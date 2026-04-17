component extends="dao.BaseDAO" output="false" singleton {

    public any function init() {
        super.init();        return this;
    }

    public array function getDegrees( required numeric userID ) {
        var qry = executeQueryWithRetry(
            "SELECT * FROM UserDegrees WHERE UserID = :id ORDER BY DegreeID",
            { id={ value=userID, cfsqltype="cf_sql_integer" } },
            { datasource=variables.datasource, timeout=30, fetchSize=100 }
        );
        return queryToArray(qry);
    }

    public void function replaceDegrees( required numeric userID, required array degrees ) {
        var idParam = { id={ value=userID, cfsqltype="cf_sql_integer" } };
        executeQueryWithRetry(
            "DELETE FROM UserDegrees WHERE UserID = :id",
            idParam, { datasource=variables.datasource, timeout=30 }
        );
        for ( var deg in arguments.degrees ) {
            executeQueryWithRetry(
                "INSERT INTO UserDegrees (UserID, DegreeName, University, DegreeYear) VALUES (:id, :DegreeName, :University, :DegreeYear)",
                {
                    id         = { value=userID,              cfsqltype="cf_sql_integer"  },
                    DegreeName = { value=deg.name,            cfsqltype="cf_sql_nvarchar" },
                    University = { value=deg.university,      cfsqltype="cf_sql_nvarchar" },
                    DegreeYear = { value=deg.year,            cfsqltype="cf_sql_nvarchar" }
                },
                { datasource=variables.datasource, timeout=30 }
            );
        }
    }

    public void function deleteAllForUser( required numeric userID ) {
        var idParam = { id={ value=userID, cfsqltype="cf_sql_integer" } };
        executeQueryWithRetry( "DELETE FROM UserDegrees WHERE UserID = :id", idParam, { datasource=variables.datasource, timeout=30 } );
    }
}
