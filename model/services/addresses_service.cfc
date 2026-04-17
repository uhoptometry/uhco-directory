component output="false" singleton {

    public any function init() {
        variables.AddressesDAO = createObject("component", "dao.addresses_DAO").init();
        return this;
    }

    public struct function getAddresses( required numeric userID ) {
        return { success=true, data=variables.AddressesDAO.getAddresses( userID ) };
    }

    public struct function addAddress( required struct data ) {

        // Business rule: Building codes must be uppercase
        if ( structKeyExists( data, "Building" ) ) {
            if ( isStruct( data.Building ) ) {
                data.Building.value = uCase( trim( data.Building.value ) );
            } else {
                data.Building = uCase( trim( data.Building ) );
            }
        }

        var id = variables.AddressesDAO.createAddress( data );

        return { success=true, addressID=id };
    }

    public struct function replaceAddresses( required numeric userID, required array addresses ) {
        for ( var addr in addresses ) {
            if ( structKeyExists( addr, "Building" ) ) {
                if ( isStruct( addr.Building ) ) {
                    addr.Building.value = uCase( trim( addr.Building.value ) );
                } else {
                    addr.Building = uCase( trim( addr.Building ) );
                }
            }
        }
        variables.AddressesDAO.replaceAddresses( userID, addresses );
        return { success=true };
    }

    public struct function deleteAddress( required numeric addressID ) {
        variables.AddressesDAO.deleteAddress( addressID );
        return { success=true };
    }

    public struct function deleteAllForUser( required numeric userID ) {
        variables.AddressesDAO.deleteAllForUser( userID );
        return { success=true };
    }

}