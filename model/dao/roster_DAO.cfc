component extends="dao.BaseDAO" output="false" singleton {

    public any function init() {
        super.init();
        return this;
    }

    public array function getAvailableGradYears() {
        var qry = executeQueryWithRetry(
            "-- Degree-based: enrolled students with ExpectedGradYear
             SELECT DISTINCT ud.ExpectedGradYear AS CurrentGradYear
             FROM   Users u
                    INNER JOIN UserDegrees ud ON ud.UserID = u.UserID
                                             AND ud.IsUHCO = 1
                                             AND ud.IsEnrolled = 1
                                             AND (ud.Program IS NULL OR ud.Program <> 'Residency')
                                             AND ud.ExpectedGradYear IS NOT NULL
                                             AND ud.ExpectedGradYear > 0
             WHERE  u.Active = 1
               AND  EXISTS (
                        SELECT 1 FROM UserFlagAssignments ufa
                        INNER JOIN UserFlags uf ON ufa.FlagID = uf.FlagID
                        WHERE ufa.UserID = u.UserID AND uf.FlagName = 'Current-Student'
                    )
               AND  NOT EXISTS (
                        SELECT 1 FROM UserFlagAssignments ufaTest
                        INNER JOIN UserFlags ufTest ON ufaTest.FlagID = ufTest.FlagID
                        WHERE ufaTest.UserID = u.UserID AND ufTest.FlagName = 'TEST_USER'
                    )
             UNION
             -- Legacy fallback: current students with UserAcademicInfo but no UHCO degree row
             SELECT DISTINCT uai.CurrentGradYear
             FROM   Users u
                    INNER JOIN UserAcademicInfo uai ON u.UserID = uai.UserID
                    INNER JOIN UserOrganizations uo ON u.UserID = uo.UserID
                    INNER JOIN Organizations o ON uo.OrgID = o.OrgID
             WHERE  u.Active = 1
               AND  uai.CurrentGradYear IS NOT NULL
               AND  uai.CurrentGradYear > 0
               AND  o.OrgName IN ('OD Program', 'MS Program', 'PhD Program')
               AND  NOT EXISTS (
                        SELECT 1 FROM UserDegrees ud2
                        WHERE ud2.UserID = u.UserID AND ud2.IsUHCO = 1 AND ud2.IsEnrolled = 1
                          AND (ud2.Program IS NULL OR ud2.Program <> 'Residency')
                    )
               AND  EXISTS (
                        SELECT 1 FROM UserFlagAssignments ufa
                        INNER JOIN UserFlags uf ON ufa.FlagID = uf.FlagID
                        WHERE ufa.UserID = u.UserID AND uf.FlagName = 'Current-Student'
                    )
               AND  NOT EXISTS (
                        SELECT 1 FROM UserFlagAssignments ufaTest
                        INNER JOIN UserFlags ufTest ON ufaTest.FlagID = ufTest.FlagID
                        WHERE ufaTest.UserID = u.UserID AND ufTest.FlagName = 'TEST_USER'
                    )
             ORDER BY CurrentGradYear DESC",
            {},
            { datasource = variables.datasource, timeout = 20, fetchSize = 200 }
        );

        return queryToArray(qry);
    }

    public array function getRosterUsers( required numeric gradYear, required string programName ) {
        var qry = executeQueryWithRetry(
            "SELECT DISTINCT
                    u.UserID,
                    COALESCE(pa.FirstName, u.FirstName) AS FirstName,
                    COALESCE(pa.MiddleName, u.MiddleName) AS MiddleName,
                    COALESCE(pa.LastName, u.LastName) AS LastName,
                    COALESCE(deg.ExpectedGradYear, uai.CurrentGradYear) AS CurrentGradYear,
                    o.OrgName AS Program,
                    thumb.ImageURL AS WebThumbImage,
                    profile.ImageURL AS WebProfileImage
             FROM   Users u
                    INNER JOIN UserOrganizations uo ON u.UserID = uo.UserID
                    INNER JOIN Organizations o ON uo.OrgID = o.OrgID
                    LEFT JOIN UserAcademicInfo uai ON u.UserID = uai.UserID
                    OUTER APPLY (
                        SELECT TOP 1 ud.ExpectedGradYear
                        FROM UserDegrees ud
                        WHERE ud.UserID = u.UserID AND ud.IsUHCO = 1 AND ud.IsEnrolled = 1
                          AND (ud.Program IS NULL OR ud.Program <> 'Residency')
                    ) deg
                    OUTER APPLY (
                        SELECT TOP 1 ua.FirstName, ua.MiddleName, ua.LastName
                        FROM UserAliases ua
                        WHERE ua.UserID = u.UserID
                          AND ISNULL(ua.IsActive, 1) = 1
                        ORDER BY
                            CASE WHEN ISNULL(ua.IsPrimary, 0) = 1 THEN 0 ELSE 1 END,
                            ISNULL(ua.SortOrder, 2147483647),
                            ua.AliasID
                    ) pa
                    OUTER APPLY (
                        SELECT TOP 1 img.ImageURL
                        FROM UserImages img
                        WHERE img.UserID = u.UserID
                          AND img.ImageVariant = 'WEB_THUMB'
                        ORDER BY img.SortOrder
                    ) thumb
                    OUTER APPLY (
                        SELECT TOP 1 img.ImageURL
                        FROM UserImages img
                        WHERE img.UserID = u.UserID
                          AND img.ImageVariant = 'WEB_PROFILE'
                        ORDER BY img.SortOrder
                    ) profile
             WHERE  u.Active = 1
               AND  o.OrgName = :programName
               AND  o.OrgName IN ('OD Program', 'MS Program', 'PhD Program')
               -- Match via UHCO enrolled degree or legacy UserAcademicInfo
               AND  (
                       EXISTS (
                           SELECT 1 FROM UserDegrees ud
                           WHERE ud.UserID = u.UserID AND ud.IsUHCO = 1 AND ud.IsEnrolled = 1
                             AND (ud.Program IS NULL OR ud.Program <> 'Residency')
                             AND ud.ExpectedGradYear = :gradYear
                       )
                    OR (
                           NOT EXISTS (
                               SELECT 1 FROM UserDegrees ud2
                               WHERE ud2.UserID = u.UserID AND ud2.IsUHCO = 1 AND ud2.IsEnrolled = 1
                                 AND (ud2.Program IS NULL OR ud2.Program <> 'Residency')
                           )
                       AND EXISTS (
                               SELECT 1 FROM UserAcademicInfo uai
                               WHERE uai.UserID = u.UserID AND uai.CurrentGradYear = :gradYear
                           )
                       )
                   )
               AND  EXISTS (
                        SELECT 1
                        FROM   UserFlagAssignments ufa
                               INNER JOIN UserFlags uf ON ufa.FlagID = uf.FlagID
                        WHERE  ufa.UserID = u.UserID
                          AND  uf.FlagName = 'Current-Student'
                    )
               AND  NOT EXISTS (
                        SELECT 1
                        FROM   UserFlagAssignments ufaTest
                               INNER JOIN UserFlags ufTest ON ufaTest.FlagID = ufTest.FlagID
                        WHERE  ufaTest.UserID = u.UserID
                          AND  ufTest.FlagName = 'TEST_USER'
                    )
             ORDER BY COALESCE(pa.LastName, u.LastName), COALESCE(pa.FirstName, u.FirstName), u.UserID",
            {
                gradYear = { value = arguments.gradYear, cfsqltype = "cf_sql_integer" },
                programName = { value = arguments.programName, cfsqltype = "cf_sql_varchar" }
            },
            { datasource = variables.datasource, timeout = 30, fetchSize = 600 }
        );

        return queryToArray(qry);
    }

}