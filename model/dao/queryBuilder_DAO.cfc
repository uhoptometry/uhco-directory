component extends="BaseDAO" output="false" singleton {

    public any function init() {
        super.init();        return this;
    }

    /**
     * Return user-related tables in the database (table name contains 'user').
     */
    public array function getTableList() {
        var qry = executeQueryWithRetry(
            "SELECT TABLE_NAME
             FROM INFORMATION_SCHEMA.TABLES
             WHERE TABLE_TYPE = 'BASE TABLE'
               AND TABLE_CATALOG = DB_NAME()
               AND TABLE_NAME LIKE '%user%'
               AND TABLE_NAME NOT IN ('AdminUsers','AdminUserRoles')
             ORDER BY TABLE_NAME",
            {},
            { datasource=variables.datasource, timeout=15 }
        );
        var result = [];
        for (var i = 1; i <= qry.recordCount; i++) {
            arrayAppend(result, qry.TABLE_NAME[i]);
        }
        return result;
    }

    /**
     * Return column metadata for a given table.
     * Returns array of { COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE }.
     */
    public array function getColumnsForTable(required string tableName) {
        var qry = executeQueryWithRetry(
            "SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE
             FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_NAME = :tbl AND TABLE_CATALOG = DB_NAME()
             ORDER BY ORDINAL_POSITION",
            { tbl = { value=arguments.tableName, cfsqltype="cf_sql_nvarchar" } },
            { datasource=variables.datasource, timeout=15 }
        );
        return queryToArray(qry);
    }

    /**
     * Execute a pre-built SELECT query with a row limit and timeout.
     * Returns the raw query object (not array) so callers can access columnList and recordCount.
     */
    public any function executeSelectQuery(
        required string sql,
        struct params = {},
        numeric timeout = 30
    ) {
        return executeQueryWithRetry(
            arguments.sql,
            arguments.params,
            { datasource=variables.datasource, timeout=arguments.timeout }
        );
    }

}
