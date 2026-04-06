<!--- ── Data Quality last run ── --->
<cfset dqLastRun  = {}>
<cfset dqDbOk     = true>
<cftry>
    <cfset dqDAO    = createObject("component", "dir.dao.dataQuality_DAO").init()>
    <cfset dqRuns   = dqDAO.getRecentRuns(1)>
    <cfset dqLastRun = arrayLen(dqRuns) ? dqRuns[1] : {}>
<cfcatch>
    <cfset dqDbOk = false>
</cfcatch>
</cftry>

<!--- ── UH Sync last run ── --->
<cfset uhSyncLastRun = {}>
<cfset uhSyncDbOk    = true>
<cftry>
    <cfset uhSyncDAO_dash  = createObject("component", "dir.dao.uhSync_DAO").init()>
    <cfset uhSyncLastRun   = uhSyncDAO_dash.getLatestRun()>
<cfcatch>
    <cfset uhSyncDbOk = false>
</cfcatch>
</cftry>

<cfset dqIssues    = structIsEmpty(dqLastRun) ? -1 : dqLastRun.TOTALISSUES>
<cfset dqBadgeCls  = dqIssues GT 0 ? "bg-danger" : (dqIssues EQ 0 ? "bg-success" : "bg-secondary")>
<cfset dqBadgeTxt  = dqIssues EQ -1 ? "Never run" : dqIssues & " issue(s)">
<cfset dqSubtitle  = structIsEmpty(dqLastRun) ? "No report has been run yet." : "Last run: " & dateTimeFormat(dqLastRun.RUNAT, "mmm d, yyyy HH:nn") & " UTC">

<!--- ── UH Sync badge values ── --->
<cfset uhSyncHasPending = false>
<cfset uhSyncBadgeCls   = "bg-secondary">
<cfset uhSyncBadgeTxt   = "Never run">
<cfset uhSyncSubtitle   = "No sync has been run yet.">
<cfset uhSyncBorderCls  = "">
<cfif NOT structIsEmpty(uhSyncLastRun)>
    <cfset uhSyncTotalPending = (uhSyncLastRun.TOTALDIFFS ?: 0) + (uhSyncLastRun.TOTALGONE ?: 0) + (uhSyncLastRun.TOTALNEW ?: 0)>
    <cfset uhSyncHasPending   = (uhSyncTotalPending GT 0)>
    <cfset uhSyncBadgeCls     = uhSyncHasPending ? "bg-warning text-dark" : "bg-success">
    <cfset uhSyncBadgeTxt     = uhSyncHasPending ? uhSyncTotalPending & " pending" : "Up to date">
    <cfset uhSyncSubtitle     = "Last run: " & dateTimeFormat(uhSyncLastRun.RUNAT, "mmm d, yyyy HH:nn") & " UTC — "
        & (uhSyncLastRun.TOTALDIFFS ?: 0) & " diff(s), "
        & (uhSyncLastRun.TOTALGONE  ?: 0) & " gone, "
        & (uhSyncLastRun.TOTALNEW   ?: 0) & " new">
    <cfset uhSyncBorderCls    = uhSyncHasPending ? "border-warning" : "border-success">
</cfif>

<cfset content = "
<h1 class='mb-4'>Directory Admin Dashboard</h1>

<div class='row g-4'>
    <div class='col-md-4'>
        <div class='card shadow-sm'>
            <div class='card-body'>
                <h5 class='card-title'>Users</h5>
                <p class='card-text'>Manage UHCO faculty, staff, residents, alumni, and students.</p>
                <a href='/dir/admin/users/index.cfm' class='btn btn-primary'>Manage Users</a>
            </div>
        </div>
    </div>

    <div class='col-md-4'>
        <div class='card shadow-sm'>
            <div class='card-body'>
                <h5 class='card-title'>Flags</h5>
                <p class='card-text'>Assign Display Flags such as Faculty, Staff, Resident, Alumni.</p>
                <a href='/dir/admin/flags/index.cfm' class='btn btn-primary'>Manage Flags</a>
            </div>
        </div>
    </div>

    <div class='col-md-4'>
        <div class='card shadow-sm'>
            <div class='card-body'>
                <h5 class='card-title'>Organizations</h5>
                <p class='card-text'>Manage departments, divisions, and faculty groups.</p>
                <a href='/dir/admin/orgs/index.cfm' class='btn btn-primary'>Manage Orgs</a>
            </div>
        </div>
    </div>
</div>
<div class='row g-4 mt-1'>
    <div class='col-md-4'>
        <div class='card shadow-sm'>
            <div class='card-body'>
                <h5 class='card-title'>External IDs</h5>
                <p class='card-text'>Manage External IDs for users.</p>
                <a href='/dir/admin/external/index.cfm' class='btn btn-primary'>Manage IDs</a>
            </div>
        </div>
    </div>
</div>

<div class='row g-4 mt-2'>
    <div class='col-12'>
        <div class='card shadow-sm " & (dqIssues GT 0 ? "border-danger" : (dqIssues EQ 0 ? "border-success" : "")) & "'>
            <div class='card-body d-flex flex-wrap align-items-center justify-content-between gap-3'>
                <div>
                    <h5 class='card-title mb-1'>
                        <i class='bi bi-clipboard-data me-2'></i>Data Quality Report
                    </h5>
                    <small class='text-muted'>#dqSubtitle#</small>
                </div>
                <div class='d-flex align-items-center gap-2'>
                    <span class='badge #dqBadgeCls# fs-6'>#dqBadgeTxt#</span>
                    <a href='/dir/admin/reporting/data_quality_report.cfm' class='btn btn-sm btn-primary'>View Report</a>
                    <a href='/dir/admin/reporting/run_data_quality_report.cfm' class='btn btn-sm btn-outline-secondary'>Run Now</a>
                </div>
            </div>
        </div>
    </div>
    <div class='col-12'>
        <div class='card shadow-sm #uhSyncBorderCls#'>
            <div class='card-body d-flex flex-wrap align-items-center justify-content-between gap-3'>
                <div>
                    <h5 class='card-title mb-1'>
                        <i class='bi bi-arrow-left-right me-2'></i>UH API Sync Report
                    </h5>
                    <small class='text-muted'>#uhSyncSubtitle#</small>
                </div>
                <div class='d-flex align-items-center gap-2'>
                    <span class='badge #uhSyncBadgeCls# fs-6'>#uhSyncBadgeTxt#</span>
                    <a href='/dir/admin/reporting/uh_sync_report.cfm' class='btn btn-sm btn-primary'>View Report</a>
                    <a href='/dir/admin/reporting/run_uh_sync_report.cfm' class='btn btn-sm btn-outline-secondary'>Run Now</a>
                </div>
            </div>
        </div>
    </div>
</div>
" />

<cfinclude template="/dir/admin/layout.cfm">