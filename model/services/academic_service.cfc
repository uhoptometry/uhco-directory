component output="false" singleton {

    public any function init() {
        variables.AcademicDAO = createObject("component", "dao.academic_DAO").init();
        variables.DegreesDAO  = createObject("component", "dao.degrees_DAO").init();
        return this;
    }


    public struct function getAcademicInfo( required numeric userID ) {
        return {
            success=true,
            data=variables.AcademicDAO.getAcademicInfo( userID )
        };
    }

    /**
     * Returns a map keyed by UserID string with legacy grad year fields plus
     * EFFECTIVEGRADYEAR (derived from UserDegrees UHCO rows first, then legacy fallback).
     */
    public struct function getAllAcademicInfoMap() {
        var rows = variables.AcademicDAO.getAllAcademicInfo();

        // Build legacy map first
        var result = {};
        for ( var row in rows ) {
            result[ toString( row.USERID ) ] = {
                CURRENTGRADYEAR  = row.CURRENTGRADYEAR,
                ORIGINALGRADYEAR = row.ORIGINALGRADYEAR,
                EFFECTIVEGRADYEAR = val(row.CURRENTGRADYEAR ?: 0)
            };
        }

        // Override EFFECTIVEGRADYEAR with degree-based value where available
        var degreeRows = variables.DegreesDAO.getAllUHCODegrees();
        // Group by UserID
        var enrolledByUser  = {};  // userID -> ExpectedGradYear (enrolled)
        var graduatedByUser = {};  // userID -> max GraduationYear
        for ( var d in degreeRows ) {
            var uid = toString( d.USERID );
            if ( isBoolean(d.ISENROLLED ?: false) AND d.ISENROLLED AND val(d.EXPECTEDGRADYEAR ?: 0) GT 0 ) {
                enrolledByUser[ uid ] = val(d.EXPECTEDGRADYEAR);
            } else if ( !structKeyExists(enrolledByUser, uid) ) {
                var yr = val(d.GRADUATIONYEAR ?: 0);
                if ( yr GT val(graduatedByUser[ uid ] ?: 0) ) {
                    graduatedByUser[ uid ] = yr;
                }
            }
        }

        for ( var uid in enrolledByUser ) {
            if ( structKeyExists(result, uid) ) {
                result[ uid ].EFFECTIVEGRADYEAR = enrolledByUser[ uid ];
            } else {
                result[ uid ] = { CURRENTGRADYEAR="", ORIGINALGRADYEAR="", EFFECTIVEGRADYEAR=enrolledByUser[ uid ] };
            }
        }
        for ( var uid in graduatedByUser ) {
            if ( structKeyExists(result, uid) AND result[uid].EFFECTIVEGRADYEAR EQ val(result[uid].CURRENTGRADYEAR ?: 0) ) {
                result[ uid ].EFFECTIVEGRADYEAR = graduatedByUser[ uid ];
            }
        }

        return result;
    }

    /**
     * Returns a map keyed by UserID string for grad-year filtering/display.
     * Primary source is UHCO UserDegrees; CURRENTGRADYEAR is fallback when no usable degree years exist.
     */
    public struct function getAllGradYearMap() {
        var rows = variables.AcademicDAO.getAllAcademicInfo();
        var map = {};

        for ( var row in rows ) {
            var uid = toString( row.USERID );
            map[ uid ] = {
                YEARS = [],
                YEARLOOKUP = {},
                YEARPROGRAMMAP = {},
                LEGACYYEAR = val(row.CURRENTGRADYEAR ?: 0),
                DISPLAY = ""
            };
        }

        var degreeRows = variables.DegreesDAO.getAllUHCODegrees();
        for ( var d in degreeRows ) {
            var uid = toString( d.USERID );
            if ( !structKeyExists(map, uid) ) {
                map[ uid ] = {
                    YEARS = [],
                    YEARLOOKUP = {},
                    YEARPROGRAMMAP = {},
                    LEGACYYEAR = 0,
                    DISPLAY = ""
                };
            }

            var expectedYear = val(d.EXPECTEDGRADYEAR ?: 0);
            var graduationYear = val(d.GRADUATIONYEAR ?: 0);
            var programLabel = uCase(trim(d.PROGRAM ?: ""));

            if ( expectedYear GT 0 ) {
                if ( !structKeyExists(map[uid].YEARLOOKUP, toString(expectedYear)) ) {
                    map[uid].YEARLOOKUP[ toString(expectedYear) ] = true;
                    arrayAppend(map[uid].YEARS, expectedYear);
                }
                if ( len(programLabel) ) {
                    if ( !structKeyExists(map[uid].YEARPROGRAMMAP, toString(expectedYear)) ) {
                        map[uid].YEARPROGRAMMAP[toString(expectedYear)] = {};
                    }
                    map[uid].YEARPROGRAMMAP[toString(expectedYear)][programLabel] = true;
                }
            }

            if ( graduationYear GT 0 ) {
                if ( !structKeyExists(map[uid].YEARLOOKUP, toString(graduationYear)) ) {
                    map[uid].YEARLOOKUP[ toString(graduationYear) ] = true;
                    arrayAppend(map[uid].YEARS, graduationYear);
                }
                if ( len(programLabel) ) {
                    if ( !structKeyExists(map[uid].YEARPROGRAMMAP, toString(graduationYear)) ) {
                        map[uid].YEARPROGRAMMAP[toString(graduationYear)] = {};
                    }
                    map[uid].YEARPROGRAMMAP[toString(graduationYear)][programLabel] = true;
                }
            }
        }

        for ( var uid in map ) {
            if ( !arrayLen(map[uid].YEARS) AND val(map[uid].LEGACYYEAR) GT 0 ) {
                map[uid].YEARLOOKUP[ toString(val(map[uid].LEGACYYEAR)) ] = true;
                arrayAppend(map[uid].YEARS, val(map[uid].LEGACYYEAR));
            }

            if ( arrayLen(map[uid].YEARS) ) {
                arraySort(map[uid].YEARS, "numeric", "asc");
            }

            if ( arrayLen(map[uid].YEARS) EQ 1 ) {
                map[uid].DISPLAY = toString(map[uid].YEARS[1]);
            } else if ( arrayLen(map[uid].YEARS) GT 1 ) {
                var pairDisplay = [];
                for ( var idx = 1; idx LTE arrayLen(map[uid].YEARS); idx++ ) {
                    var pairYear = val(map[uid].YEARS[idx]);
                    var programText = "";
                    if ( structKeyExists(map[uid].YEARPROGRAMMAP, toString(pairYear)) ) {
                        var programs = [];
                        for ( var programKey in map[uid].YEARPROGRAMMAP[toString(pairYear)] ) {
                            arrayAppend(programs, programKey);
                        }
                        arraySort(programs, "textnocase", "asc");
                        programText = arrayToList(programs, "/");
                    }

                    if ( len(programText) ) {
                        arrayAppend(pairDisplay, toString(pairYear) & " : " & programText);
                    } else {
                        arrayAppend(pairDisplay, toString(pairYear));
                    }
                }

                map[uid].DISPLAY = "(" & arrayToList(pairDisplay, " | ") & ")";
            } else {
                map[uid].DISPLAY = "";
            }
        }

        return map;
    }

    public struct function updateAcademicInfo( required numeric userID, required struct data ) {

        // Validation: grad year must be realistic
        if ( data.OriginalGradYear lt 1900 OR data.OriginalGradYear gt year( now() ) + 1 ) {
            return { success=false, message="Invalid OriginalGradYear" };
        }

        variables.AcademicDAO.updateAcademicInfo( userID, data );

        return { success=true, message="Academic info updated." };
    }

    public struct function saveAcademicInfo(
        required numeric userID,
        required string  currentGradYear,
        required string  originalGradYear
    ) {
        var currYear = val( trim( arguments.currentGradYear  ) );
        var origYear = val( trim( arguments.originalGradYear ) );

        // Server-side guard: origYear requires currYear
        if ( origYear GT 0 AND currYear EQ 0 ) {
            return { success=false, message="Original Grad Year requires a Current Grad Year." };
        }

        var existing = variables.AcademicDAO.getAcademicInfo( arguments.userID );

        var dataParams = {
            CurrentGradYear  = { value=currYear, cfsqltype="cf_sql_integer", null=(currYear  EQ 0) },
            OriginalGradYear = { value=origYear, cfsqltype="cf_sql_integer", null=(origYear EQ 0) }
        };

        if ( structIsEmpty( existing ) ) {
            if ( currYear EQ 0 AND origYear EQ 0 ) {
                return { success=true };
            }
            dataParams.UserID = { value=arguments.userID, cfsqltype="cf_sql_integer" };
            variables.AcademicDAO.createAcademicInfo( dataParams );
        } else {
            variables.AcademicDAO.updateAcademicInfo( arguments.userID, dataParams );
        }

        return { success=true, message="Academic info saved." };
    }

}