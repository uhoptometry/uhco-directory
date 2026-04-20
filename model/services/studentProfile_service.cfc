component output="false" singleton {

    public any function init() {
        variables.ProfileDAO = createObject("component", "dao.studentProfile_DAO").init();
        return this;
    }

    public struct function getProfile( required numeric userID ) {
        return { success=true, data=variables.ProfileDAO.getProfile( userID ) };
    }

    public struct function getAwards( required numeric userID ) {
        return { success=true, data=variables.ProfileDAO.getAwards( userID ) };
    }

    public void function saveProfile(
        required numeric userID,
        required string  firstExternship,
        required string  secondExternship,
        required string  commencementAge
    ) {
        variables.ProfileDAO.saveProfile( userID, {
            FirstExternship  = trim( firstExternship ),
            SecondExternship = trim( secondExternship ),
            CommencementAge  = { value=(len(trim(commencementAge)) AND isNumeric(trim(commencementAge)) ? val(trim(commencementAge)) : ""), cfsqltype="cf_sql_integer", null=(!len(trim(commencementAge)) OR !isNumeric(trim(commencementAge))) }
        });
    }

    public void function syncHometown( required numeric userID, string hometownCity = "", string hometownState = "" ) {
        variables.ProfileDAO.saveHometown( userID, trim(arguments.hometownCity), trim(arguments.hometownState) );
    }

    public void function replaceAwards( required numeric userID, required array awards ) {
        variables.ProfileDAO.replaceAwards( userID, awards );
    }

}
