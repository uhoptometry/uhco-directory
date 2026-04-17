<!---
    Admin Roles — list, create, edit, delete roles.
    SUPER_ADMIN only.
--->

<cfif NOT request.hasRole("SUPER_ADMIN")>
    <cflocation url="#request.webRoot#/admin/unauthorized.cfm" addtoken="false">
</cfif>

<cfset authSvc  = createObject("component", "cfc.adminAuth_service").init()>
<cfset roles    = authSvc.getAllRoles()>
<cfset msgParam = structKeyExists(url, "msg") ? url.msg : "">
<cfset errParam = structKeyExists(url, "err") ? url.err : "">
<cfset editID   = (structKeyExists(url, "edit") AND isNumeric(url.edit)) ? val(url.edit) : 0>
<cfset editRole = editID GT 0 ? authSvc.getRoleByID(editID) : {}>

<cfset content = "">
<cfsavecontent variable="content">
<cfoutput>

<nav aria-label="breadcrumb">
    <ol class="breadcrumb">
        <li class="breadcrumb-item"><a href="/admin/settings/">Settings</a></li>
        <li class="breadcrumb-item"><a href="/admin/settings/admin-users/">Admin Users</a></li>
        <li class="breadcrumb-item active">Roles</li>
    </ol>
</nav>

<h1 class="mb-1"><i class="bi bi-key me-2"></i>Admin Roles</h1>
<p class="text-muted">Create and manage roles that control admin panel access.</p>

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

<!--- ── Create / Edit form ── --->
<div class="card border-0 shadow-sm mt-3 mb-4">
    <div class="card-body">
        <h5 class="mb-3">
            <cfif structCount(editRole)>
                <i class="bi bi-pencil me-2"></i>Edit Role
            <cfelse>
                <i class="bi bi-plus-circle me-2"></i>Create Role
            </cfif>
        </h5>
        <form method="post" action="/admin/settings/admin-roles/save.cfm" class="row g-3 align-items-end">
            <cfif structCount(editRole)>
                <input type="hidden" name="action" value="updateRole">
                <input type="hidden" name="roleID" value="#editRole.ROLE_ID#">
            <cfelse>
                <input type="hidden" name="action" value="createRole">
            </cfif>
            <div class="col-auto">
                <label class="form-label">Role Name</label>
                <input type="text" name="roleName" class="form-control text-uppercase"
                       value="#encodeForHTMLAttribute(structCount(editRole) ? editRole.ROLE_NAME : '')#"
                       placeholder="e.g. REPORT_ADMIN" required>
            </div>
            <div class="col-auto">
                <button type="submit" class="btn btn-primary">
                    <cfif structCount(editRole)>Update<cfelse>Create</cfif>
                </button>
                <cfif structCount(editRole)>
                    <a href="/admin/settings/admin-roles/" class="btn btn-outline-secondary">Cancel</a>
                </cfif>
            </div>
        </form>
    </div>
</div>

<!--- ── Roles table ── --->
<div class="card border-0 shadow-sm">
    <div class="card-body">
        <h5 class="mb-3"><i class="bi bi-list-ul me-2"></i>All Roles</h5>
        <div class="table-responsive">
            <table class="table table-hover align-middle mb-0">
                <thead class="table-light">
                    <tr>
                        <th>ID</th>
                        <th>Role Name</th>
                        <th class="text-end">Actions</th>
                    </tr>
                </thead>
                <tbody>
                <cfloop array="#roles#" index="r">
                    <tr>
                        <td>#r.ROLE_ID#</td>
                        <td><span class="badge bg-primary">#encodeForHTML(r.ROLE_NAME)#</span></td>
                        <td class="text-end">
                            <a href="/admin/settings/admin-roles/?edit=#r.ROLE_ID#" class="btn btn-sm btn-outline-primary" title="Edit">
                                <i class="bi bi-pencil"></i>
                            </a>
                            <cfif r.ROLE_NAME NEQ "SUPER_ADMIN">
                                <form method="post" action="/admin/settings/admin-roles/save.cfm" class="d-inline">
                                    <input type="hidden" name="action" value="deleteRole">
                                    <input type="hidden" name="roleID" value="#r.ROLE_ID#">
                                    <button type="submit" class="btn btn-sm btn-outline-danger" title="Delete"
                                            onclick="return confirm('Delete role #encodeForJavaScript(r.ROLE_NAME)#? This will remove it from all users.')">
                                        <i class="bi bi-trash"></i>
                                    </button>
                                </form>
                            <cfelse>
                                <button class="btn btn-sm btn-outline-secondary" disabled title="SUPER_ADMIN cannot be deleted">
                                    <i class="bi bi-lock"></i>
                                </button>
                            </cfif>
                        </td>
                    </tr>
                </cfloop>
                </tbody>
            </table>
        </div>
    </div>
</div>

</cfoutput>
</cfsavecontent>

<cfinclude template="/admin/layout.cfm">
