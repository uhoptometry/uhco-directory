component output="false" singleton {

    public any function init() {
        variables.dao = createObject("component", "dao.quickpull_DAO").init();
        return this;
    }

    /**
     * Clinical-Attending quick pull.
     * Flat list: UserID, FirstName, MiddleName, LastName, Degrees (display string).
     */
    public array function getAttending() {
        var users = variables.dao.getAttendingUsers();
        for (var i = 1; i <= arrayLen(users); i++) {
            var parts = [];
            if (len(trim(users[i].FIRSTNAME)))  arrayAppend(parts, trim(users[i].FIRSTNAME));
            if (len(trim(users[i].MIDDLENAME))) arrayAppend(parts, trim(users[i].MIDDLENAME));
            if (len(trim(users[i].LASTNAME)))   arrayAppend(parts, trim(users[i].LASTNAME));
            var fullName = arrayToList(parts, " ");
            if (len(trim(users[i].DEGREES ?: ""))) {
                fullName &= ", " & trim(users[i].DEGREES);
            }
            users[i]["FULLNAME"] = fullName;
        }
        return users;
    }

    /**
     * Alumni graduation class quick pull.
     * Flat list filtered by grad year: UserID, FirstName, MiddleName, LastName, CurrentGradYear.
     */
    public array function getGradClass( required numeric gradYear, required string programName ) {
        var users = variables.dao.getGradClassUsers( arguments.gradYear, arguments.programName );
        if ( arrayLen(users) == 0 ) return [];

        var ids = [];
        for ( var user in users ) {
            arrayAppend( ids, user.USERID );
        }

        var interactiveMap = variables.dao.getImageMapByVariant( "interactive_roster", ids );
        var rosterMap      = variables.dao.getImageMapByVariant( "KIOSK_ROSTER", ids );
        var profileMap     = variables.dao.getImageMapByVariant( "KIOSK_PROFILE", ids );

        for ( var i = 1; i <= arrayLen(users); i++ ) {
            var key = toString( users[i].USERID );
            users[i]["FULLNAME"] = buildFullName( users[i] );
            users[i]["INTERACTIVEUSERIMAGE"] = structKeyExists( interactiveMap, key ) ? interactiveMap[ key ] : "";
            users[i]["KIOSKROSTERIMAGE"] = structKeyExists( rosterMap, key ) ? rosterMap[ key ] : "";
            users[i]["KIOSKPROFILEIMAGE"] = structKeyExists( profileMap, key ) ? profileMap[ key ] : "";
        }

        return users;
    }

    /**
     * Full graduate quick pull for a single user.
     * Returns a struct with nested degrees, awards, and kiosk images.
     * Returns empty struct if user not found or not an Alumni.
     */
    public struct function getGraduate( required numeric userID ) {
        var users = variables.dao.getGraduateUser( arguments.userID );
        if ( arrayLen(users) == 0 ) return {};

        var user = users[1];
        var uid  = arguments.userID;
        var ids  = [ uid ];

        // Fetch related data
        user["DEGREES"]           = variables.dao.getDegreesForUsers( ids );
        user["AWARDS"]            = variables.dao.getAwardsForUsers( ids );

        var interactiveMap = variables.dao.getImageMapByVariant( "interactive_roster", ids );
        var rosterMap      = variables.dao.getImageMapByVariant( "KIOSK_ROSTER",  ids );
        var profileMap     = variables.dao.getImageMapByVariant( "KIOSK_PROFILE", ids );
        var key = toString( uid );
        user["INTERACTIVEUSERIMAGE"] = structKeyExists( interactiveMap, key ) ? interactiveMap[ key ] : "";
        user["KIOSKROSTERIMAGE"]  = structKeyExists( rosterMap,  key ) ? rosterMap[ key ]  : "";
        user["KIOSKPROFILEIMAGE"] = structKeyExists( profileMap, key ) ? profileMap[ key ] : "";

        return user;
    }

    /**
     * Deans quick pull with kiosk non-grid image.
     */
    public array function getDeans() {
        var users = variables.dao.getDeansUsers();
        if ( arrayLen(users) == 0 ) return [];

        var ids = [];
        for ( var u in users ) {
            arrayAppend( ids, u.USERID );
        }

        var nonGridMap = variables.dao.getImageMapByVariant( "KIOSK_NON_GRID", ids );

        for ( var i = 1; i <= arrayLen(users); i++ ) {
            var uid = toString( users[i].USERID );
            users[i]["FULLNAME"] = buildFullName( users[i] );
            users[i]["KIOSKNONGRIDIMAGE"] = structKeyExists( nonGridMap, uid ) ? nonGridMap[ uid ] : "";
        }

        return users;
    }

    private string function buildFullName( required struct user ) {
        var parts = [];
        if ( len(trim(arguments.user.FIRSTNAME ?: "")) ) {
            arrayAppend( parts, trim(arguments.user.FIRSTNAME) );
        }
        if ( len(trim(arguments.user.MIDDLENAME ?: "")) ) {
            arrayAppend( parts, trim(arguments.user.MIDDLENAME) );
        }
        if ( len(trim(arguments.user.LASTNAME ?: "")) ) {
            arrayAppend( parts, trim(arguments.user.LASTNAME) );
        }
        return arrayToList( parts, " " );
    }

}
