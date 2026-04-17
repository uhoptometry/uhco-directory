component output="false" singleton {

    public any function init() {
        variables.dao = createObject("component", "dao.queryBuilder_DAO").init();
        variables.maxRows = 10000;
        return this;
    }

    /**
     * Get all valid table names from INFORMATION_SCHEMA.
     */
    public array function getTableList() {
        return variables.dao.getTableList();
    }

    /**
     * Get column metadata for a validated table.
     * Throws if table is not in the whitelist.
     */
    public array function getColumnsForTable(required string tableName) {
        validateTableName(arguments.tableName);
        return variables.dao.getColumnsForTable(arguments.tableName);
    }

    /**
     * Build and execute a SELECT query from structured parameters.
     *
     * @tableName   The table to query (validated against INFORMATION_SCHEMA)
     * @columns     Array of column names (validated against INFORMATION_SCHEMA)
     * @conditions  Array of structs: { column, operator, value }
     * @orderBy     Array of structs: { column, direction }
     * @maxRows     Max rows to return (capped at variables.maxRows)
     *
     * Returns struct: { sql, results (query object), rowCount, truncated }
     */
    public struct function executeQuery(
        required string tableName,
        required array columns,
        array conditions = [],
        array orderBy = [],
        numeric maxRows = 1000
    ) {
        // Validate table
        validateTableName(arguments.tableName);

        // Validate columns
        var validColumns = variables.dao.getColumnsForTable(arguments.tableName);
        var validColNames = {};
        for (var vc in validColumns) {
            validColNames[uCase(vc.COLUMN_NAME)] = true;
        }
        for (var col in arguments.columns) {
            if (!structKeyExists(validColNames, uCase(col))) {
                throw(type="QueryBuilder.InvalidColumn", message="Invalid column: #col#");
            }
        }

        // Validate condition columns
        for (var cond in arguments.conditions) {
            if (!structKeyExists(validColNames, uCase(cond.column))) {
                throw(type="QueryBuilder.InvalidColumn", message="Invalid condition column: #cond.column#");
            }
        }

        // Validate orderBy columns
        for (var ob in arguments.orderBy) {
            if (!structKeyExists(validColNames, uCase(ob.column))) {
                throw(type="QueryBuilder.InvalidColumn", message="Invalid order-by column: #ob.column#");
            }
        }

        // Cap rows
        var rowLimit = min(val(arguments.maxRows), variables.maxRows);
        if (rowLimit LT 1) rowLimit = 1000;

        // Build SQL
        var selectCols = arrayToList(arguments.columns, ", ");
        // Bracket-escape column names
        var bracketedCols = [];
        for (var c in arguments.columns) {
            arrayAppend(bracketedCols, "[" & c & "]");
        }
        var sql = "SELECT TOP #rowLimit# " & arrayToList(bracketedCols, ", ")
                & " FROM [" & arguments.tableName & "]";

        var params = {};
        var paramIdx = 0;

        // WHERE clauses
        if (arrayLen(arguments.conditions)) {
            var whereParts = [];
            for (var cond in arguments.conditions) {
                paramIdx++;
                var pName = "p#paramIdx#";
                var op = validateOperator(cond.operator);
                if (op EQ "IS NULL" OR op EQ "IS NOT NULL") {
                    arrayAppend(whereParts, "[" & cond.column & "] " & op);
                } else if (op EQ "LIKE") {
                    arrayAppend(whereParts, "[" & cond.column & "] LIKE :#pName#");
                    params[pName] = { value="%" & cond.value & "%", cfsqltype="cf_sql_nvarchar" };
                } else if (op EQ "IN") {
                    // Split comma-separated values into individual params
                    var inValues = listToArray(cond.value);
                    var inParams = [];
                    for (var iv = 1; iv <= arrayLen(inValues); iv++) {
                        var ipName = "p#paramIdx#_#iv#";
                        arrayAppend(inParams, ":#ipName#");
                        params[ipName] = { value=trim(inValues[iv]), cfsqltype="cf_sql_nvarchar" };
                    }
                    if (arrayLen(inParams)) {
                        arrayAppend(whereParts, "[" & cond.column & "] IN (" & arrayToList(inParams, ",") & ")");
                    }
                } else {
                    arrayAppend(whereParts, "[" & cond.column & "] " & op & " :#pName#");
                    params[pName] = { value=cond.value, cfsqltype="cf_sql_nvarchar" };
                }
            }
            if (arrayLen(whereParts)) {
                sql &= " WHERE " & arrayToList(whereParts, " AND ");
            }
        }

        // ORDER BY
        if (arrayLen(arguments.orderBy)) {
            var orderParts = [];
            for (var ob in arguments.orderBy) {
                var dir = (uCase(trim(ob.direction ?: "ASC")) EQ "DESC") ? "DESC" : "ASC";
                arrayAppend(orderParts, "[" & ob.column & "] " & dir);
            }
            sql &= " ORDER BY " & arrayToList(orderParts, ", ");
        }

        // Execute
        var qry = variables.dao.executeSelectQuery(sql, params, 30);

        return {
            sql       = sql,
            rowCount  = qry.recordCount,
            truncated = (qry.recordCount GTE rowLimit),
            results   = qry
        };
    }

    // ── Private helpers ─────────────────────────────────────────────

    /**
     * Validate table name exists in INFORMATION_SCHEMA.
     */
    private void function validateTableName(required string tableName) {
        var tables = variables.dao.getTableList();
        var found = false;
        for (var t in tables) {
            if (compareNoCase(t, arguments.tableName) EQ 0) {
                found = true;
                break;
            }
        }
        if (!found) {
            throw(type="QueryBuilder.InvalidTable", message="Invalid table: #arguments.tableName#");
        }
    }

    /**
     * Validate and normalize a WHERE operator.
     */
    private string function validateOperator(required string op) {
        var allowed = {
            "="           : "=",
            "!="          : "!=",
            "<>"          : "<>",
            ">"           : ">",
            ">="          : ">=",
            "<"           : "<",
            "<="          : "<=",
            "LIKE"        : "LIKE",
            "IN"          : "IN",
            "IS NULL"     : "IS NULL",
            "IS NOT NULL" : "IS NOT NULL"
        };
        var normalized = uCase(trim(arguments.op));
        if (structKeyExists(allowed, normalized)) {
            return allowed[normalized];
        }
        throw(type="QueryBuilder.InvalidOperator", message="Invalid operator: #arguments.op#");
    }

}
