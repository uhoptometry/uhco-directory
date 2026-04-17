<cfcomponent displayname="AuthService" output="false">

  <cffunction
    name="authenticate"
    access="public"
    returntype="struct"
    output="false"
  >
    <cfargument name="username" type="string" required="true">
    <cfargument name="password" type="string" required="true">

    <cfset var result = {
      success = false,
      message = "",
      user    = {}
    }>

    <cftry>
      <cfldap
        action="QUERY"
        name="GetUserInfo"
        attributes="displayName,memberOf,sAMAccountName,mail,telephoneNumber,accountExpires,userAccountControl,department,title,initials"
        start="DC=cougarnet,DC=uh,DC=edu"
        scope="SUBTREE"
        filter="(&(objectClass=User)(objectCategory=Person)(sAMAccountName=#arguments.username#)(|(memberOf=CN=OPT-ASC,OU=ASC USERS,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu)(memberOf=CN=OPT-STAFF,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu)(memberOf=CN=OPT-OPTOMETRY,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu)(memberOf=CN=OPT-FACULTY-1,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu)(memberOf=CN=OPT-CLASS2022,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu)(memberOf=CN=OPT-CLASS2023,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu)(memberOf=CN=OPT-CLASS2024,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu)(memberOf=CN=OPT-CLASS2025,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu)(memberOf=CN=OPT-CLASS2026,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu)))"
        maxrows="1"
        server="cougarnet.uh.edu"
        username="COUGARNET\#arguments.username#"
        password="#arguments.password#">
  
      <!--- Authorization check --->
      <cfif GetUserInfo.recordCount EQ 0>
        <cfset result.message = "User not authorized">
        <cfreturn result>
      </cfif>

      <!--- Disabled account --->
      <cfif bitAnd(GetUserInfo.userAccountControl, 2)>
        <cfset result.message = "Account disabled">
        <cfreturn result>
      </cfif>

      <!--- Account expired --->
      <cfif GetUserInfo.accountExpires NEQ 0
         AND GetUserInfo.accountExpires LT
           dateDiff("s", createDate(1601,1,1), now())>
        <cfset result.message = "Account expired">
        <cfreturn result>
      </cfif>

      <!--- Verify against access membership --->
        <cfquery datasource="#request.datasource#" name="accessCheck">
            SELECT *
            FROM AdminUsers
            WHERE cougarnet = <cfqueryparam value="#GetUserInfo.sAMAccountName#" cfsqltype="cf_sql_varchar">
            AND is_active = <cfqueryparam value="1" cfsqltype="cf_sql_integer">
        </cfquery>
        <cfif accessCheck.recordCount EQ 1>
            <cfquery datasource="#request.datasource#" name="roleCheck">
                SELECT r.role_name, r.role_id
                FROM AdminUserRoles ur
                JOIN AdminRoles r ON r.role_id = ur.role_id
                WHERE ur.user_id = <cfqueryparam value="#accessCheck.user_id#" cfsqltype="cf_sql_integer">
            </cfquery>

            <cfset var roles = []>
            <cfset var roleIDs = []>

            <cfloop query="roleCheck">
              <cfset arrayAppend(roles, roleCheck.role_name)>
              <cfset arrayAppend(roleIDs, roleCheck.role_id)>
            </cfloop>

            <cfif arrayLen(roles) EQ 0>
              <cfset result.message = "User not authorized - No access role assigned">
              <cfreturn result>
            </cfif>
        <cfelse>
            <cfset result.message = "User not authorized - Not found in access list">
            <cfreturn result>
        </cfif>



      <!--- Success --->
      <cfset result.success = true>
      <cfset result.user = {
        username    = GetUserInfo.sAMAccountName,
        displayName = GetUserInfo.displayName,
        email       = GetUserInfo.mail,
        department  = GetUserInfo.department,
        title       = GetUserInfo.title,
        phone       = GetUserInfo.telephoneNumber,
        authType    = "ldap",
        loginAt     = now(),
        roles       = roles,
        roleIDs     = roleIDs,
        isSuperAdmin = arrayFindNoCase(roles, "SUPER_ADMIN") GT 0
      }>

      <cfreturn result>

      <cfcatch type="any">
        <cflog
          file="ldap-debug"
          type="error"
          text="LDAP ERROR: #cfcatch.message# | #cfcatch.detail#"
        >
        <cfif cfcatch.message CONTAINS "error code 49">
          <cfif cfcatch.message CONTAINS "52e">
            <cfset result.message = "Invalid credentials. Please check your username or password and try again.">
          <cfelseif cfcatch.message CONTAINS "525">
            <cfset result.message = "User not found. Please check your username and try again.">
          <cfelseif cfcatch.message CONTAINS "530">
            <cfset result.message = "Not permitted to log on at this time. Please contact your IT admin.">
          <cfelseif cfcatch.message CONTAINS "532">
            <cfset result.message = "Password expired. Please change your password before attempting to log in again.">
          <cfelseif cfcatch.message CONTAINS "533">
            <cfset result.message = "Account disabled. Please contact your IT admin.">
          <cfelseif cfcatch.message CONTAINS "701">
            <cfset result.message = "Account expired. Please contact your IT admin.">
          <cfelseif cfcatch.message CONTAINS "773">
            <cfset result.message = "You must reset your password before logging in.">
          <cfelse>
            <cfset result.message = "Login failed (code 49). Please try again.">
          </cfif>
        <cfelse>
          <cfset result.message = "Authentication error. Please try again. #cfcatch.message# | #cfcatch.detail#">
        </cfif>
        <cfreturn result>
      </cfcatch>

    </cftry>

  </cffunction>

    <cffunction
        name="isLoggedIn"
        access="public"
        returntype="boolean"
        output="false"
        >
        <cfreturn structKeyExists(session, "user")>
    </cffunction>

    <cffunction name="hasRole" access="public" returntype="boolean" output="false">
      <cfargument name="role" type="string" required="true">

      <cfif structKeyExists(session, "user") AND session.user.isSuperAdmin>
        <cfreturn true>
      </cfif>

      <cfif NOT structKeyExists(session, "user")>
        <cfreturn false>
      </cfif>

      <cfreturn arrayFindNoCase(session.user.roles, arguments.role) GT 0>
    </cffunction>

    <cffunction name="hasAnyRole" access="public" returntype="boolean" output="false">
      <cfargument name="roles" type="array" required="true">

      <cfif structKeyExists(session, "user") AND session.user.isSuperAdmin>
        <cfreturn true>
      </cfif>

      <cfif NOT structKeyExists(session, "user")>
        <cfreturn false>
      </cfif>

      <cfloop array="#arguments.roles#" index="r">
        <cfif arrayFindNoCase(session.user.roles, r) GT 0>
          <cfreturn true>
        </cfif>
      </cfloop>

      <cfreturn false>
    </cffunction>

    <cffunction
        name="createSession"
        access="public"
        returntype="void"
        output="false"
        >
        <cfargument name="user" type="struct" required="true">

        <cfset session.user = duplicate(arguments.user)>
    </cffunction>

    <cffunction
        name="logout"
        access="public"
        returntype="void"
        output="false"
        >
        <!--- Clear user session data --->
        <cfif structKeyExists(session, "user")>
            <cfset structDelete(session, "user")>
        </cfif>

        <!--- Optional but recommended: rotate session ID --->
        <cfset sessionInvalidate()>
        </cffunction>

</cfcomponent>