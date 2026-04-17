component extends="dao.BaseDAO" output="false" singleton {

    public any function init() {
        super.init();        return this;
    }

    public struct function getBio( required numeric userID ) {
        var qry = executeQueryWithRetry(
            "SELECT * FROM UserBio WHERE UserID = :id",
            { id={ value=userID, cfsqltype="cf_sql_integer" } },
            { datasource=variables.datasource, timeout=30, fetchSize=10 }
        );
        return (qry.recordCount > 0) ? qry.getRow(1) : {};
    }

    public void function saveBio( required numeric userID, required struct data ) {
        data.id = userID;
        var existing = getBio( userID );
        if ( structIsEmpty(existing) ) {
            executeQueryWithRetry(
                "INSERT INTO UserBio (UserID, BioContent) VALUES (:id, :BioContent)",
                data,
                { datasource=variables.datasource, timeout=30 }
            );
        } else {
            executeQueryWithRetry(
                "UPDATE UserBio SET BioContent = :BioContent, UpdatedAt = GETDATE() WHERE UserID = :id",
                data,
                { datasource=variables.datasource, timeout=30 }
            );
        }
    }

    public void function deleteForUser( required numeric userID ) {
        executeQueryWithRetry(
            "DELETE FROM UserBio WHERE UserID = :id",
            { id={ value=userID, cfsqltype="cf_sql_integer" } },
            { datasource=variables.datasource, timeout=30 }
        );
    }

}
