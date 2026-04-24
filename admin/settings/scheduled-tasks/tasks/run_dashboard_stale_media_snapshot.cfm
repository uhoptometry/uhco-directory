<cfsetting showdebugoutput="false" requesttimeout="180">
<!---
    run_dashboard_stale_media_snapshot.cfm
    Computes stale-media totals for dashboard cards and stores the latest
    run snapshot in AppConfig.
--->

<cfset triggeredBy = "manual">
<cfif structKeyExists(url, "triggeredBy") AND len(trim(url.triggeredBy))>
    <cfset triggeredBy = trim(url.triggeredBy)>
<cfelseif structKeyExists(form, "triggeredBy") AND len(trim(form.triggeredBy))>
    <cfset triggeredBy = trim(form.triggeredBy)>
</cfif>

<cfinclude template="/admin/settings/scheduled-tasks/tasks/_scheduled_task_auth.cfm">

<cfif triggeredBy NEQ "scheduled" AND NOT request.hasPermission("settings.scheduled_tasks.manage")>
    <cflocation url="#request.webRoot#/admin/unauthorized.cfm" addtoken="false">
</cfif>

<cfset returnJson = structKeyExists(url, "format") AND lCase(trim(url.format ?: "")) EQ "json">
<cfset variantsDAO = createObject("component", "dao.UserImageVariantDAO").init()>
<cfset appConfigService = createObject("component", "cfc.appConfig_service").init()>

<cfset success = false>
<cfset errorMsg = "">
<cfset total = 0>
<cfset staleMonths = val(appConfigService.getValue("dashboard.stale_months", "6"))>
<cfif staleMonths LT 1><cfset staleMonths = 6></cfif>
<cfif staleMonths GT 60><cfset staleMonths = 60></cfif>

<cftry>
    <cfset pageResult = variantsDAO.getStaleMediaUsersForDashboardPage(pageSize=1, pageNumber=1, staleMonths=staleMonths)>
    <cfset total = val(pageResult.totalCount ?: 0)>

    <cfset snapshot = {
        runAt = dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
        triggeredBy = triggeredBy,
        staleMonths = staleMonths,
        total = total
    }>
    <cfset appConfigService.setValue("scheduled_tasks.dashboard_stale_media.last_run", serializeJSON(snapshot))>
    <cfset success = true>
<cfcatch type="any">
    <cfset errorMsg = cfcatch.message>
    <cfif len(trim(cfcatch.detail ?: ""))>
        <cfset errorMsg &= " -- " & cfcatch.detail>
    </cfif>
</cfcatch>
</cftry>

<cfif returnJson>
    <cfcontent type="application/json; charset=utf-8">
    <cfoutput>#serializeJSON({
        success = success,
        triggeredBy = triggeredBy,
        staleMonths = staleMonths,
        total = total,
        error = errorMsg
    })#</cfoutput>
    <cfabort>
</cfif>

<cfif success>
    <cflocation url="#request.webRoot#/admin/settings/scheduled-tasks/?msg=ran&taskKey=UHCO_DashboardStaleMedia&total=#urlEncodedFormat(total)#" addtoken="false">
<cfelse>
    <cflocation url="#request.webRoot#/admin/settings/scheduled-tasks/?msg=error&taskKey=UHCO_DashboardStaleMedia&err=#urlEncodedFormat(errorMsg)#" addtoken="false">
</cfif>
