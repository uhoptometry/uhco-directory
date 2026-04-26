<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>UHCO Identity Admin</title>

    <link rel="stylesheet" href="/assets/css/admin.css">
    
    <!-- Bootstrap Icons -->
    <link rel="stylesheet" href="/assets/vendor/bootstrap-icons/bootstrap-icons.css">

    <cfif structKeyExists(variables, "pageStyles")>
        <cfoutput>#pageStyles#</cfoutput>
    </cfif>
</head>

<body>
<div>
    <!-- Sidebar -->
    <cfoutput>
    <nav class="sidebar p-3" id="sidebar">
        <script>
            // Apply collapsed state immediately to prevent flicker
            if (localStorage.getItem('sidebarCollapsed') === 'true') {
                document.getElementById('sidebar').classList.add('collapsed');
            }
        </script>
        <div class="sidebar-header">
            <h4 class="sidebar-title text-white mb-0" aria-hidden="true">&nbsp;</h4>
        </div>
        
        <ul class="nav flex-column sidebar-nav">
            <li class="nav-item">
                <a class="nav-link" href="#request.webRoot#/admin/dashboard.cfm">
                    <i class="bi bi-speedometer2 sidebar-icon"></i>
                    <span class="sidebar-label">Dashboard</span>
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="#request.webRoot#/admin/users/index.cfm?list=all" id="usersToggle">
                    <i class="bi bi-people-fill sidebar-icon"></i>
                    <span class="sidebar-label">Users</span>
                </a>
            </li>
            <cfif request.hasPermission("media.view")>
            <li class="nav-item">
                <a class="nav-link" href="#request.webRoot#/admin/user-media/index.cfm">
                    <i class="bi bi-collection-fill sidebar-icon"></i>
                    <span class="sidebar-label">User Media</span>
                </a>
            </li>
            </cfif>
            <li class="nav-item">
                <a class="nav-link" href="#request.webRoot#/admin/flags/index.cfm">
                    <i class="bi bi-flag-fill sidebar-icon"></i>
                    <span class="sidebar-label">Flags</span>
                </a>
            </li>
            
            <li class="nav-item">
                <a class="nav-link" href="#request.webRoot#/admin/orgs/index.cfm">
                    <i class="bi bi-building-fill sidebar-icon"></i>
                    <span class="sidebar-label">Organizations</span>
                </a>
            </li>
            <li class="nav-item">
                <a class="nav-link" href="#request.webRoot#/admin/external/index.cfm">
                    <i class="bi bi-person-bounding-box sidebar-icon"></i>
                    <span class="sidebar-label">External IDs</span>
                </a>
            </li>
            <li class="nav-item">
                <a href='/admin/users/search_UH_API.cfm' class='nav-link'>
                    <i class='bi bi-search me-1'></i><span class="sidebar-label">Search UH API</span>
                </a>
            </li>
            <li class="nav-item">
                <a href='/admin/users/search_UH_LDAP.cfm' class='nav-link'>
                    <i class='bi bi-person-vcard me-1'></i><span class="sidebar-label">Search UH LDAP</span>
                </a>
            </li>
        </ul>
            <cfif request.hasPermission("settings.view") OR request.hasAnyPermission([
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
                "settings.uh_sync.view",
                "settings.query_builder.use",
                "settings.scheduled_tasks.manage",
                "settings.workflows.manage"
            ])>
            <div class="mt-auto pt-3 pb-1 border-top d-flex justify-content-start">
                <a href="#request.webRoot#/admin/settings/" class="text-white settings settings-btn" title="Settings" id="settingsGear">
                    <i class="bi bi-gear-fill"></i><span class="sidebar-label">Settings</span>
                </a>
            </div>
            </cfif>
    </nav>
    </cfoutput>
    
    

    <!-- Main Content wrapper — offset for fixed sidebar -->
    <div class="main-content d-flex" id="mainContent">
    
    <script>
        // Sync main content offset immediately to prevent layout shift
        if (localStorage.getItem('sidebarCollapsed') === 'true') {
            document.getElementById('mainContent').classList.add('sidebar-collapsed');
        }
    </script>
    <cfset isSettingsSection = structKeyExists(cgi, "script_name") AND findNoCase("/admin/settings/", cgi.script_name) GT 0>
    <cfset isUsersSection = structKeyExists(cgi, "script_name") AND findNoCase("/admin/users/", cgi.script_name) GT 0>
    <cfparam name="contentWrapperClass" default="py-4 px-4 pt-2">
    <cfparam name="showGlobalAdminToolbar" default="#NOT isUsersSection#">
    <cfset normalizedContentWrapperClass = trim(contentWrapperClass ?: "")>

    <cfset currentAdminUser = structKeyExists(session, "user") AND isStruct(session.user) ? session.user : {}>
    <cfset currentUserDisplayName = encodeForHTML(trim(currentAdminUser.displayName ?: "Admin User"))>
    <cfset currentUserEmail = encodeForHTML(trim(currentAdminUser.email ?: ""))>
    <cfset currentUserUsername = encodeForHTML(trim(currentAdminUser.username ?: ""))>
    <cfset currentUserRoleLabel = "">
    <cfset currentUserImageSrc = "">
    <cfset impersonationState = {}>
    <cfset currentRequestUrl = cgi.script_name & (len(trim(cgi.query_string ?: "")) ? "?" & cgi.query_string : "")>
    <cfset toolbarTitle = "Admin">
    <cfset toolbarIconClass = "bi-grid-1x2-fill">

    <cfif structKeyExists(currentAdminUser, "roles") AND isArray(currentAdminUser.roles) AND arrayLen(currentAdminUser.roles)>
        <cfset currentUserRoleLabel = encodeForHTML(replace(currentAdminUser.roles[1], "_", " ", "all"))>
    </cfif>

    <cfif structKeyExists(currentAdminUser, "image")>
        <cfset currentUserImageSrc = trim(currentAdminUser.image ?: "")>
    </cfif>
    <cfif NOT len(currentUserImageSrc) AND structKeyExists(currentAdminUser, "avatar")>
        <cfset currentUserImageSrc = trim(currentAdminUser.avatar ?: "")>
    </cfif>
    <cfif NOT len(currentUserImageSrc)>
        <cfset currentUserImageSrc = request.webRoot & "/assets/images/uh.png">
    </cfif>

    <cfif structKeyExists(application, "authService") AND application.authService.isImpersonating() AND application.authService.isActualSuperAdmin()>
        <cfset impersonationState = application.authService.getImpersonationState()>
    </cfif>

    <cfif structKeyExists(variables, "pageTitle") AND len(trim(variables.pageTitle ?: ""))>
        <cfset toolbarTitle = trim(variables.pageTitle)>
    <cfelseif structKeyExists(cgi, "script_name")>
        <cfset normalizedScriptName = lcase(replace(cgi.script_name ?: "", "\", "/", "all"))>
        <cfif findNoCase("/admin/dashboard", normalizedScriptName)>
            <cfset toolbarTitle = "Dashboard">
            <cfset toolbarIconClass = "bi-speedometer2">
        <cfelseif findNoCase("/admin/settings/", normalizedScriptName)>
            <cfset toolbarTitle = "Settings">
            <cfset toolbarIconClass = "bi-gear-fill">
        <cfelseif findNoCase("/admin/user-media/", normalizedScriptName)>
            <cfset toolbarTitle = "User Media">
            <cfset toolbarIconClass = "bi-collection-fill">
        <cfelseif findNoCase("/admin/flags/", normalizedScriptName)>
            <cfset toolbarTitle = "Flags">
            <cfset toolbarIconClass = "bi-flag-fill">
        <cfelseif findNoCase("/admin/orgs/", normalizedScriptName)>
            <cfset toolbarTitle = "Organizations">
            <cfset toolbarIconClass = "bi-building-fill">
        <cfelseif findNoCase("/admin/external/", normalizedScriptName)>
            <cfset toolbarTitle = "External IDs">
            <cfset toolbarIconClass = "bi-person-bounding-box">
        <cfelseif findNoCase("/admin/users/search_uh_api.cfm", normalizedScriptName)>
            <cfset toolbarTitle = "Search UH API">
            <cfset toolbarIconClass = "bi-search">
        <cfelseif findNoCase("/admin/users/search_uh_ldap.cfm", normalizedScriptName)>
            <cfset toolbarTitle = "Search UH LDAP">
            <cfset toolbarIconClass = "bi-person-vcard">
        <cfelseif findNoCase("/admin/reporting/", normalizedScriptName)>
            <cfset toolbarTitle = "Reporting">
            <cfset toolbarIconClass = "bi-bar-chart-line-fill">
        <cfelse>
            <cfset scriptParts = listToArray(reReplace(normalizedScriptName, "^/+|/+$", "", "all"), "/")>
            <cfif arrayLen(scriptParts) GTE 2>
                <cfset candidateTitle = scriptParts[arrayLen(scriptParts)]>
                <cfif compareNoCase(candidateTitle, "index.cfm") EQ 0 AND arrayLen(scriptParts) GTE 3>
                    <cfset candidateTitle = scriptParts[arrayLen(scriptParts) - 1]>
                <cfelse>
                    <cfset candidateTitle = listFirst(candidateTitle, ".")>
                </cfif>
                <cfset candidateTitle = reReplace(candidateTitle, "[-_]+", " ", "all")>
                <cfif len(candidateTitle)>
                    <cfset toolbarTitle = uCase(left(candidateTitle, 1)) & mid(candidateTitle, 2, len(candidateTitle))>
                </cfif>
            </cfif>
        </cfif>
    </cfif>

    <cfset toolbarTitle = encodeForHTML(toolbarTitle)>

    <main class="flex-fill <cfif isSettingsSection> admin-main-settings</cfif>" style="min-width:0; overflow-x:hidden;">
        <cfif showGlobalAdminToolbar>
            <cfoutput>
            <nav class="navbar sticky-top bg-slate text-white users-list-toolbar admin-global-toolbar" data-toolbar-title="#encodeForHTMLAttribute(toolbarTitle)#">
                <div class="container-fluid users-list-toolbar-shell">
                    <div class="users-list-toolbar-primary">
                        <button class="sidebar-toggle" id="sidebarToggle" title="Toggle Sidebar" aria-label="Toggle Sidebar">
                            <i class="bi bi-chevron-left"></i>
                        </button>
                        <h1 class="navbar-brand text-white users-list-toolbar-brand mb-0 fs-5 d-flex align-items-center gap-2">
                            <span>UHCO_Identity</span>
                            <span>|</span>
                            <i class="bi #encodeForHTMLAttribute(toolbarIconClass)#"></i>
                            <span>#toolbarTitle#</span>
                        </h1>
                    </div>
                    <ul class="navbar-nav d-flex flex-row align-items-center gap-2 ms-auto users-list-toolbar-nav">
                        <li class="nav-item dropdown ms-3 users-list-toolbar-account">
                            <a class="nav-link dropdown-toggle d-flex align-items-center text-white" href="##" role="button" data-bs-toggle="dropdown" aria-expanded="false">
                                <i class="bi bi-person-circle me-2"></i>
                                #currentUserDisplayName#
                            </a>
                            <div class="dropdown-menu dropdown-menu-end p-3 users-list-toolbar-dropdown" style="min-width: 320px;">
                                <div class="d-flex align-items-center gap-3 mb-3 users-list-toolbar-account-header">
                                    <img src="#encodeForHTMLAttribute(currentUserImageSrc)#" alt="Profile image for #encodeForHTMLAttribute(trim(currentAdminUser.displayName ?: "Admin User"))#" class="users-list-toolbar-avatar rounded-circle">
                                    <div class="users-list-toolbar-account-meta">
                                        <h6 class="mb-1">#currentUserDisplayName#</h6>
                                        #len(currentUserEmail) ? "<div class='small text-muted'>" & currentUserEmail & "</div>" : ""#
                                        #len(currentUserUsername) ? "<div class='small text-muted'>@" & currentUserUsername & "</div>" : ""#
                                    </div>
                                </div>
                                #len(currentUserRoleLabel) ? "<div class='bg-light p-2 rounded mb-3'><small class='d-block text-uppercase fw-bold text-muted users-list-toolbar-label'>Role</small><span class='badge text-bg-primary'>" & currentUserRoleLabel & "</span></div>" : ""#
                                #structCount(impersonationState) ? "<div class='users-list-toolbar-impersonation alert alert-warning mb-3 py-2 px-3'><div class='small fw-semibold text-uppercase mb-1'>Impersonation Active</div><div class='small mb-2'>You are currently using <strong>" & encodeForHTML(impersonationState.label ?: "") & "</strong>.</div><form method='post' action='" & request.webRoot & "/admin/settings/admin-users/save.cfm' class='mb-0'><input type='hidden' name='action' value='clearImpersonation'><input type='hidden' name='returnURL' value='" & encodeForHTMLAttribute(currentRequestUrl) & "'><button type='submit' class='btn btn-sm btn-outline-dark w-100'><i class='bi bi-x-octagon me-1'></i>Stop Impersonating</button></form></div>" : ""#
                                <div class="d-grid">
                                    <a href="#request.webRoot#/admin/logout.cfm" class="btn btn-outline-primary btn-sm"><i class="bi bi-box-arrow-right me-1"></i>Logout</a>
                                </div>
                            </div>
                        </li>
                    </ul>
                </div>
            </nav>
            </cfoutput>
        </cfif>
        <cfif len(normalizedContentWrapperClass)>
            <cfoutput><div class="#encodeForHTMLAttribute(normalizedContentWrapperClass)# admin-toolbar-content-root">#content#</div></cfoutput>
        <cfelse>
            <cfoutput><div class="admin-toolbar-content-root">#content#</div></cfoutput>
        </cfif>
        
        <cfif isDefined('url.dump')><cfdump var="#session.user#">

       
    <cfldap 
        action="QUERY"
        name="qFindUser2"
        attributes="displayName,sAMAccountName,mail,employeeid"
        start="OU=Master Users,DC=cougarnet,DC=uh,DC=edu"
        scope="SUBTREE"
        server="cougarnet.uh.edu"
        filter="(&(objectClass=user)(objectCategory=person)(|(sAMAccountName=amarchi2)(displayName=amarchi2)(mail=amarchi2)(userPrincipalName=amarchi2)))"
        username="COUGARNET\svc-opt-cfserv"
        password="Xu&mLtgdtKV5bQ@M">
    </cfldap>
    <cfset searchTerm = "oaborahm">
    <cfset filter = "(&(objectClass=user)(objectCategory=person)(|(sAMAccountName=#searchTerm#)(displayName=#searchTerm#)(mail=#searchTerm#)(userPrincipalName=#searchTerm#))(|(memberOf=CN=OPT-Class2026,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu)(memberOf=CN=OPT-Class2027,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu)(memberOf=CN=OPT-Class2028,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu)(memberOf=CN=OPT-Class2029,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu)))">
    <cfset attributes = "displayName,sAMAccountName,mail,employeeid">
    <cfset user = "COUGARNET\svc-opt-cfserv">
    <cfset password = "Xu&mLtgdtKV5bQ@M">
    <cfldap 
        action="QUERY"
        name="qFindUser3"
        attributes="#attributes#"
        start="OU=Master Users,DC=cougarnet,DC=uh,DC=edu"
        scope="SUBTREE"
        server="cougarnet.uh.edu"
        filter="(&(objectClass=user)(objectCategory=person)(|(sAMAccountName=#searchTerm#)(displayName=#searchTerm#)(mail=#searchTerm#)(userPrincipalName=#searchTerm#)))"
        username="#user#"
        password="#password#">
    </cfldap>






   <!--- CN=OPT-ClassOf2026,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu|CN=OPT-ClassOf2027,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu|CN=OPT-ClassOf2028,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu|CN=OPT-ClassOf2029,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu

        CN=OPT-OPTOMETRY,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu<Br/>
        -OPT-ClassOf2026,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu<Br/>
        -OPT-ClassOf2027,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu<Br/>
        -OPT-ClassOf2028,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu<Br/>
        -OPT-ClassOf2029,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu<Br/>
        -OPT-Staff,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu<Br/>
        -OPT-Faculty,OU=Distribution Groups,OU=OPTOMETRY,DC=cougarnet,DC=uh,DC=edu<Br/>
        <cfdump var="#qGetGroupDN#" label="Group DNs for Optometry distribution groups">
        <cfdump var="#qFindUser#" label="User found with uhcoweb account">--->
        <cfdump var="#qFindUser2#" label="User found with svc-opt-cfserv account">
        <cfdump var="#qFindUser3#" label="User found in class of groups">
        </cfif>
    </main>

    <cfif CGI.SCRIPT_NAME CONTAINS "/admin/users/edit.cfm">
        <div class="viewbar p-3 d-none">
            <cfoutput>
                #ViewContent#
            </cfoutput>
        </div>
    </cfif>
    </div><!--- /.main-content d-flex --->
</div>

<cfoutput>
<div class="toast-container environment-toast">
    <div
        id="environmentToast"
        class="toast border-0 shadow-sm"
        role="status"
        aria-live="polite"
        aria-atomic="true"
        data-bs-autohide="false"
        data-environment-name="#encodeForHTMLAttribute(request.environmentName)#"
    >
        <div class="toast-header #(request.isProduction ? "text-bg-danger" : "text-bg-success")# border-0">
            <i class="bi #(request.isProduction ? "bi-broadcast-pin" : "bi-laptop")# me-2"></i>
            <strong class="me-auto">Environment</strong>
            <small>#encodeForHTML(ucase(left(request.environmentName, 1)) & mid(request.environmentName, 2, len(request.environmentName)))#</small>
            <button type="button" class="btn-close btn-close-white ms-2 mb-1" data-bs-dismiss="toast" aria-label="Close"></button>
        </div>
        <div class="toast-body bg-white">
            Current session is running in <strong>#encodeForHTML(request.environmentName)#</strong>.
        </div>
    </div>
</div>
</cfoutput>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.8/dist/js/bootstrap.bundle.min.js" integrity="sha384-FKyoEForCGlyvwx9Hj09JcYn3nv7wiPVlz7YYwJrWVcXK/BmnVDxM+D2scQbITxI" crossorigin="anonymous"></script>

<cfif structKeyExists(variables, "pageScripts")>
    <cfoutput>#pageScripts#</cfoutput>
</cfif>

<cfoutput><script>const WEBROOT='#request.webRoot#';</script></cfoutput>

<script>
    function toggleUserMedia(e) {
        e.preventDefault();
        const submenu = document.getElementById('userMediaSubmenu');
        const chevron  = document.getElementById('userMediaChevron');
        const open     = submenu.style.display === 'block';
        submenu.style.display = open ? 'none' : 'block';
        chevron.style.transform = open ? '' : 'rotate(180deg)';
    }

    function toggleAPI(e) {
        e.preventDefault();
        const submenu = document.getElementById('apiSubmenu');
        const chevron  = document.getElementById('apiChevron');
        const open     = submenu.style.display === 'block';
        submenu.style.display = open ? 'none' : 'block';
        chevron.style.transform = open ? '' : 'rotate(180deg)';
    }

    function toggleReporting(e) {
        e.preventDefault();
        const submenu  = document.getElementById('reportingSubmenu');
        const chevron  = document.getElementById('reportingChevron');
        const open     = submenu.style.display === 'block';
        submenu.style.display = open ? 'none' : 'block';
        chevron.style.transform = open ? '' : 'rotate(180deg)';
    }

    document.addEventListener('DOMContentLoaded', function() {
        // Auto-expand API submenu when a child page is active
        const apiPages = [
            WEBROOT+'/admin/settings/uhco-api/tokens/',
            WEBROOT+'/admin/settings/uhco-api/secrets/'
        ];
        if (apiPages.some(p => window.location.pathname.toLowerCase().startsWith(p))) {
            const apiSubmenu = document.getElementById('apiSubmenu');
            const apiChevron = document.getElementById('apiChevron');
            if (apiSubmenu) { apiSubmenu.style.display = 'block'; }
            if (apiChevron) { apiChevron.style.transform = 'rotate(180deg)'; }
        }

        
        // Highlight settings gear when on a settings page
        if (window.location.pathname.toLowerCase().startsWith(WEBROOT+'/admin/settings/')) {
            const gear = document.getElementById('settingsGear');
            if (gear) { gear.style.color = '#f0d878'; }
        }

        // Auto-expand Reporting submenu when a child page is active
        const reportingPages = [
            WEBROOT+'/admin/users/uh_people_import.cfm',
            WEBROOT+'/admin/users/uh_people_db_not_in_api.cfm',
            WEBROOT+'/admin/reporting/OLD/cs-migration.cfm',
            WEBROOT+'/admin/reporting/OLD/cs-bulk-import.cfm',
            WEBROOT+'/admin/reporting/OLD/cs-alumni-bulk-import.cfm',
            WEBROOT+'/admin/reporting/OLD/od-student-audit.cfm'
        ];
        if (reportingPages.some(p => window.location.pathname.startsWith(p))) {
            const submenu = document.getElementById('reportingSubmenu');
            const chevron = document.getElementById('reportingChevron');
            if (submenu) { submenu.style.display = 'block'; }
            if (chevron) { chevron.style.transform = 'rotate(180deg)'; }
        }

        const sidebar = document.getElementById('sidebar');
        const sidebarToggle = document.getElementById('sidebarToggle');
        const toggleIcon = sidebarToggle.querySelector('i');
        
        // Initialize toggle icon based on current collapsed state
        if (sidebar.classList.contains('collapsed')) {
            toggleIcon.classList.remove('bi-chevron-left');
            toggleIcon.classList.add('bi-chevron-right');
        }

        // Hide duplicate top-level page title if it matches the global toolbar title.
        const globalToolbar = document.querySelector('.admin-global-toolbar[data-toolbar-title]');
        const toolbarContentRoot = document.querySelector('.admin-toolbar-content-root');
        if (globalToolbar && toolbarContentRoot) {
            const normalizeTitle = function(text) {
                return (text || '')
                    .toLowerCase()
                    .replace(/\s+/g, ' ')
                    .replace(/[^a-z0-9 ]/g, '')
                    .trim();
            };

            const toolbarTitle = normalizeTitle(globalToolbar.getAttribute('data-toolbar-title'));
            const firstHeading = toolbarContentRoot.querySelector('h1');
            const currentPath = (window.location.pathname || '').toLowerCase();
            const forceHideDuplicateTitle = currentPath.includes('/admin/flags/')
                || currentPath.includes('/admin/orgs/')
                || currentPath.includes('/admin/external/');

            if (firstHeading) {
                const headingTitle = normalizeTitle(firstHeading.textContent);
                const fuzzyMatch = headingTitle === toolbarTitle
                    || headingTitle.startsWith(toolbarTitle)
                    || toolbarTitle.startsWith(headingTitle)
                    || (toolbarTitle === 'flags' && headingTitle.includes('flag'))
                    || (toolbarTitle === 'organizations' && headingTitle.includes('org'))
                    || (toolbarTitle === 'external ids' && headingTitle.includes('external'));

                if (forceHideDuplicateTitle || fuzzyMatch) {
                    firstHeading.classList.add('d-none');
                }
            }
        }

        const environmentToastEl = document.getElementById('environmentToast');
        if (environmentToastEl && window.bootstrap) {
            const environmentKey = 'environmentToastDismissed:' + environmentToastEl.dataset.environmentName;
            const environmentToast = bootstrap.Toast.getOrCreateInstance(environmentToastEl);

            if (!sessionStorage.getItem(environmentKey)) {
                environmentToast.show();
            }

            environmentToastEl.addEventListener('hidden.bs.toast', function() {
                sessionStorage.setItem(environmentKey, 'true');
            });
        }
        
        // Toggle sidebar on button click
        sidebarToggle.addEventListener('click', function() {
            sidebar.classList.toggle('collapsed');
            const nowCollapsed = sidebar.classList.contains('collapsed');
            localStorage.setItem('sidebarCollapsed', nowCollapsed);

            // Sync main content offset
            const mainContent = document.getElementById('mainContent');
            if (mainContent) {
                mainContent.classList.toggle('sidebar-collapsed', nowCollapsed);
            }
            
            // Update icon
            if (nowCollapsed) {
                toggleIcon.classList.remove('bi-chevron-left');
                toggleIcon.classList.add('bi-chevron-right');
            } else {
                toggleIcon.classList.remove('bi-chevron-right');
                toggleIcon.classList.add('bi-chevron-left');
            }
        });
        
        // Mark active link and its top-level nav-item based on current page
        const currentURL  = new URL(window.location.href);
        const currentPage = currentURL.pathname.toLowerCase();
        const currentList = (currentURL.searchParams.get('list') || '').toLowerCase();

        document.querySelectorAll('.sidebar .sidebar-nav a[href]').forEach(link => {
            const rawHref = link.getAttribute('href');
            // Skip dropdown toggles (href="#")
            if (!rawHref || rawHref === '#') return;
            const linkURL  = new URL(link.href, window.location.origin);
            const linkPath = linkURL.pathname.toLowerCase();
            const linkList = (linkURL.searchParams.get('list') || '').toLowerCase();

            // Match: same path AND same list param (or both empty)
            let isActive = false;
            if (linkPath === currentPage) {
                if (linkList && currentList) {
                    isActive = (linkList === currentList);
                } else if (!linkList && !currentList) {
                    isActive = true;
                } else if (!currentList && linkList === 'problems') {
                    // Default: no ?list in URL matches the "problems" sidebar link
                    isActive = true;
                } else if (!linkList) {
                    // Links without a list param (e.g. Search UH API) match by path only
                    isActive = true;
                }
            }

            if (isActive) {
                link.classList.add('active');
                // Walk up to the top-level nav-item LI and mark it active
                let li = link.closest('.nav-item');
                while (li) {
                    const parentUl = li.parentElement;
                    const parentLi = parentUl ? parentUl.closest('.nav-item') : null;
                    if (!parentLi) {
                        // This is the top-level LI
                        li.classList.add('active');
                        break;
                    }
                    li = parentLi;
                }
            }
        });

        // Ensure Users parent item is active for child routes that do not have direct sidebar links.
        const usersBasePath = (WEBROOT + '/admin/users/').toLowerCase();
        if (currentPage.startsWith(usersBasePath)) {
            const usersToggle = document.getElementById('usersToggle');
            if (usersToggle) {
                usersToggle.classList.add('active');
                const usersTopNavItem = usersToggle.closest('.nav-item');
                if (usersTopNavItem) {
                    usersTopNavItem.classList.add('active');
                }
            }
        }
    });
</script>
</body>
</html>
