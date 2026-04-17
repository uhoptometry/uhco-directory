<!---
    Settings Hub — SUPER_ADMIN only
    Central dashboard with links to all settings sub-sections.
--->

<!--- ── Auth guard ── --->
<cfif NOT request.hasRole("SUPER_ADMIN")>
    <cflocation url="#request.webRoot#/admin/unauthorized.cfm" addtoken="false">
</cfif>

<cfset content = "">
<cfsavecontent variable="content">
<cfoutput>

<h1 class="mb-1"><i class="bi bi-gear-fill me-2"></i>Settings</h1>
<p class="text-muted">System configuration and administration tools. Super Admin access only.</p>

<div class="row g-4 mt-3">

    <!--- Admin Users & Roles --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/admin-users/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm">
                <div class="card-body text-center py-4">
                    <i class="bi bi-shield-lock display-4 mb-3"></i>
                    <h5 class="card-title text-dark">Admin Users &amp; Roles</h5>
                    <p class="card-text text-muted small">Manage admin accounts and role assignments</p>
                </div>
            </div>
        </a>
    </div>

    <!--- User Media Config --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/media-config/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm">
                <div class="card-body text-center py-4">
                    <i class="bi bi-image display-4 mb-3"></i>
                    <h5 class="card-title text-dark">User Media Config</h5>
                    <p class="card-text text-muted small">Filename patterns and image variant types</p>
                </div>
            </div>
        </a>
    </div>

    <!--- Scheduled Tasks --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/scheduled-tasks/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm">
                <div class="card-body text-center py-4">
                    <i class="bi bi-clock-history display-4 mb-3"></i>
                    <h5 class="card-title text-dark">Scheduled Tasks <span class="badge bg-warning text-dark">Alpha</span></h5>
                    <p class="card-text text-muted small">Enable, disable, and configure automated tasks</p>
                </div>
            </div>
        </a>
    </div>

    <!--- Migrations --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/migrations/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm">
                <div class="card-body text-center py-4">
                    <i class="bi bi-mortarboard display-4 mb-3"></i>
                    <h5 class="card-title text-dark">Migrations <span class="badge bg-warning text-dark">Alpha</span></h5>
                    <p class="card-text text-muted small">Graduation migration and future migration tools</p>
                </div>
            </div>
        </a>
    </div>

    <!--- Bulk Exclusions --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/bulk-exclusions/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm">
                <div class="card-body text-center py-4">
                    <i class="bi bi-funnel display-4 mb-3"></i>
                    <h5 class="card-title text-dark">Bulk Exclusions <span class="badge bg-warning text-dark">Alpha</span></h5>
                    <p class="card-text text-muted small">Data quality exclusion rules by user type</p>
                </div>
            </div>
        </a>
    </div>

    <!--- UH Sync --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/uh-sync/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm">
                <div class="card-body text-center py-4">
                    <i class="bi bi-arrow-left-right display-4 mb-3"></i>
                    <h5 class="card-title text-dark">UH Sync <span class="badge bg-warning text-dark">Alpha</span></h5>
                    <p class="card-text text-muted small">Field-level diffs and membership changes vs UH API</p>
                </div>
            </div>
        </a>
    </div>

    <!--- Query Builder --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/query-builder/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm">
                <div class="card-body text-center py-4">
                    <i class="bi bi-database display-4 mb-3"></i>
                    <h5 class="card-title text-dark">Query Builder <span class="badge bg-warning text-dark">Alpha</span></h5>
                    <p class="card-text text-muted small">Visual query builder with export (CSV)</p>
                </div>
            </div>
        </a>
    </div>

    <!--- Import Data --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/import/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm">
                <div class="card-body text-center py-4">
                    <i class="bi bi-upload display-4 mb-3"></i>
                    <h5 class="card-title text-dark">Import Data <span class="badge bg-warning text-dark">Alpha</span></h5>
                    <p class="card-text text-muted small">Import users, flags, organizations via CSV or Excel</p>
                </div>
            </div>
        </a>
    </div>

    <!--- UHCO API --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/uhco-api/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm">
                <div class="card-body text-center py-4">
                    <i class="bi bi-braces display-4 mb-3"></i>
                    <h5 class="card-title text-dark">UHCO API</h5>
                    <p class="card-text text-muted small">Manage API tokens and secrets for external integrations</p>
                </div>
            </div>
        </a>
    </div>

    <!--- Workflows --->
    <div class="col-md-6 col-lg-4">
        <a href="/admin/settings/workflows/" class="text-decoration-none">
            <div class="card h-100 border-0 shadow-sm">
                <div class="card-body text-center py-4">
                    <i class="bi bi-diagram-3 display-4 mb-3"></i>
                    <h5 class="card-title text-dark">Workflows <span class="badge bg-warning text-dark">Alpha</span></h5>
                    <p class="card-text text-muted small">Automated workflows and processing pipelines</p>
                </div>
            </div>
        </a>
    </div>

</div>

</cfoutput>
</cfsavecontent>

<cfinclude template="/admin/layout.cfm">
