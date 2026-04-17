component output="false" singleton {

    public any function init() {
        variables.ExternalIDsDAO = createObject("component", "dao.externalIDs_DAO").init();
        variables.ExternalSystemsDAO = createObject("component", "dao.externalsystems_DAO").init();
        return this;
    }

    public struct function getSystems() {
        return {
            success=true,
            data=variables.ExternalSystemsDAO.getSystems()
        };
    }

    public struct function getSystem( required numeric systemID ) {
        var rows = variables.ExternalSystemsDAO.getSystem( arguments.systemID );
        if ( arrayLen(rows) ) {
            return { success=true, data=rows[1] };
        }
        return { success=false, message="System not found." };
    }

    public struct function updateSystem( required numeric systemID, required string systemName ) {
        variables.ExternalSystemsDAO.updateSystem( arguments.systemID, arguments.systemName );
        return { success=true, message="System updated." };
    }

    public struct function deleteSystem( required numeric systemID ) {
        variables.ExternalSystemsDAO.deleteSystem( arguments.systemID );
        return { success=true, message="System deleted." };
    }

    public struct function getExternalIDs( required numeric userID ) {
        return { success=true, data=variables.ExternalIDsDAO.getExternalIDs( userID ) };
    }

    public struct function setExternalID(
        required numeric userID,
        required numeric systemID,
        required string value
    ) {
        variables.ExternalIDsDAO.setExternalID( userID, systemID, trim( value ) );
        return { success=true, message="External ID saved." };
    }

    // Returns struct keyed by ExternalValue (trimmed, lower-cased) → UserID, for a given SystemID
    public struct function getValueToUserMap( required numeric systemID ) {
        var rows = variables.ExternalIDsDAO.getAllExternalIDs();
        var result = {};
        for ( var row in rows ) {
            if ( row.SYSTEMID == arguments.systemID ) {
                var k = lCase( trim( row.EXTERNALVALUE ) );
                if ( len(k) ) result[ k ] = row.USERID;
            }
        }
        return result;
    }

}