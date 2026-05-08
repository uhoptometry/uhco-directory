component output="false" singleton {

    public any function init() {
        variables.DegreesDAO  = createObject("component", "dao.degrees_DAO").init();
        variables.AcademicDAO = createObject("component", "dao.academic_DAO").init();
        return this;
    }

    public struct function getDegrees( required numeric userID ) {
        return { success=true, data=variables.DegreesDAO.getDegrees( userID ) };
    }

    public void function replaceDegrees( required numeric userID, required array degrees ) {
        variables.DegreesDAO.replaceDegrees( userID, degrees );
        // Auto-update the composite Degrees field on the Users table
        var compositeStr = buildDegreesString( userID );
        var usersDAO = createObject("component", "dao.users_DAO").init();
        usersDAO.updateDegreesField( userID, compositeStr );
    }

    /**
     * Build the comma-separated Degrees string from the UserDegrees table.
     * Enrolled UHCO degrees render as "{DegreeName} Candidate ({ExpectedGradYear})"
     * e.g. "O.D., Ph.D. Candidate (2026), FAAO"
     */
    public string function buildDegreesString( required numeric userID ) {
        var rows  = variables.DegreesDAO.getDegrees( userID );
        var names = [];
        for ( var r in rows ) {
            if ( !len(trim(r.DEGREENAME ?: "")) ) continue;
            var label = trim(r.DEGREENAME);
            if ( isBoolean(r.ISUHCO ?: false) AND r.ISUHCO
              && isBoolean(r.ISENROLLED ?: false) AND r.ISENROLLED
              && val(r.EXPECTEDGRADYEAR ?: 0) GT 0 ) {
                label = label & " Candidate (" & val(r.EXPECTEDGRADYEAR) & ")";
            }
            arrayAppend( names, label );
        }
        return arrayToList( names, ", " );
    }

    /**
     * Return the active enrolled UHCO degree row for a user, or an empty struct if none.
     * "Active" means IsUHCO=1 AND IsEnrolled=1. Excludes Residency rows.
     */
    public struct function getActiveUHCODegree( required numeric userID ) {
        var rows = variables.DegreesDAO.getDegrees( userID );
        for ( var r in rows ) {
            if ( isBoolean(r.ISUHCO ?: false)    AND r.ISUHCO
              && isBoolean(r.ISENROLLED ?: false) AND r.ISENROLLED
              && uCase(trim(r.PROGRAM ?: "")) NEQ "RESIDENCY" ) {
                return r;
            }
        }
        return {};
    }

    /**
     * Return the effective graduation year for a user.
     * Priority:
     *   1. ExpectedGradYear of the active enrolled UHCO degree
     *   2. GraduationYear of the most recent (highest) UHCO degree
     *   3. UserAcademicInfo.CurrentGradYear (legacy fallback)
     *   Returns 0 if none found.
     */
    public numeric function getEffectiveGradYear( required numeric userID ) {
        var rows = variables.DegreesDAO.getDegrees( userID );

        // Priority 1: active enrolled UHCO degree expected year
        for ( var r in rows ) {
            if ( isBoolean(r.ISUHCO ?: false)    AND r.ISUHCO
              && isBoolean(r.ISENROLLED ?: false) AND r.ISENROLLED
              && val(r.EXPECTEDGRADYEAR ?: 0) GT 0 ) {
                return val(r.EXPECTEDGRADYEAR);
            }
        }

        // Priority 2: most recent UHCO graduation year
        var bestYear = 0;
        for ( var r in rows ) {
            if ( isBoolean(r.ISUHCO ?: false) AND r.ISUHCO ) {
                var yr = val(r.GRADUATIONYEAR ?: 0);
                if ( yr GT bestYear ) bestYear = yr;
            }
        }
        if ( bestYear GT 0 ) return bestYear;

        // Priority 3: legacy UserAcademicInfo fallback
        var academic = variables.AcademicDAO.getAcademicInfo( arguments.userID );
        return val( academic.CURRENTGRADYEAR ?: 0 );
    }
}
