<cfif !structKeyExists(form, "userID") OR !isNumeric(form.userID)>
    <cflocation url="#request.webRoot#/admin/users/index.cfm" addtoken="false">
</cfif>

<cfif NOT request.hasPermission("users.delete")>
    <cflocation url="#request.webRoot#/admin/users/index.cfm" addtoken="false">
</cfif>

<cfset directoryService = createObject("component", "cfc.directory_service").init()>
<cfset usersService = createObject("component", "cfc.users_service").init()>
<cfset appConfigService = createObject("component", "cfc.appConfig_service").init()>
<cfset canViewTestUsers = application.authService.hasRole("SUPER_ADMIN")>
<cfset testModeEnabledValue = trim(appConfigService.getValue("test_mode.enabled", "0"))>
<cfset testModeEnabled = usersService.isTestModeEnabled() OR (listFindNoCase("1,true,yes,on", testModeEnabledValue) GT 0)>
<cfset isSuperAdminImpersonation = structKeyExists(request, "isImpersonating") AND request.isImpersonating() AND structKeyExists(request, "isActualSuperAdmin") AND request.isActualSuperAdmin()>
<cfset showTestUsersForAdmin = canViewTestUsers OR testModeEnabled OR isSuperAdminImpersonation>
<cfset hideTestUsersForAdmin = NOT showTestUsersForAdmin>
<cfset profile = directoryService.getFullProfile(form.userID)>
<cfset isTestUser = false>
<cfloop from="1" to="#arrayLen(profile.flags ?: [])#" index="flagIndex">
    <cfif compareNoCase(trim(profile.flags[flagIndex].FLAGNAME ?: ""), "TEST_USER") EQ 0>
        <cfset isTestUser = true>
        <cfbreak>
    </cfif>
</cfloop>
<cfif hideTestUsersForAdmin AND isTestUser>
    <cflocation url="#request.webRoot#/admin/unauthorized.cfm" addtoken="false">
</cfif>

<!--- Perform the deletion --->
<cfset result = usersService.deleteUser( form.userID )>

<cfif result.success>
    <cfset content = "
    <div class='alert alert-success alert-dismissible fade show' role='alert'>
        <h4 class='alert-heading'>✓ User Deleted</h4>
        <p>#result.message#</p>
        <button type='button' class='btn-close' data-bs-dismiss='alert' aria-label='Close'></button>
    </div>

    <p><a href='/admin/users/index.cfm' class='btn btn-primary'>Back to Users</a></p>
    " />
<cfelse>
    <cfset content = "
    <div class='alert alert-danger alert-dismissible fade show' role='alert'>
        <h4 class='alert-heading'>✗ Error Deleting User</h4>
        <p>#result.message#</p>
        <button type='button' class='btn-close' data-bs-dismiss='alert' aria-label='Close'></button>
    </div>

    <p><a href='/admin/users/index.cfm' class='btn btn-secondary'>Back to Users</a></p>
    " />
</cfif>

<cfinclude template="/admin/layout.cfm">
