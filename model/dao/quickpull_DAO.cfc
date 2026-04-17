component extends="dao.BaseDAO" output="false" singleton {

    public any function init() {
        super.init();        return this;
    }

    /**
     * Users with the Clinical-Attending flag.
     * Returns: UserID, FirstName, MiddleName, LastName, Degrees (display string from Users table)
     */
    public array function getAttendingUsers() {
        var qry = executeQueryWithRetry(
            "SELECT u.UserID, u.FirstName, u.MiddleName, u.LastName, u.Degrees
             FROM   Users u
             WHERE  u.Active = 1
               AND  EXISTS (
                        SELECT 1
                        FROM   UserFlagAssignments ufa
                               INNER JOIN UserFlags uf ON ufa.FlagID = uf.FlagID
                        WHERE  ufa.UserID = u.UserID
                          AND  uf.FlagName = 'Clinical-Attending'
                    )
             ORDER BY u.LastName, u.FirstName",
            {},
            { datasource=variables.datasource, timeout=30, fetchSize=500 }
        );
        return queryToArray(qry);
    }

    /**
     * Alumni filtered to a specific graduation year.
     * Returns: UserID, FirstName, MiddleName, LastName, CurrentGradYear
     */
    public array function getGradClassUsers( required numeric gradYear ) {
        var qry = executeQueryWithRetry(
            "SELECT u.UserID, u.FirstName, u.MiddleName, u.LastName,
                    uai.CurrentGradYear
             FROM   Users u
                    INNER JOIN UserAcademicInfo uai ON u.UserID = uai.UserID
             WHERE  u.Active = 1
               AND  uai.CurrentGradYear = :gradYear
               AND  EXISTS (
                        SELECT 1
                        FROM   UserFlagAssignments ufa
                               INNER JOIN UserFlags uf ON ufa.FlagID = uf.FlagID
                        WHERE  ufa.UserID = u.UserID
                          AND  uf.FlagName = 'Alumni'
                    )
             ORDER BY u.LastName, u.FirstName",
            { gradYear = { value=arguments.gradYear, cfsqltype="cf_sql_integer" } },
            { datasource=variables.datasource, timeout=30, fetchSize=500 }
        );
        return queryToArray(qry);
    }

    /**
     * Single Alumni user with student profile and academic data.
     * Returns base fields; degrees, awards, and images are fetched separately.
     */
    public array function getGraduateUser( required numeric userID ) {
        var qry = executeQueryWithRetry(
            "SELECT u.UserID, u.FirstName, u.MiddleName, u.LastName,
                    uai.CurrentGradYear,
                    usp.FirstExternship, usp.SecondExternship,
                    usp.HometownCity, usp.HometownState
             FROM   Users u
                    LEFT JOIN UserAcademicInfo    uai ON u.UserID = uai.UserID
                    LEFT JOIN UserStudentProfile  usp ON u.UserID = usp.UserID
             WHERE  u.Active = 1
               AND  u.UserID = :userID
               AND  EXISTS (
                        SELECT 1
                        FROM   UserFlagAssignments ufa
                               INNER JOIN UserFlags uf ON ufa.FlagID = uf.FlagID
                        WHERE  ufa.UserID = u.UserID
                          AND  uf.FlagName = 'Alumni'
                    )",
            { userID = { value=arguments.userID, cfsqltype="cf_sql_integer" } },
            { datasource=variables.datasource, timeout=30, fetchSize=10 }
        );
        return queryToArray(qry);
    }

    /**
     * Users with the Deans flag.
     * Returns: UserID, FirstName, MiddleName, LastName
     */
    public array function getDeansUsers() {
        var qry = executeQueryWithRetry(
            "SELECT u.UserID, u.FirstName, u.MiddleName, u.LastName
             FROM   Users u
             WHERE  u.Active = 1
               AND  EXISTS (
                        SELECT 1
                        FROM   UserFlagAssignments ufa
                               INNER JOIN UserFlags uf ON ufa.FlagID = uf.FlagID
                        WHERE  ufa.UserID = u.UserID
                          AND  uf.FlagName = 'Deans'
                    )
             ORDER BY u.LastName, u.FirstName",
            {},
            { datasource=variables.datasource, timeout=30, fetchSize=500 }
        );
        return queryToArray(qry);
    }

    /**
     * Bulk-fetch degrees for a set of UserIDs.
     * Returns: array of { USERID, DEGREENAME, UNIVERSITY, DEGREEYEAR }
     */
    public array function getDegreesForUsers( required array userIDs ) {
        if ( arrayLen(arguments.userIDs) == 0 ) return [];

        var inClause = "";
        var params   = {};
        for ( var i = 1; i <= arrayLen(arguments.userIDs); i++ ) {
            if ( i > 1 ) inClause &= ",";
            inClause &= ":uid#i#";
            params["uid#i#"] = { value=arguments.userIDs[i], cfsqltype="cf_sql_integer" };
        }

        var qry = executeQueryWithRetry(
            "SELECT UserID, DegreeName, University, DegreeYear
             FROM   UserDegrees
             WHERE  UserID IN (#inClause#)
             ORDER BY UserID, DegreeID",
            params,
            { datasource=variables.datasource, timeout=30, fetchSize=1000 }
        );
        return queryToArray(qry);
    }

    /**
     * Bulk-fetch awards for a set of UserIDs.
     * Returns: array of { USERID, AWARDNAME, AWARDTYPE }
     */
    public array function getAwardsForUsers( required array userIDs ) {
        if ( arrayLen(arguments.userIDs) == 0 ) return [];

        var inClause = "";
        var params   = {};
        for ( var i = 1; i <= arrayLen(arguments.userIDs); i++ ) {
            if ( i > 1 ) inClause &= ",";
            inClause &= ":uid#i#";
            params["uid#i#"] = { value=arguments.userIDs[i], cfsqltype="cf_sql_integer" };
        }

        var qry = executeQueryWithRetry(
            "SELECT UserID, AwardName, AwardType
             FROM   UserAwards
             WHERE  UserID IN (#inClause#)
             ORDER BY UserID, AwardID",
            params,
            { datasource=variables.datasource, timeout=30, fetchSize=1000 }
        );
        return queryToArray(qry);
    }

    /**
     * Bulk-fetch the primary image URL for a given variant code across a set of UserIDs.
     * Returns a struct keyed by UserID → ImageURL (first image per user by SortOrder).
     */
    public struct function getImageMapByVariant( required string variantCode, required array userIDs ) {
        if ( arrayLen(arguments.userIDs) == 0 ) return {};

        var inClause = "";
        var params   = { code = { value=arguments.variantCode, cfsqltype="cf_sql_varchar" } };
        for ( var i = 1; i <= arrayLen(arguments.userIDs); i++ ) {
            if ( i > 1 ) inClause &= ",";
            inClause &= ":uid#i#";
            params["uid#i#"] = { value=arguments.userIDs[i], cfsqltype="cf_sql_integer" };
        }

        var qry = executeQueryWithRetry(
            "SELECT UserID, ImageURL
             FROM (
                 SELECT UserID, ImageURL,
                        ROW_NUMBER() OVER (PARTITION BY UserID ORDER BY SortOrder) AS rn
                 FROM   UserImages
                 WHERE  ImageVariant = :code
                   AND  UserID IN (#inClause#)
             ) t
             WHERE t.rn = 1",
            params,
            { datasource=variables.datasource, timeout=30, fetchSize=500 }
        );

        var result = {};
        for ( var row in qry ) {
            result[ toString(row.USERID) ] = row.IMAGEURL;
        }
        return result;
    }

}
