<cfif NOT request.hasPermission("settings.api.manage")>
    <cflocation url="#request.webRoot#/admin/unauthorized.cfm" addtoken="false">
</cfif>

<cfif CGI.REQUEST_METHOD NEQ "POST" OR NOT structKeyExists(form, "tokenID") OR NOT isNumeric(form.tokenID)>
    <cflocation url="#request.webRoot#/admin/settings/uhco-api/tokens/index.cfm" addtoken="false">
</cfif>

<cfset tokenService  = createObject("component", "cfc.token_service").init()>
<cfset secretService = createObject("component", "cfc.secret_service").init()>

<!--- Cascade: revoke any secrets sharing the same AppName --->  
<cfset tokenRows = tokenService.getAllTokens()>
<cfset revokeAppName = "">
<cfloop array="#tokenRows#" index="t">
    <cfif val(t.TOKENID) EQ val(form.tokenID)>
        <cfset revokeAppName = t.APPNAME>
        <cfbreak>
    </cfif>
</cfloop>

<cfset tokenService.revokeToken(val(form.tokenID))>

<cfif len(trim(revokeAppName))>
    <cfset matchingSecrets = secretService.getSecretsByAppName(revokeAppName)>
    <cfloop array="#matchingSecrets#" index="s">
        <cfset secretService.revokeSecret(val(s.SECRETID))>
    </cfloop>
</cfif>

<cflocation url="#request.webRoot#/admin/settings/uhco-api/tokens/index.cfm" addtoken="false">
