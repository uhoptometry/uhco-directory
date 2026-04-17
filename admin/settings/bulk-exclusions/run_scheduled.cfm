<cfsetting requesttimeout="900">
<!---
    Bulk Exclusions — Scheduled task endpoint.
    Runs all 6 exclusion types and returns JSON.
--->

<cfset svc    = createObject("component", "cfc.bulkExclusions_service").init()>
<cfset result = { success = false, totalRows = 0, details = [], error = "" }>

<cftry>
    <cfset runResult = svc.runAll("scheduled")>
    <cfset result.success   = runResult.success>
    <cfset result.totalRows = runResult.totalRows>
    <cfloop array="#runResult.results#" index="r">
        <cfset arrayAppend(result.details, { type = r.key, rows = r.rows, success = r.success, message = r.message })>
    </cfloop>

<cfcatch type="any">
    <cfset result.error = cfcatch.message>
</cfcatch>
</cftry>

<cfcontent type="application/json" reset="true"><cfoutput>#serializeJSON(result)#</cfoutput>
