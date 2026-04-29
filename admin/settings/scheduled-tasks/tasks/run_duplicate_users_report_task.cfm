<cfsetting showdebugoutput="false">
<!---
    Scheduled-task wrapper for duplicate-users report.
--->
<cfset triggeredBy = "manual">
<cfif structKeyExists(url, "triggeredBy") AND len(trim(url.triggeredBy ?: ""))>
    <cfset triggeredBy = trim(url.triggeredBy)>
<cfelseif structKeyExists(form, "triggeredBy") AND len(trim(form.triggeredBy ?: ""))>
    <cfset triggeredBy = trim(form.triggeredBy)>
</cfif>

<cfinclude template="/admin/settings/scheduled-tasks/tasks/_scheduled_task_auth.cfm">

<cfif triggeredBy NEQ "scheduled" AND NOT request.hasPermission("settings.scheduled_tasks.manage")>
    <cflocation url="#request.webRoot#/admin/unauthorized.cfm" addtoken="false">
</cfif>

<cfinclude template="/admin/reporting/run_duplicate_users_report.cfm">
