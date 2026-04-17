<!---
    Admin Users — POST handler for add, toggle active, assign/revoke role.
    SUPER_ADMIN only.
--->

<cfif NOT request.hasRole("SUPER_ADMIN")>
    <cflocation url="#request.webRoot#/admin/unauthorized.cfm" addtoken="false">
</cfif>

<cfset authSvc = createObject("component", "cfc.adminAuth_service").init()>
<cfset action  = structKeyExists(form, "action") ? trim(form.action) : "">
<cfset redirectURL = "/admin/settings/admin-users/">

<cftry>
    <cfswitch expression="#action#">

        <cfcase value="addUser">
            <cfset cn     = structKeyExists(form, "cougarnet") ? trim(form.cougarnet) : "">
            <cfset result = authSvc.addUser(cn)>
            <cfif result.success>
                <cfset redirectURL &= "?msg=" & urlEncodedFormat(result.message)>
            <cfelse>
                <cfset redirectURL &= "?err=" & urlEncodedFormat(result.message)>
            </cfif>
        </cfcase>

        <cfcase value="toggleActive">
            <cfset uid    = structKeyExists(form, "userID") AND isNumeric(form.userID) ? val(form.userID) : 0>
            <cfset result = authSvc.toggleUserActive(uid)>
            <cfif result.success>
                <cfset redirectURL &= "?msg=" & urlEncodedFormat(result.message)>
            <cfelse>
                <cfset redirectURL &= "?err=" & urlEncodedFormat(result.message)>
            </cfif>
        </cfcase>

        <cfcase value="assignRole">
            <cfset uid = structKeyExists(form, "userID") AND isNumeric(form.userID) ? val(form.userID) : 0>
            <cfset rid = structKeyExists(form, "roleID") AND isNumeric(form.roleID) ? val(form.roleID) : 0>
            <cfset result = authSvc.assignRole(uid, rid)>
            <cfif result.success>
                <cfset redirectURL &= "?msg=" & urlEncodedFormat(result.message)>
            <cfelse>
                <cfset redirectURL &= "?err=" & urlEncodedFormat(result.message)>
            </cfif>
        </cfcase>

        <cfcase value="revokeRole">
            <cfset uid = structKeyExists(form, "userID") AND isNumeric(form.userID) ? val(form.userID) : 0>
            <cfset rid = structKeyExists(form, "roleID") AND isNumeric(form.roleID) ? val(form.roleID) : 0>
            <cfset result = authSvc.revokeRole(uid, rid)>
            <cfif result.success>
                <cfset redirectURL &= "?msg=" & urlEncodedFormat(result.message)>
            <cfelse>
                <cfset redirectURL &= "?err=" & urlEncodedFormat(result.message)>
            </cfif>
        </cfcase>

        <cfdefaultcase>
            <cfset redirectURL &= "?err=" & urlEncodedFormat("Unknown action.")>
        </cfdefaultcase>

    </cfswitch>

<cfcatch type="any">
    <cfset redirectURL &= "?err=" & urlEncodedFormat(cfcatch.message)>
</cfcatch>
</cftry>

<cflocation url="#redirectURL#" addtoken="false">
