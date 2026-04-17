<!---
    Admin Users — list, add, toggle active, manage role assignments.
    SUPER_ADMIN only.
--->

<!--- ── Auth guard ── --->
<cfif NOT request.hasRole("SUPER_ADMIN")>
    <cflocation url="#request.webRoot#/admin/unauthorized.cfm" addtoken="false">
</cfif>

<!--- ── Load service & data ── --->
<cfset authSvc   = createObject("component", "cfc.adminAuth_service").init()>
<cfset users     = authSvc.getAllUsers()>
<cfset allRoles  = authSvc.getAllRoles()>
<cfset msgParam  = structKeyExists(url, "msg") ? url.msg : "">
<cfset errParam  = structKeyExists(url, "err") ? url.err : "">

<cfset content = "">
<cfsavecontent variable="content">
<cfoutput>

<nav aria-label="breadcrumb">
    <ol class="breadcrumb">
        <li class="breadcrumb-item"><a href="/admin/settings/">Settings</a></li>
        <li class="breadcrumb-item active">Admin Users</li>
    </ol>
</nav>

<h1 class="mb-1"><i class="bi bi-shield-lock me-2"></i>Admin Users &amp; Roles</h1>
<p class="text-muted">Manage who can access the admin panel and their role assignments.</p>

<!--- Status messages --->
<cfif len(msgParam)>
    <div class="alert alert-success alert-dismissible fade show mt-3">
        #encodeForHTML(msgParam)#
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
</cfif>
<cfif len(errParam)>
    <div class="alert alert-danger alert-dismissible fade show mt-3">
        #encodeForHTML(errParam)#
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    </div>
</cfif>

<!--- ── Add User form ── --->
<div class="card border-0 shadow-sm mt-3 mb-4">
    <div class="card-body">
        <h5 class="mb-3"><i class="bi bi-person-plus me-2"></i>Add Admin User</h5>
        <form method="post" action="/admin/settings/admin-users/save.cfm" class="row g-3 align-items-end">
            <input type="hidden" name="action" value="addUser">
            <div class="col-auto">
                <label class="form-label">CougarNet Username</label>
                <input type="text" name="cougarnet" class="form-control" placeholder="e.g. jdoe123" required
                       pattern="[a-zA-Z0-9_]+" title="Alphanumeric / underscores only">
            </div>
            <div class="col-auto">
                <button type="submit" class="btn btn-primary"><i class="bi bi-plus-lg me-1"></i>Add User</button>
            </div>
        </form>
    </div>
</div>

<!--- ── Users table ── --->
<div class="card border-0 shadow-sm">
    <div class="card-body">
        <h5 class="mb-3"><i class="bi bi-people me-2"></i>Current Admin Users</h5>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th>ID</th>
                        <th>CougarNet</th>
                        <th>Status</th>
                        <th>Roles</th>
                        <th class="text-end">Actions</th>
                    </tr>
                </thead>
                <tbody>
                <cfloop array="#users#" index="u">
                    <tr>
                        <td>#u.USER_ID#</td>
                        <td><strong>#encodeForHTML(u.COUGARNET)#</strong></td>
                        <td>
                            <cfif u.IS_ACTIVE>
                                <span class="badge bg-success">Active</span>
                            <cfelse>
                                <span class="badge bg-secondary">Inactive</span>
                            </cfif>
                        </td>
                        <td>
                            <cfif len(trim(u.ROLE_NAMES ?: ""))>
                                <cfloop list="#u.ROLE_NAMES#" index="rn" delimiters=",">
                                    <span class="badge bg-primary me-1">#encodeForHTML(trim(rn))#</span>
                                </cfloop>
                            <cfelse>
                                <span class="text-muted fst-italic">No roles</span>
                            </cfif>
                        </td>
                        <td class="text-end">
                            <!--- Toggle active --->
                            <form method="post" action="/admin/settings/admin-users/save.cfm" class="d-inline">
                                <input type="hidden" name="action" value="toggleActive">
                                <input type="hidden" name="userID" value="#u.USER_ID#">
                                <cfif u.IS_ACTIVE>
                                    <button type="submit" class="btn btn-sm btn-outline-warning"
                                            title="Deactivate"
                                            onclick="return confirm('Deactivate #encodeForJavaScript(u.COUGARNET)#?')">
                                        <i class="bi bi-pause-circle"></i>
                                    </button>
                                <cfelse>
                                    <button type="submit" class="btn btn-sm btn-outline-success" title="Activate">
                                        <i class="bi bi-play-circle"></i>
                                    </button>
                                </cfif>
                            </form>
                            <!--- Manage Roles --->
                            <button type="button" class="btn btn-sm btn-outline-primary"
                                    title="Manage Roles"
                                    data-bs-toggle="modal"
                                    data-bs-target="##rolesModal#u.USER_ID#">
                                <i class="bi bi-key"></i>
                            </button>
                        </td>
                    </tr>

                    <!--- Roles modal --->
                    <div class="modal fade" id="rolesModal#u.USER_ID#" tabindex="-1">
                        <div class="modal-dialog">
                            <div class="modal-content">
                                <div class="modal-header">
                                    <h5 class="modal-title">Roles for #encodeForHTML(u.COUGARNET)#</h5>
                                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                                </div>
                                <div class="modal-body">
                                    <cfset currentRoleIDs = listToArray(u.ROLE_IDS ?: "")>
                                    <cfloop array="#allRoles#" index="role">
                                        <cfset hasRole = arrayFindNoCase(currentRoleIDs, role.ROLE_ID)>
                                        <div class="d-flex justify-content-between align-items-center mb-2">
                                            <span>
                                                <cfif hasRole>
                                                    <i class="bi bi-check-circle-fill text-success me-1"></i>
                                                <cfelse>
                                                    <i class="bi bi-circle text-muted me-1"></i>
                                                </cfif>
                                                #encodeForHTML(role.ROLE_NAME)#
                                            </span>
                                            <form method="post" action="/admin/settings/admin-users/save.cfm" class="d-inline">
                                                <input type="hidden" name="userID" value="#u.USER_ID#">
                                                <input type="hidden" name="roleID" value="#role.ROLE_ID#">
                                                <cfif hasRole>
                                                    <input type="hidden" name="action" value="revokeRole">
                                                    <button type="submit" class="btn btn-sm btn-outline-danger">Revoke</button>
                                                <cfelse>
                                                    <input type="hidden" name="action" value="assignRole">
                                                    <button type="submit" class="btn btn-sm btn-outline-success">Assign</button>
                                                </cfif>
                                            </form>
                                        </div>
                                    </cfloop>
                                </div>
                            </div>
                        </div>
                    </div>
                </cfloop>
                </tbody>
            </table>
        </div>
    </div>
</div>

<div class="mt-3">
    <a href="/admin/settings/admin-roles/" class="btn btn-outline-secondary">
        <i class="bi bi-gear me-1"></i>Manage Roles
    </a>
</div>

</cfoutput>
</cfsavecontent>

<cfinclude template="/admin/layout.cfm">
