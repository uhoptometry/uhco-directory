component output="false" singleton {

    public any function init() {
        variables.AppConfigDAO = createObject("component", "dao.AppConfigDAO").init();
        return this;
    }

    public string function getValue(
        required string configKey,
        string defaultValue = ""
    ) {
        var value = variables.AppConfigDAO.getConfigValue( arguments.configKey );
        return len(value) ? value : arguments.defaultValue;
    }

    public void function setValue(
        required string configKey,
        required string configValue
    ) {
        variables.AppConfigDAO.setConfigValue( arguments.configKey, trim(arguments.configValue) );
    }

    public array function getAll() {
        return variables.AppConfigDAO.getAllConfig();
    }

}