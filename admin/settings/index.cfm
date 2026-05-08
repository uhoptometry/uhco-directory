<!---
    Settings Hub
    Central dashboard with links to all settings sub-sections.
--->

<!--- ── Auth guard ── --->
<cfif NOT (
    request.hasPermission("settings.view")
    OR request.hasAnyPermission([
        "settings.app_config.manage",
        "settings.media_config.manage",
        "settings.api.manage",
        "settings.admin_users.manage",
        "settings.admin_roles.manage",
        "settings.admin_permissions.manage",
        "settings.user_review.manage",
        "users.approve_user_review",
        "settings.import.manage",
        "settings.bulk_exclusions.manage",
        "settings.migrations.manage",
        "settings.rosters.manage",
        "settings.uh_sync.view",
        "settings.query_builder.use",
        "settings.scheduled_tasks.manage",
        "settings.workflows.manage"
    ])
)>
    <cflocation url="#request.webRoot#/admin/unauthorized.cfm" addtoken="false">
</cfif>

<cfinclude template="/admin/settings/section-status-config.cfm">

<cfset content = "">
<cfsavecontent variable="content">
<cfoutput>

<div class="settings-page settings-hub">
<h1 class="mb-1"><i class="bi bi-gear-fill me-2"></i>Settings</h1>
<p class="text-muted">System configuration and administration tools.</p>

