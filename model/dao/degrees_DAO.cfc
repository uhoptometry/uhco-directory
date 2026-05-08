component extends="dao.BaseDAO" output="false" singleton {

    public any function init() {
        super.init();        return this;
    }

    public array function getDegrees( required numeric userID ) {
        var qry = executeQueryWithRetry(
            "SELECT DegreeID, UserID, DegreeName, University, GraduationYear,
                    IsUHCO, IsEnrolled, HasYearChange, OriginalExpectedGradYear,
                    ExpectedGradYear, Program
             FROM   UserDegrees
             WHERE  UserID = :id
             ORDER BY DegreeID",
            { id={ value=userID, cfsqltype="cf_sql_integer" } },
            { datasource=variables.datasource, timeout=30, fetchSize=100 }
        );
        return queryToArray(qry);
    }

    public void function replaceDegrees( required numeric userID, required array degrees ) {
        var idParam = { id={ value=userID, cfsqltype="cf_sql_integer" } };
        executeQueryWithRetry(
            "DELETE FROM UserDegrees WHERE UserID = :id",
            idParam, { datasource=variables.datasource, timeout=30 }
        );
        for ( var deg in arguments.degrees ) {
            var isUHCO      = _toBitBoolean(deg.isUHCO ?: 0);
            var isEnrolled  = _toBitBoolean(deg.isEnrolled ?: 0);
            var hasChange   = _toBitBoolean(deg.hasYearChange ?: 0);
            var origExp     = isNumeric(deg.originalExpectedGradYear ?: "") ? val(deg.originalExpectedGradYear) : 0;
            var expGrad     = isNumeric(deg.expectedGradYear ?: "")         ? val(deg.expectedGradYear)         : 0;
            var program     = trim(deg.program ?: "");
            executeQueryWithRetry(
                "INSERT INTO UserDegrees
                     (UserID, DegreeName, University, GraduationYear,
                      IsUHCO, IsEnrolled, HasYearChange,
                      OriginalExpectedGradYear, ExpectedGradYear, Program)
                 VALUES
                     (:id, :DegreeName, :University, :GraduationYear,
                      :IsUHCO, :IsEnrolled, :HasYearChange,
                      :OriginalExpectedGradYear, :ExpectedGradYear, :Program)",
                {
                    id                       = { value=userID,                      cfsqltype="cf_sql_integer"  },
                    DegreeName               = { value=deg.name,                    cfsqltype="cf_sql_nvarchar" },
                    University               = { value=deg.university,              cfsqltype="cf_sql_nvarchar" },
                    GraduationYear           = { value=trim(deg.year ?: ""),        cfsqltype="cf_sql_nvarchar" },
                    IsUHCO                   = { value=(isUHCO ? 1 : 0),            cfsqltype="cf_sql_bit"      },
                    IsEnrolled               = { value=(isUHCO ? (isEnrolled ? 1 : 0) : javaCast("null","")), cfsqltype="cf_sql_bit",     null=!isUHCO },
                    HasYearChange            = { value=(isEnrolled ? (hasChange ? 1 : 0) : javaCast("null","")), cfsqltype="cf_sql_bit", null=(!isUHCO OR !isEnrolled) },
                    OriginalExpectedGradYear = { value=origExp,                     cfsqltype="cf_sql_integer", null=(origExp EQ 0) },
                    ExpectedGradYear         = { value=expGrad,                     cfsqltype="cf_sql_integer", null=(expGrad EQ 0) },
                    Program                  = { value=program,                     cfsqltype="cf_sql_nvarchar",null=!len(program) }
                },
                { datasource=variables.datasource, timeout=30 }
            );
        }
    }

    /**
     * Mark an active UHCO degree as graduated: clears IsEnrolled and sets GraduationYear.
     * Called by gradMigration_service after promoting a student to alumni.
     * Only updates rows where IsUHCO=1, IsEnrolled=1, and Program != 'Residency'.
     */
    public void function graduateUHCODegree( required numeric userID, required numeric gradYear ) {
        executeQueryWithRetry(
            "UPDATE UserDegrees
             SET    IsEnrolled   = 0,
                    GraduationYear = :yr
             WHERE  UserID    = :id
               AND  IsUHCO    = 1
               AND  IsEnrolled = 1
               AND  (Program IS NULL OR Program <> 'Residency')",
            {
                id = { value=arguments.userID,   cfsqltype="cf_sql_integer"  },
                yr = { value=toString(arguments.gradYear), cfsqltype="cf_sql_nvarchar" }
            },
            { datasource=variables.datasource, timeout=30 }
        );
    }

    /**
     * Reverse graduateUHCODegree: re-mark degree as enrolled and clear GraduationYear
     * (sets it back to empty string so it was not set before graduation).
     * Called by gradMigration_service.rollback().
     */
    public void function rollbackGraduateUHCODegree( required numeric userID, required numeric gradYear ) {
        executeQueryWithRetry(
            "UPDATE UserDegrees
             SET    IsEnrolled   = 1,
                    GraduationYear = ''
             WHERE  UserID    = :id
               AND  IsUHCO    = 1
               AND  IsEnrolled = 0
               AND  GraduationYear = :yr
               AND  (Program IS NULL OR Program <> 'Residency')",
            {
                id = { value=arguments.userID,   cfsqltype="cf_sql_integer"  },
                yr = { value=toString(arguments.gradYear), cfsqltype="cf_sql_nvarchar" }
            },
            { datasource=variables.datasource, timeout=30 }
        );
    }

    public void function deleteAllForUser( required numeric userID ) {
        var idParam = { id={ value=userID, cfsqltype="cf_sql_integer" } };
        executeQueryWithRetry( "DELETE FROM UserDegrees WHERE UserID = :id", idParam, { datasource=variables.datasource, timeout=30 } );
    }

    private boolean function _toBitBoolean( any rawValue ) {
        if ( isBoolean(arguments.rawValue) ) {
            return arguments.rawValue;
        }

        if ( isNumeric(arguments.rawValue ?: "") ) {
            return val(arguments.rawValue) EQ 1;
        }

        return listFindNoCase("1,true,yes,on", trim(arguments.rawValue ?: "")) GT 0;
    }

    /**
     * Return all UHCO degree rows across all users for bulk map building.
     * Used by academic_service.getAllAcademicInfoMap().
     */
    public array function getAllUHCODegrees() {
        var qry = executeQueryWithRetry(
            "SELECT UserID, IsEnrolled, ExpectedGradYear, GraduationYear, Program
             FROM   UserDegrees
             WHERE  IsUHCO = 1
                OR  Program IN ('OD', 'MS', 'PhD')
             ORDER BY UserID, DegreeID",
            {},
            { datasource=variables.datasource, timeout=60, fetchSize=2000 }
        );
        return queryToArray(qry);
    }

    /**
     * Bridge: when a legacy CurrentGradYear is imported, sync the value into the
     * active enrolled UHCO degree row's ExpectedGradYear (if one exists).
     * Used by bulkImport_service as a compat shim.
     */
    public void function syncExpectedGradYearFromLegacy( required numeric userID, required numeric gradYear ) {
        executeQueryWithRetry(
            "UPDATE UserDegrees
             SET    ExpectedGradYear = :yr
             WHERE  UserID    = :uid
               AND  IsUHCO    = 1
               AND  IsEnrolled = 1
               AND  (Program IS NULL OR Program <> 'Residency')
               AND  (ExpectedGradYear IS NULL OR ExpectedGradYear <> :yr)",
            {
                uid = { value=arguments.userID,  cfsqltype="cf_sql_integer" },
                yr  = { value=arguments.gradYear, cfsqltype="cf_sql_integer" }
            },
            { datasource=variables.datasource, timeout=30 }
        );
    }
}
