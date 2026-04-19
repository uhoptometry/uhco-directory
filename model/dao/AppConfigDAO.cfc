component extends="dao.BaseDAO" output="false" singleton {

    public any function init() {
        super.init();
        return this;
    }

    public string function getConfigValue( required string configKey ) {
        var qry = executeQueryWithRetry(
            "SELECT ConfigValue FROM AppConfig WHERE ConfigKey = :key",
            { key = { value=arguments.configKey, cfsqltype="cf_sql_nvarchar" } },
            { datasource=variables.datasource, timeout=30, fetchSize=1 }
        );

        return (qry.recordCount GT 0) ? trim(qry.ConfigValue) : "";
    }

    public void function setConfigValue(
        required string configKey,
        required string configValue
    ) {
        executeQueryWithRetry(
            "
            IF EXISTS (SELECT 1 FROM AppConfig WHERE ConfigKey = :key)
                UPDATE AppConfig
                SET    ConfigValue = :val,
                       UpdatedAt   = GETDATE()
                WHERE  ConfigKey = :key
            ELSE
                INSERT INTO AppConfig (ConfigKey, ConfigValue, UpdatedAt)
                VALUES (:key, :val, GETDATE())
            ",
            {
                key = { value=arguments.configKey, cfsqltype="cf_sql_nvarchar" },
                val = { value=arguments.configValue, cfsqltype="cf_sql_nvarchar" }
            },
            { datasource=variables.datasource, timeout=30 }
        );
    }

    public array function getAllConfig() {
        var qry = executeQueryWithRetry(
            "SELECT ConfigKey, ConfigValue, UpdatedAt FROM AppConfig ORDER BY ConfigKey",
            {},
            { datasource=variables.datasource, timeout=30, fetchSize=200 }
        );

        return queryToArray(qry);
    }

}