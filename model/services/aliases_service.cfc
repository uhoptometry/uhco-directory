component output="false" singleton {

    public any function init() {
        variables.AliasesDAO = createObject("component", "dao.aliases_DAO").init();
        return this;
    }

    public struct function getAliases( required numeric userID ) {
        return { success=true, data=variables.AliasesDAO.getAliases( userID ) };
    }

    public array function getAliasTypes() {
        return variables.AliasesDAO.getAliasTypes();
    }

    public void function replaceAliases( required numeric userID, required array aliases ) {
        variables.AliasesDAO.replaceAliases( userID, aliases );
    }
}
