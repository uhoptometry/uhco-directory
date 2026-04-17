component extends="dao.BaseDAO" output="false" singleton {

    public any function init() {
        super.init();        return this;
    }

    public array function getSystems() {
        var qry = executeQueryWithRetry(
            "SELECT * FROM ExternalSystems ORDER BY SystemName",
            {},
            { datasource=variables.datasource, timeout=30, fetchSize=100 }
        );
        return queryToArray(qry);
    }

    public array function getSystem( required numeric systemID ) {
        var qry = executeQueryWithRetry(
            "SELECT * FROM ExternalSystems WHERE SystemID = :systemID",
            { systemID={ value=arguments.systemID, cfsqltype="cf_sql_integer" } },
            { datasource=variables.datasource, timeout=30 }
        );
        return queryToArray(qry);
    }

    public void function updateSystem( required numeric systemID, required string systemName ) {
        executeQueryWithRetry(
            "UPDATE ExternalSystems SET SystemName = :systemName WHERE SystemID = :systemID",
            {
                systemName={ value=trim(arguments.systemName), cfsqltype="cf_sql_varchar" },
                systemID={ value=arguments.systemID, cfsqltype="cf_sql_integer" }
            },
            { datasource=variables.datasource, timeout=30 }
        );
    }

    public void function deleteSystem( required numeric systemID ) {
        executeQueryWithRetry(
            "DELETE FROM ExternalSystems WHERE SystemID = :systemID",
            { systemID={ value=arguments.systemID, cfsqltype="cf_sql_integer" } },
            { datasource=variables.datasource, timeout=30 }
        );
    }

}