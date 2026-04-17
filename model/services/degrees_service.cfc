component output="false" singleton {

    public any function init() {
        variables.DegreesDAO = createObject("component", "dao.degrees_DAO").init();
        return this;
    }

    public struct function getDegrees( required numeric userID ) {
        return { success=true, data=variables.DegreesDAO.getDegrees( userID ) };
    }

    public void function replaceDegrees( required numeric userID, required array degrees ) {
        variables.DegreesDAO.replaceDegrees( userID, degrees );
        // Auto-update the composite Degrees field on the Users table
        var compositeStr = buildDegreesString( userID );
        var usersDAO = createObject("component", "dao.users_DAO").init();
        usersDAO.updateDegreesField( userID, compositeStr );
    }

    /**
     * Build the comma-separated Degrees string from the UserDegrees table
     * e.g. "O.D., Ph.D., FAAO"
     */
    public string function buildDegreesString( required numeric userID ) {
        var rows = variables.DegreesDAO.getDegrees( userID );
        var names = [];
        for ( var r in rows ) {
            if ( len(trim(r.DEGREENAME)) ) {
                arrayAppend( names, trim(r.DEGREENAME) );
            }
        }
        return arrayToList( names, ", " );
    }
}
