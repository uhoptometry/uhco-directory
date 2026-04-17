component extends="dao.BaseDAO" output="false" {

    /**
     * bulkExclusions_DAO — Runs bulk DataQualityExclusion inserts
     * for each user-type and logs results to BulkExclusionRuns.
     */

    public any function init() {
        super.init();        return this;
    }

    /* ─────────────────── Audit ─────────────────── */

    public numeric function createRun(
        required string exclusionType,
        required string triggeredBy
    ) {
        var qry = executeQueryWithRetry(
            sql = "
                INSERT INTO BulkExclusionRuns (ExclusionType, TriggeredBy)
                OUTPUT INSERTED.RunID
                VALUES (:exType, :trig)
            ",
            params = {
                exType = { value = arguments.exclusionType, cfsqltype = "cf_sql_varchar" },
                trig   = { value = arguments.triggeredBy,   cfsqltype = "cf_sql_varchar" }
            },
            options = { datasource = variables.dsn }
        );
        return qry.RunID;
    }

    public void function updateRun(
        required numeric runID,
        required numeric rowsAffected,
        string errorMessage = ""
    ) {
        executeQueryWithRetry(
            sql = "
                UPDATE BulkExclusionRuns
                SET RowsAffected = :rows,
                    ErrorMessage = :err
                WHERE RunID = :runID
            ",
            params = {
                runID = { value = arguments.runID,         cfsqltype = "cf_sql_integer" },
                rows  = { value = arguments.rowsAffected,  cfsqltype = "cf_sql_integer" },
                err   = { value = arguments.errorMessage,  cfsqltype = "cf_sql_varchar", null = !len(arguments.errorMessage) }
            },
            options = { datasource = variables.dsn }
        );
    }

    public array function getRecentRuns(numeric maxRuns = 20) {
        var qry = executeQueryWithRetry(
            sql = "
                SELECT TOP (:n) RunID, ExclusionType, RowsAffected, TriggeredBy, RunAt, ErrorMessage
                FROM BulkExclusionRuns
                ORDER BY RunAt DESC
            ",
            params = { n = { value = arguments.maxRuns, cfsqltype = "cf_sql_integer" } },
            options = { datasource = variables.dsn }
        );
        return queryToArray(qry);
    }

    public struct function getLatestRunByType(required string exclusionType) {
        var qry = executeQueryWithRetry(
            sql = "
                SELECT TOP 1 RunID, ExclusionType, RowsAffected, TriggeredBy, RunAt, ErrorMessage
                FROM BulkExclusionRuns
                WHERE ExclusionType = :exType
                ORDER BY RunAt DESC
            ",
            params = { exType = { value = arguments.exclusionType, cfsqltype = "cf_sql_varchar" } },
            options = { datasource = variables.dsn }
        );
        var arr = queryToArray(qry);
        return arrayLen(arr) ? arr[1] : {};
    }

    /* ─────────────────── Type Config (DB-driven) ─────────────────── */

    public array function getAllTypes() {
        var qry = executeQueryWithRetry(
            sql = "SELECT type_key, label, icon, flags, codes, flag_join_type, extra_filter, sort_order, is_active, updated_at, updated_by
                   FROM BulkExclusionTypes
                   WHERE is_active = 1
                   ORDER BY sort_order, label",
            params  = {},
            options = { datasource = variables.dsn }
        );
        return queryToArray(qry);
    }

    public struct function getType(required string typeKey) {
        var qry = executeQueryWithRetry(
            sql = "SELECT type_key, label, icon, flags, codes, flag_join_type, extra_filter, sort_order, is_active, updated_at, updated_by
                   FROM BulkExclusionTypes
                   WHERE type_key = :tk",
            params  = { tk = { value = arguments.typeKey, cfsqltype = "cf_sql_nvarchar" } },
            options = { datasource = variables.dsn }
        );
        var arr = queryToArray(qry);
        return arrayLen(arr) ? arr[1] : {};
    }

    public void function updateType(
        required string typeKey,
        required string flags,
        required string codes,
        required string label,
        required string icon,
        string extraFilter = "",
        string updatedBy = ""
    ) {
        executeQueryWithRetry(
            sql = "UPDATE BulkExclusionTypes
                   SET flags = :flags, codes = :codes, label = :lbl, icon = :ico,
                       extra_filter = :ef, updated_at = GETDATE(), updated_by = :ub
                   WHERE type_key = :tk",
            params = {
                tk    = { value = arguments.typeKey,     cfsqltype = "cf_sql_nvarchar" },
                flags = { value = arguments.flags,       cfsqltype = "cf_sql_nvarchar" },
                codes = { value = arguments.codes,       cfsqltype = "cf_sql_nvarchar" },
                lbl   = { value = arguments.label,       cfsqltype = "cf_sql_nvarchar" },
                ico   = { value = arguments.icon,        cfsqltype = "cf_sql_nvarchar" },
                ef    = { value = arguments.extraFilter, cfsqltype = "cf_sql_nvarchar", null = !len(trim(arguments.extraFilter)) },
                ub    = { value = arguments.updatedBy,   cfsqltype = "cf_sql_nvarchar", null = !len(trim(arguments.updatedBy)) }
            },
            options = { datasource = variables.dsn }
        );
    }

    /**
     * Dynamic exclusion runner — builds SQL from the type config in BulkExclusionTypes.
     * Flags match via LOWER(TRIM(uf.FlagName)) IN (...).
     * Codes are CROSS JOINed as VALUES.
     * Alumni extra_filter (join to UserAcademicInfo, WHERE clause) is handled via extra_filter column.
     */
    public numeric function runDynamic(required string typeKey) {
        var typeConfig = getType(arguments.typeKey);
        if (structIsEmpty(typeConfig)) throw(type="BulkExclusions.UnknownType", message="Unknown exclusion type: #arguments.typeKey#");

        // Build flag IN list
        var flagList = listToArray(typeConfig.FLAGS, ",");
        var flagSql = "";
        for (var i = 1; i <= arrayLen(flagList); i++) {
            if (i > 1) flagSql &= ",";
            flagSql &= "'" & replace(lCase(trim(flagList[i])), "'", "''", "all") & "'";
        }

        // Build codes VALUES list
        var codeList = listToArray(typeConfig.CODES, ",");
        var codesSql = "";
        for (var i = 1; i <= arrayLen(codeList); i++) {
            if (i > 1) codesSql &= ",";
            codesSql &= "('" & replace(trim(codeList[i]), "'", "''", "all") & "')";
        }

        // Extra joins/filters for special types (e.g. alumni needs UserAcademicInfo)
        var extraJoin   = "";
        var extraWhere  = "";
        if (len(trim(typeConfig.EXTRA_FILTER ?: ""))) {
            // Alumni-style filter references uai => join UserAcademicInfo
            if (findNoCase("uai.", typeConfig.EXTRA_FILTER)) {
                extraJoin = "INNER JOIN UserAcademicInfo uai ON uai.UserID = u.UserID";
            }
            extraWhere = "AND " & typeConfig.EXTRA_FILTER;
        }

        var sql = "
            INSERT INTO DataQualityExclusions (UserID, IssueCode, CreatedAt)
            SELECT q.UserID, codes.IssueCode, GETDATE()
            FROM (
                SELECT DISTINCT u.UserID
                FROM Users u
                INNER JOIN UserFlagAssignments ufa ON ufa.UserID = u.UserID
                INNER JOIN UserFlags uf ON uf.FlagID = ufa.FlagID
                    AND LOWER(TRIM(uf.FlagName)) IN (#flagSql#)
                #extraJoin#
                WHERE 1=1 #extraWhere#
            ) q
            CROSS JOIN (VALUES #codesSql#) AS codes(IssueCode)
            WHERE NOT EXISTS (
                SELECT 1 FROM DataQualityExclusions x
                WHERE x.UserID = q.UserID AND x.IssueCode = codes.IssueCode
            );
            SELECT @@ROWCOUNT AS RowsInserted;
        ";

        var qry = executeQueryWithRetry(
            sql     = sql,
            params  = {},
            options = { datasource = variables.dsn }
        );
        return qry.RowsInserted;
    }

    /* ─────────────────── Exclusion Runners (legacy — kept for reference) ─────────────────── */

    public numeric function runAdjunctFaculty() {
        var qry = executeQueryWithRetry(
            sql = "
                INSERT INTO DataQualityExclusions (UserID, IssueCode, CreatedAt)
                SELECT q.UserID, codes.IssueCode, GETDATE()
                FROM (
                    SELECT DISTINCT u.UserID
                    FROM Users u
                    INNER JOIN UserFlagAssignments ufa ON ufa.UserID = u.UserID
                    INNER JOIN UserFlags uf ON uf.FlagID = ufa.FlagID
                        AND LOWER(TRIM(uf.FlagName)) = 'faculty-adjunct'
                ) q
                CROSS JOIN (VALUES
                    ('missing_legacy_id'),('missing_room'),('missing_building'),
                    ('missing_phone'),('missing_peoplesoft')
                ) AS codes(IssueCode)
                WHERE NOT EXISTS (
                    SELECT 1 FROM DataQualityExclusions x
                    WHERE x.UserID = q.UserID AND x.IssueCode = codes.IssueCode
                );
                SELECT @@ROWCOUNT AS RowsInserted;
            ",
            params  = {},
            options = { datasource = variables.dsn }
        );
        return qry.RowsInserted;
    }

    public numeric function runAlumni() {
        var qry = executeQueryWithRetry(
            sql = "
                INSERT INTO DataQualityExclusions (UserID, IssueCode, CreatedAt)
                SELECT q.UserID, codes.IssueCode, GETDATE()
                FROM (
                    SELECT DISTINCT u.UserID
                    FROM Users u
                    INNER JOIN UserFlagAssignments ufa ON ufa.UserID = u.UserID
                    INNER JOIN UserFlags uf ON uf.FlagID = ufa.FlagID
                        AND LOWER(TRIM(uf.FlagName)) = 'alumni'
                    INNER JOIN UserAcademicInfo uai ON uai.UserID = u.UserID
                    WHERE LOWER(TRIM(u.Title1)) = 'alumni'
                      AND uai.CurrentGradYear BETWEEN 1955 AND 2025
                ) q
                CROSS JOIN (VALUES
                    ('missing_uh_api_id'),('missing_email_primary'),('missing_room'),
                    ('missing_building'),('missing_phone'),('missing_degrees'),
                    ('missing_cougarnet'),('missing_peoplesoft'),('missing_legacy_id')
                ) AS codes(IssueCode)
                WHERE NOT EXISTS (
                    SELECT 1 FROM DataQualityExclusions x
                    WHERE x.UserID = q.UserID AND x.IssueCode = codes.IssueCode
                );
                SELECT @@ROWCOUNT AS RowsInserted;
            ",
            params  = {},
            options = { datasource = variables.dsn }
        );
        return qry.RowsInserted;
    }

    public numeric function runCurrentStudents() {
        var qry = executeQueryWithRetry(
            sql = "
                INSERT INTO DataQualityExclusions (UserID, IssueCode, CreatedAt)
                SELECT q.UserID, codes.IssueCode, GETDATE()
                FROM (
                    SELECT DISTINCT u.UserID
                    FROM Users u
                    INNER JOIN UserFlagAssignments ufa ON ufa.UserID = u.UserID
                    INNER JOIN UserFlags uf ON uf.FlagID = ufa.FlagID
                        AND LOWER(TRIM(uf.FlagName)) = 'current-student'
                ) q
                CROSS JOIN (VALUES
                    ('missing_degrees'),('missing_phone'),
                    ('missing_building'),('missing_room')
                ) AS codes(IssueCode)
                WHERE NOT EXISTS (
                    SELECT 1 FROM DataQualityExclusions x
                    WHERE x.UserID = q.UserID AND x.IssueCode = codes.IssueCode
                );
                SELECT @@ROWCOUNT AS RowsInserted;
            ",
            params  = {},
            options = { datasource = variables.dsn }
        );
        return qry.RowsInserted;
    }

    public numeric function runFaculty() {
        var qry = executeQueryWithRetry(
            sql = "
                INSERT INTO DataQualityExclusions (UserID, IssueCode, CreatedAt)
                SELECT q.UserID, codes.IssueCode, GETDATE()
                FROM (
                    SELECT DISTINCT u.UserID
                    FROM Users u
                    INNER JOIN UserFlagAssignments ufa ON ufa.UserID = u.UserID
                    INNER JOIN UserFlags uf ON uf.FlagID = ufa.FlagID
                        AND LOWER(TRIM(uf.FlagName)) IN (
                            'faculty-fulltime','faculty-adjunct','joint faculty appointment'
                        )
                ) q
                CROSS JOIN (VALUES
                    ('missing_legacy_id'),('missing_peoplesoft')
                ) AS codes(IssueCode)
                WHERE NOT EXISTS (
                    SELECT 1 FROM DataQualityExclusions x
                    WHERE x.UserID = q.UserID AND x.IssueCode = codes.IssueCode
                );
                SELECT @@ROWCOUNT AS RowsInserted;
            ",
            params  = {},
            options = { datasource = variables.dsn }
        );
        return qry.RowsInserted;
    }

    public numeric function runRetirees() {
        var qry = executeQueryWithRetry(
            sql = "
                INSERT INTO DataQualityExclusions (UserID, IssueCode, CreatedAt)
                SELECT q.UserID, codes.IssueCode, GETDATE()
                FROM (
                    SELECT DISTINCT u.UserID
                    FROM Users u
                    INNER JOIN UserFlagAssignments ufa ON ufa.UserID = u.UserID
                    INNER JOIN UserFlags uf ON uf.FlagID = ufa.FlagID
                        AND LOWER(TRIM(uf.FlagName)) IN ('active retiree','professor emeritus')
                ) q
                CROSS JOIN (VALUES
                    ('missing_email_primary'),('missing_title1'),('missing_room'),
                    ('missing_building'),('missing_cougarnet'),('missing_peoplesoft'),
                    ('missing_legacy_id'),('missing_phone'),('missing_degrees')
                ) AS codes(IssueCode)
                WHERE NOT EXISTS (
                    SELECT 1 FROM DataQualityExclusions x
                    WHERE x.UserID = q.UserID AND x.IssueCode = codes.IssueCode
                );
                SELECT @@ROWCOUNT AS RowsInserted;
            ",
            params  = {},
            options = { datasource = variables.dsn }
        );
        return qry.RowsInserted;
    }

    public numeric function runStaff() {
        var qry = executeQueryWithRetry(
            sql = "
                INSERT INTO DataQualityExclusions (UserID, IssueCode, CreatedAt)
                SELECT q.UserID, codes.IssueCode, GETDATE()
                FROM (
                    SELECT DISTINCT u.UserID
                    FROM Users u
                    INNER JOIN UserFlagAssignments ufa ON ufa.UserID = u.UserID
                    INNER JOIN UserFlags uf ON uf.FlagID = ufa.FlagID
                        AND LOWER(TRIM(uf.FlagName)) = 'staff'
                ) q
                CROSS JOIN (VALUES
                    ('missing_legacy_id'),('missing_degrees'),('missing_peoplesoft_id')
                ) AS codes(IssueCode)
                WHERE NOT EXISTS (
                    SELECT 1 FROM DataQualityExclusions x
                    WHERE x.UserID = q.UserID AND x.IssueCode = codes.IssueCode
                );
                SELECT @@ROWCOUNT AS RowsInserted;
            ",
            params  = {},
            options = { datasource = variables.dsn }
        );
        return qry.RowsInserted;
    }

}
