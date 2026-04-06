component output="false" singleton {

    public any function init() {
        variables.ProfileDAO = createObject("component", "dir.dao.studentProfile_DAO").init();
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
        required string  hometown,
        required string  firstExternship,
        required string  secondExternship
    ) {
        variables.ProfileDAO.saveProfile( userID, {
            Hometown        = trim( hometown ),
            FirstExternship = trim( firstExternship ),
            SecondExternship= trim( secondExternship )
        });
    }

    public void function replaceAwards( required numeric userID, required array awards ) {
        variables.ProfileDAO.replaceAwards( userID, awards );
    }

}
