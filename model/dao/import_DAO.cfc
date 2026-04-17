component extends="BaseDAO" output="false" singleton {

    public any function init() {
        super.init();        return this;
    }

    /**
     * Create a new import run record and return the run_id.
     */
    public numeric function createRun(
        required string templateKey,
        required string fileName,
        required numeric totalRows,
        required string startedBy
    ) {
        var qry = executeQueryWithRetry(
            "INSERT INTO ImportRuns (template_key, file_name, total_rows, started_by)
             OUTPUT INSERTED.run_id
             VALUES (:tpl, :fn, :rows, :usr)",
            {
                tpl  = { value=arguments.templateKey, cfsqltype="cf_sql_nvarchar" },
                fn   = { value=arguments.fileName,    cfsqltype="cf_sql_nvarchar" },
                rows = { value=arguments.totalRows,   cfsqltype="cf_sql_integer"  },
                usr  = { value=arguments.startedBy,   cfsqltype="cf_sql_nvarchar" }
            },
            { datasource=variables.datasource, timeout=15 }
        );
        return qry.run_id;
    }

    /**
     * Log one row result for an import run.
     */
    public void function addDetail(
        required numeric runID,
        required numeric rowNumber,
        required string status,
        string message = "",
        string rowData = ""
    ) {
        executeQueryWithRetry(
            "INSERT INTO ImportRunDetails (run_id, row_number, status, message, row_data)
             VALUES (:rid, :rn, :st, :msg, :rd)",
            {
                rid = { value=arguments.runID,     cfsqltype="cf_sql_integer"  },
                rn  = { value=arguments.rowNumber, cfsqltype="cf_sql_integer"  },
                st  = { value=arguments.status,    cfsqltype="cf_sql_nvarchar" },
                msg = { value=arguments.message,   cfsqltype="cf_sql_nvarchar" },
                rd  = { value=arguments.rowData,   cfsqltype="cf_sql_nvarchar" }
            },
            { datasource=variables.datasource, timeout=15 }
        );
    }

    /**
     * Finalize a run with counts and completed status.
     */
    public void function completeRun(
        required numeric runID,
        required numeric successCount,
        required numeric skipCount,
        required numeric errorCount,
        string status = "completed"
    ) {
        executeQueryWithRetry(
            "UPDATE ImportRuns
                SET success_count = :sc, skip_count = :sk, error_count = :ec,
                    completed_at = GETDATE(), status = :st
              WHERE run_id = :rid",
            {
                sc  = { value=arguments.successCount, cfsqltype="cf_sql_integer"  },
                sk  = { value=arguments.skipCount,    cfsqltype="cf_sql_integer"  },
                ec  = { value=arguments.errorCount,   cfsqltype="cf_sql_integer"  },
                st  = { value=arguments.status,       cfsqltype="cf_sql_nvarchar" },
                rid = { value=arguments.runID,         cfsqltype="cf_sql_integer"  }
            },
            { datasource=variables.datasource, timeout=15 }
        );
    }

    /**
     * Get recent import runs, optionally filtered by template.
     */
    public array function getRecentRuns(string templateKey = "", numeric maxRows = 25) {
        var sql = "SELECT TOP (:mx) run_id, template_key, file_name, total_rows,
                          success_count, skip_count, error_count,
                          started_by, started_at, completed_at, status
                     FROM ImportRuns";
        var params = { mx = { value=arguments.maxRows, cfsqltype="cf_sql_integer" } };

        if (len(trim(arguments.templateKey))) {
            sql &= " WHERE template_key = :tpl";
            params.tpl = { value=arguments.templateKey, cfsqltype="cf_sql_nvarchar" };
        }
        sql &= " ORDER BY started_at DESC";

        return queryToArray(
            executeQueryWithRetry(sql, params, { datasource=variables.datasource, timeout=15 })
        );
    }

    /**
     * Get details for a specific run.
     */
    public array function getRunDetails(required numeric runID) {
        return queryToArray(
            executeQueryWithRetry(
                "SELECT detail_id, run_id, row_number, status, message, row_data, created_at
                   FROM ImportRunDetails
                  WHERE run_id = :rid
                  ORDER BY row_number",
                { rid = { value=arguments.runID, cfsqltype="cf_sql_integer" } },
                { datasource=variables.datasource, timeout=30 }
            )
        );
    }

    /**
     * Get a single run by ID.
     */
    public array function getRun(required numeric runID) {
        return queryToArray(
            executeQueryWithRetry(
                "SELECT run_id, template_key, file_name, total_rows,
                        success_count, skip_count, error_count,
                        started_by, started_at, completed_at, status
                   FROM ImportRuns
                  WHERE run_id = :rid",
                { rid = { value=arguments.runID, cfsqltype="cf_sql_integer" } },
                { datasource=variables.datasource, timeout=15 }
            )
        );
    }
}
