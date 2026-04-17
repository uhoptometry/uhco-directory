/**
 * FileNamePatternDAO.cfc
 *
 * Database access for the FileNamePatterns table.
 * Patterns use token placeholders ({first}, {last}, {middle}, {fi}, {mi})
 * that are resolved at runtime against user fields.
 */
component extends="dao.BaseDAO" output="false" singleton {

    public any function init() {
        super.init();        return this;
    }


    /**
     * Return all active patterns ordered by SortOrder then Pattern.
     */
    public array function getActivePatterns() {
        var qry = executeQueryWithRetry(
            "
            SELECT FileNamePatternID, Pattern, Description, IsActive, SortOrder
            FROM   FileNamePatterns
            WHERE  IsActive = 1
            ORDER  BY SortOrder, Pattern
            ",
            {},
            { datasource=variables.datasource, timeout=30, fetchSize=200 }
        );
        return queryToArray(qry);
    }

    /**
     * Return ALL patterns including inactive, for the admin page.
     */
    public array function getAllPatterns() {
        var qry = executeQueryWithRetry(
            "
            SELECT FileNamePatternID, Pattern, Description, IsActive, SortOrder
            FROM   FileNamePatterns
            ORDER  BY SortOrder, Pattern
            ",
            {},
            { datasource=variables.datasource, timeout=30, fetchSize=200 }
        );
        return queryToArray(qry);
    }

    /**
     * Return a single pattern by ID (includes inactive for admin editing).
     */
    public struct function getPatternByID( required numeric fileNamePatternID ) {
        var qry = executeQueryWithRetry(
            "SELECT * FROM FileNamePatterns WHERE FileNamePatternID = :id",
            { id = { value=arguments.fileNamePatternID, cfsqltype="cf_sql_integer" } },
            { datasource=variables.datasource, timeout=30, fetchSize=1 }
        );
        return (qry.recordCount GT 0) ? qry.getRow(1) : {};
    }

    /**
     * Insert a new pattern. Returns the new ID.
     */
    public numeric function insertPattern(
        required string  pattern,
        string  description = "",
        boolean isActive    = true,
        numeric sortOrder   = 0
    ) {
        var qry = executeQueryWithRetry(
            "
            INSERT INTO FileNamePatterns (Pattern, Description, IsActive, SortOrder)
            VALUES (:pattern, :description, :isActive, :sortOrder);
            SELECT SCOPE_IDENTITY() AS newID;
            ",
            {
                pattern     = { value=arguments.pattern,     cfsqltype="cf_sql_nvarchar" },
                description = { value=arguments.description, cfsqltype="cf_sql_nvarchar" },
                isActive    = { value=arguments.isActive,    cfsqltype="cf_sql_bit" },
                sortOrder   = { value=arguments.sortOrder,   cfsqltype="cf_sql_integer" }
            },
            { datasource=variables.datasource, timeout=30 }
        );
        return val(qry.newID);
    }

    /**
     * Update an existing pattern.
     */
    public void function updatePattern(
        required numeric fileNamePatternID,
        required string  pattern,
        string  description = "",
        boolean isActive    = true,
        numeric sortOrder   = 0
    ) {
        executeQueryWithRetry(
            "
            UPDATE FileNamePatterns
            SET    Pattern     = :pattern,
                   Description = :description,
                   IsActive    = :isActive,
                   SortOrder   = :sortOrder,
                   ModifiedAt  = GETDATE()
            WHERE  FileNamePatternID = :id
            ",
            {
                id          = { value=arguments.fileNamePatternID, cfsqltype="cf_sql_integer" },
                pattern     = { value=arguments.pattern,          cfsqltype="cf_sql_nvarchar" },
                description = { value=arguments.description,      cfsqltype="cf_sql_nvarchar" },
                isActive    = { value=arguments.isActive,         cfsqltype="cf_sql_bit" },
                sortOrder   = { value=arguments.sortOrder,        cfsqltype="cf_sql_integer" }
            },
            { datasource=variables.datasource, timeout=30 }
        );
    }

    /**
     * Hard-delete a pattern.
     */
    public void function deletePattern( required numeric fileNamePatternID ) {
        executeQueryWithRetry(
            "DELETE FROM FileNamePatterns WHERE FileNamePatternID = :id",
            { id = { value=arguments.fileNamePatternID, cfsqltype="cf_sql_integer" } },
            { datasource=variables.datasource, timeout=30 }
        );
    }

}
