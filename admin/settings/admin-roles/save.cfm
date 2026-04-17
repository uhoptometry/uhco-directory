<!---
    Admin Roles — POST handler for create, update, delete.
    SUPER_ADMIN only.
--->

<cfif NOT request.hasRole("SUPER_ADMIN")>
    <cflocation url="#request.webRoot#/admin/unauthorized.cfm" addtoken="false">
</cfif>

<cfset authSvc     = createObject("component", "cfc.adminAuth_service").init()>
<cfset action      = structKeyExists(form, "action") ? trim(form.action) : "">
<cfset redirectURL = "/admin/settings/admin-roles/">

<cftry>
    <cfswitch expression="#action#">

        <cfcase value="createRole">
            <cfset rn     = structKeyExists(form, "roleName") ? trim(form.roleName) : "">
            <cfset result = authSvc.createRole(rn)>
            <cfif result.success>
                <cfset redirectURL &= "?msg=" & urlEncodedFormat(result.message)>
            <cfelse>
                <cfset redirectURL &= "?err=" & urlEncodedFormat(result.message)>
            </cfif>
        </cfcase>

        <cfcase value="updateRole">
            <cfset rid    = structKeyExists(form, "roleID") AND isNumeric(form.roleID) ? val(form.roleID) : 0>
            <cfset rn     = structKeyExists(form, "roleName") ? trim(form.roleName) : "">
            <cfset result = authSvc.updateRole(rid, rn)>
            <cfif result.success>
                <cfset redirectURL &= "?msg=" & urlEncodedFormat(result.message)>
            <cfelse>
                <cfset redirectURL &= "?err=" & urlEncodedFormat(result.message)>
            </cfif>
        </cfcase>

        <cfcase value="deleteRole">
            <cfset rid    = structKeyExists(form, "roleID") AND isNumeric(form.roleID) ? val(form.roleID) : 0>
            <cfset result = authSvc.deleteRole(rid)>
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
