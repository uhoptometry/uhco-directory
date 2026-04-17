<cfset externalService = createObject("component", "cfc.externalID_service").init()>

<cfif !structKeyExists(form, "SystemID") OR !isNumeric(form.SystemID)>
    <cflocation url="#request.webRoot#/admin/external/index.cfm" addtoken="false">
</cfif>

<cfset result = externalService.deleteSystem(val(form.SystemID))>

<cfif result.success>
    <cflocation url="#request.webRoot#/admin/external/index.cfm" addtoken="false">
<cfelse>
    <cflocation url="#request.webRoot#/admin/external/index.cfm?error=#urlEncodedFormat(result.message)#" addtoken="false">
</cfif>
