<!---
    Shared scheduled-task auth guard.
    Enforces token validation only for scheduler-triggered execution.
--->

<cfif lCase(trim(triggeredBy ?: "manual")) EQ "scheduled">
    <cfset _taskAppConfig = createObject("component", "cfc.appConfig_service").init()>
    <cfset _expectedToken = trim(_taskAppConfig.getValue("scheduled_tasks.shared_secret", ""))>
    <cfset _providedToken = trim((url.token ?: form.token ?: ""))>
    <cfset _wantsJson = structKeyExists(url, "format") AND lCase(trim(url.format ?: "")) EQ "json">

    <cfif NOT len(_expectedToken) OR _providedToken NEQ _expectedToken>
        <cfheader statuscode="403">
        <cfif _wantsJson>
            <cfcontent type="application/json; charset=utf-8" reset="true"><cfoutput>#serializeJSON({ success=false, error="Invalid scheduled task token." })#</cfoutput>
        <cfelse>
            <cfcontent type="text/plain; charset=utf-8" reset="true">Forbidden
        </cfif>
        <cfabort>
    </cfif>
</cfif>