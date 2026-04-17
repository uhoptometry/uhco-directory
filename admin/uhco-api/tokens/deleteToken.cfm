<cfif CGI.REQUEST_METHOD NEQ "POST" OR NOT structKeyExists(form, "tokenID") OR NOT isNumeric(form.tokenID)>
    <cflocation url="#request.webRoot#/admin/tokens/index.cfm" addtoken="false">
</cfif>

<cfset tokenService = createObject("component", .cfc.token_service").init()>
<cfset tokenService.deleteToken(val(form.tokenID))>
<cflocation url="#request.webRoot#/admin/tokens/index.cfm" addtoken="false">
