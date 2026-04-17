component extends="dao.BaseDAO" output="false" singleton {

    public any function init() {
        super.init();        return this;
    }

    public struct function getProfile( required numeric userID ) {
        var qry = executeQueryWithRetry(
            "SELECT * FROM UserStudentProfile WHERE UserID = :id",
            { id={ value=userID, cfsqltype="cf_sql_integer" } },
            { datasource=variables.datasource, timeout=30, fetchSize=10 }
        );
        return (qry.recordCount > 0) ? qry.getRow(1) : {};
    }

    public void function saveProfile( required numeric userID, required struct data ) {
        data.id = userID;
        var existing = getProfile( userID );
        if ( structIsEmpty(existing) ) {
            executeQueryWithRetry(
                "INSERT INTO UserStudentProfile (UserID, FirstExternship, SecondExternship, CommencementAge)
                 VALUES (:id, :FirstExternship, :SecondExternship, :CommencementAge)",
                data,
                { datasource=variables.datasource, timeout=30 }
            );
        } else {
            executeQueryWithRetry(
                "UPDATE UserStudentProfile
                 SET FirstExternship=:FirstExternship, SecondExternship=:SecondExternship,
                     CommencementAge=:CommencementAge,
                     UpdatedAt=GETDATE()
                 WHERE UserID=:id",
                data,
                { datasource=variables.datasource, timeout=30 }
            );
        }
    }

    public array function getAwards( required numeric userID ) {
        var qry = executeQueryWithRetry(
            "SELECT * FROM UserAwards WHERE UserID = :id ORDER BY AwardID",
            { id={ value=userID, cfsqltype="cf_sql_integer" } },
            { datasource=variables.datasource, timeout=30, fetchSize=100 }
        );
        return queryToArray(qry);
    }

    public void function replaceAwards( required numeric userID, required array awards ) {
        var idParam = { id={ value=userID, cfsqltype="cf_sql_integer" } };
        executeQueryWithRetry(
            "DELETE FROM UserAwards WHERE UserID = :id",
            idParam,
            { datasource=variables.datasource, timeout=30 }
        );
        for ( var award in arguments.awards ) {
            executeQueryWithRetry(
                "INSERT INTO UserAwards (UserID, AwardName, AwardType) VALUES (:id, :AwardName, :AwardType)",
                {
                    id        = { value=userID,         cfsqltype="cf_sql_integer"  },
                    AwardName = { value=award.name,     cfsqltype="cf_sql_nvarchar" },
                    AwardType = { value=award.type,     cfsqltype="cf_sql_nvarchar" }
                },
                { datasource=variables.datasource, timeout=30 }
            );
        }
    }

    public void function deleteAllForUser( required numeric userID ) {
        var idParam = { id={ value=userID, cfsqltype="cf_sql_integer" } };
        executeQueryWithRetry( "DELETE FROM UserAwards          WHERE UserID = :id", idParam, { datasource=variables.datasource, timeout=30 } );
        executeQueryWithRetry( "DELETE FROM UserStudentProfile  WHERE UserID = :id", idParam, { datasource=variables.datasource, timeout=30 } );
    }

}