<div class="row g-4 mt-3">

    <!--- Application Settings --->
    <cfif request.hasPermission("settings.admin_permissions.manage")>
        <div class="col-md-6 col-lg-4">
            <a href="/admin/settings/app-config/" class="text-decoration-none">
                <div class="card h-100 border-0 shadow-sm settings-hub-card">
                    <div class="card-body text-center py-4">
                        <i class="bi bi-sliders display-4 mb-3 settings-hub-icon"></i>
                        <h5 class="card-title text-dark">Application Settings<cfif len(getSettingsSectionStatus("app-config"))> <span class="badge settings-status-badge settings-status-badge--#lCase(getSettingsSectionStatus("app-config"))#">#getSettingsSectionStatus("app-config")#</span></cfif></h5>
                        <p class="card-text text-muted small">Shared key-value configuration such as published media URLs</p>
                    </div>
                </div>
            </a>
        </div>
        <!---- Admin Permissions --->
        <div class="col-md-6 col-lg-4">
            <a href="/admin/settings/admin-permissions/" class="text-decoration-none">
                <div class="card h-100 border-0 shadow-sm settings-hub-card">
                    <div class="card-body text-center py-4">
                        <i class="bi bi-sliders display-4 mb-3 settings-hub-icon"></i>
                        <h5 class="card-title text-dark">Admin Permissions<cfif len(getSettingsSectionStatus("admin-permissions"))> <span class="badge settings-status-badge settings-status-badge--#lCase(getSettingsSectionStatus("admin-permissions"))#">#getSettingsSectionStatus("admin-permissions")#</span></cfif></h5>
                        <p class="card-text text-muted small">Create, edit, and retire permission definitions</p>
                    </div>
                </div>
            </a>
        </div>
    </cfif>

    <!--- Admin Users & Roles --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/admin-users/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm settings-hub-card">
                <div class="card-body text-center py-4">
                    <i class="bi bi-shield-lock display-4 mb-3 settings-hub-icon"></i>
                    <h5 class="card-title text-dark">Admin Users &amp; Roles<cfif len(getSettingsSectionStatus("admin-users"))> <span class="badge settings-status-badge settings-status-badge--#lCase(getSettingsSectionStatus("admin-users"))#">#getSettingsSectionStatus("admin-users")#</span></cfif></h5>
                    <p class="card-text text-muted small">Manage admin accounts and role assignments</p>
                </div>
            </div>
        </a>
    </div>

    <cfif request.hasAnyPermission(["settings.user_review.manage", "users.approve_user_review"] )>
        <div class="col-md-6 col-lg-4">
            <a href="/admin/settings/user-review/" class="text-decoration-none">
                <div class="card h-100 border-0 shadow-sm settings-hub-card">
                    <div class="card-body text-center py-4">
                        <i class="bi bi-person-lines-fill display-4 mb-3 settings-hub-icon"></i>
                        <h5 class="card-title text-dark">User Review<cfif len(getSettingsSectionStatus("user-review"))> <span class="badge settings-status-badge settings-status-badge--#lCase(getSettingsSectionStatus("user-review"))#">#getSettingsSectionStatus("user-review")#</span></cfif></h5>
                        <p class="card-text text-muted small">Configure self-service profile review and process submissions</p>
                    </div>
                </div>
            </a>
        </div>
    </cfif>

    <!--- User Media Config --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/media-config/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm settings-hub-card">
                <div class="card-body text-center py-4">
                    <i class="bi bi-image display-4 mb-3 settings-hub-icon"></i>
                    <h5 class="card-title text-dark">User Media Config<cfif len(getSettingsSectionStatus("media-config"))> <span class="badge settings-status-badge settings-status-badge--#lCase(getSettingsSectionStatus("media-config"))#">#getSettingsSectionStatus("media-config")#</span></cfif></h5>
                    <p class="card-text text-muted small">Filename patterns and image variant types</p>
                </div>
            </div>
        </a>
    </div>

    <!--- UHCO API --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/uhco-api/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm settings-hub-card">
                <div class="card-body text-center py-4">
                    <i class="bi bi-braces display-4 mb-3 settings-hub-icon"></i>
                    <h5 class="card-title text-dark">UHCO API<cfif len(getSettingsSectionStatus("uhco-api"))> <span class="badge settings-status-badge settings-status-badge--#lCase(getSettingsSectionStatus("uhco-api"))#">#getSettingsSectionStatus("uhco-api")#</span></cfif></h5>
                    <p class="card-text text-muted small">Manage API tokens and secrets for external integrations</p>
                </div>
            </div>
        </a>
    </div>

    <!--- Migrations --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/migrations/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm settings-hub-card">
                <div class="card-body text-center py-4">
                    <i class="bi bi-mortarboard display-4 mb-3 settings-hub-icon"></i>
                    <h5 class="card-title text-dark">Migrations<cfif len(getSettingsSectionStatus("migrations"))> <span class="badge settings-status-badge settings-status-badge--#lCase(getSettingsSectionStatus("migrations"))#">#getSettingsSectionStatus("migrations")#</span></cfif></h5>
                    <p class="card-text text-muted small">Graduation migration and future migration tools</p>
                </div>
            </div>
        </a>
    </div>

    <cfif request.hasPermission("settings.rosters.manage")>
        <div class="col-md-6 col-lg-4">
            <a href="/admin/settings/rosters/" class="text-decoration-none">
                <div class="card h-100 border-0 shadow-sm settings-hub-card">
                    <div class="card-body text-center py-4">
                        <i class="bi bi-card-image display-4 mb-3 settings-hub-icon"></i>
                        <h5 class="card-title text-dark">Rosters<cfif len(getSettingsSectionStatus("rosters"))> <span class="badge settings-status-badge settings-status-badge--#lCase(getSettingsSectionStatus("rosters"))#">#getSettingsSectionStatus("rosters")#</span></cfif></h5>
                        <p class="card-text text-muted small">Generate printable class roster PDFs by grad year and program</p>
                    </div>
                </div>
            </a>
        </div>
    </cfif>

    <!--- Scheduled Tasks --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/scheduled-tasks/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm settings-hub-card">
                <div class="card-body text-center py-4">
                    <i class="bi bi-clock-history display-4 mb-3 settings-hub-icon"></i>
                    <h5 class="card-title text-dark">Scheduled Tasks<cfif len(getSettingsSectionStatus("scheduled-tasks"))> <span class="badge settings-status-badge settings-status-badge--#lCase(getSettingsSectionStatus("scheduled-tasks"))#">#getSettingsSectionStatus("scheduled-tasks")#</span></cfif></h5>
                    <p class="card-text text-muted small">Enable, disable, and configure automated tasks</p>
                </div>
            </div>
        </a>
    </div>

    <!--- Import Data --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/import/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm settings-hub-card">
                <div class="card-body text-center py-4">
                    <i class="bi bi-upload display-4 mb-3 settings-hub-icon"></i>
                    <h5 class="card-title text-dark">Import Data<cfif len(getSettingsSectionStatus("import"))> <span class="badge settings-status-badge settings-status-badge--#lCase(getSettingsSectionStatus("import"))#">#getSettingsSectionStatus("import")#</span></cfif></h5>
                    <p class="card-text text-muted small">Import users, flags, organizations via CSV or Excel</p>
                </div>
            </div>
        </a>
    </div>

    <!--- Bulk Exclusions --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/bulk-exclusions/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm settings-hub-card">
                <div class="card-body text-center py-4">
                    <i class="bi bi-funnel display-4 mb-3 settings-hub-icon"></i>
                    <h5 class="card-title text-dark">Bulk Exclusions<cfif len(getSettingsSectionStatus("bulk-exclusions"))> <span class="badge settings-status-badge settings-status-badge--#lCase(getSettingsSectionStatus("bulk-exclusions"))#">#getSettingsSectionStatus("bulk-exclusions")#</span></cfif></h5>
                    <p class="card-text text-muted small">Data quality exclusion rules by user type</p>
                </div>
            </div>
        </a>
    </div>

    

    <!--- UH Sync --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/uh-sync/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm settings-hub-card">
                <div class="card-body text-center py-4">
                    <i class="bi bi-arrow-left-right display-4 mb-3 settings-hub-icon"></i>
                    <h5 class="card-title text-dark">UH Sync<cfif len(getSettingsSectionStatus("uh-sync"))> <span class="badge settings-status-badge settings-status-badge--#lCase(getSettingsSectionStatus("uh-sync"))#">#getSettingsSectionStatus("uh-sync")#</span></cfif></h5>
                    <p class="card-text text-muted small">Field-level diffs and membership changes vs UH API</p>
                </div>
            </div>
        </a>
    </div>

    <!--- Query Builder --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/query-builder/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm settings-hub-card">
                <div class="card-body text-center py-4">
                    <i class="bi bi-database display-4 mb-3 settings-hub-icon"></i>
                    <h5 class="card-title text-dark">Query Builder<cfif len(getSettingsSectionStatus("query-builder"))> <span class="badge settings-status-badge settings-status-badge--#lCase(getSettingsSectionStatus("query-builder"))#">#getSettingsSectionStatus("query-builder")#</span></cfif></h5>
                    <p class="card-text text-muted small">Visual query builder with export (CSV)</p>
                </div>
            </div>
        </a>
    </div>

    <!--- Workflows 
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/workflows/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm settings-hub-card">
                <div class="card-body text-center py-4">
                    <i class="bi bi-diagram-3 display-4 mb-3 settings-hub-icon"></i>
                    <h5 class="card-title text-dark">Workflows <span class="badge settings-status-badge settings-status-badge--soon">Coming Soon</span></h5>
                    <p class="card-text text-muted small">Automated workflows and processing pipelines</p>
                </div>
            </div>
        </a>
    </div>--->

</div>

</div>

</cfoutput>
</cfsavecontent>

<cfinclude template="/admin/layout.cfm">
