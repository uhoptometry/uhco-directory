<cfif !structKeyExists(url, "userID") OR !isNumeric(url.userID)>
    <cflocation url="/dir/admin/users/index.cfm" addtoken="false">
</cfif>

<cfset directoryService = createObject("component", "dir.cfc.directory_service").init()>
<cfset flagsService = createObject("component", "dir.cfc.flags_service").init()>
<cfset organizationsService = createObject("component", "dir.cfc.organizations_service").init()>
<cfset user = directoryService.getFullProfile( url.userID ).user>
<cfset userFlags = directoryService.getFullProfile( url.userID ).flags>
<cfset userOrganizations = directoryService.getFullProfile( url.userID ).organizations>
<cfset allFlagsResult = flagsService.getAllFlags()>
<cfset allFlags = allFlagsResult.data />
<cfset allOrganizationsResult = organizationsService.getAllOrgs()>
<cfset allOrganizations = allOrganizationsResult.data />


<cfset userFlagIDs = []>
<cfloop from="1" to="#arrayLen(userFlags)#" index="i">
    <cfset arrayAppend(userFlagIDs, userFlags[i].FLAGID)>
</cfloop>

<!--- ── Determine grad year visibility ── --->
<cfset gradYearFlagIDs = []>
<cfloop from="1" to="#arrayLen(allFlags)#" index="i">
    <cfset flagNameLC = lCase(trim(allFlags[i].FLAGNAME))>
    <cfif flagNameLC EQ "current-student" OR flagNameLC EQ "alumni">
        <cfset arrayAppend(gradYearFlagIDs, allFlags[i].FLAGID)>
    </cfif>
</cfloop>
<cfset showGradYear = false>
<cfloop from="1" to="#arrayLen(gradYearFlagIDs)#" index="i">
    <cfif arrayFindNoCase(userFlagIDs, gradYearFlagIDs[i]) GT 0>
        <cfset showGradYear = true>
        <cfbreak>
    </cfif>
</cfloop>

<cfset userOrgIDs = []>
<cfset orgRoleMap  = {}>
<cfloop from="1" to="#arrayLen(userOrganizations)#" index="i">
    <cfset arrayAppend(userOrgIDs, val(userOrganizations[i].ORGID))>
    <cfset orgRoleMap[toString(userOrganizations[i].ORGID)] = {
        roleTitle: (userOrganizations[i].ROLETITLE ?: ""),
        roleOrder: (isNumeric(userOrganizations[i].ROLEORDER ?: "") ? val(userOrganizations[i].ROLEORDER) : 0)
    }>
</cfloop>

<!--- ── External IDs ── --->
<cfset externalIDService = createObject("component", "dir.cfc.externalID_service").init()>
<cfset allSystemsResult = externalIDService.getSystems()>
<cfset allSystems = allSystemsResult.data>
<cfset userExtIDsResult = externalIDService.getExternalIDs(url.userID)>

<!--- ── Academic Info ── --->
<cfset academicService  = createObject("component", "dir.cfc.academic_service").init()>
<cfset academicInfo     = academicService.getAcademicInfo(url.userID).data>
<cfset currentGradYear  = structIsEmpty(academicInfo) ? "" : (academicInfo.CURRENTGRADYEAR  ?: "")>
<cfset originalGradYear = structIsEmpty(academicInfo) ? "" : (academicInfo.ORIGINALGRADYEAR ?: "")>
<cfif NOT isNumeric(currentGradYear)  OR val(currentGradYear)  EQ 0><cfset currentGradYear  = ""></cfif>
<cfif NOT isNumeric(originalGradYear) OR val(originalGradYear) EQ 0><cfset originalGradYear = ""></cfif>

<!--- ── Student Profile (Current Students only) ── --->
<cfset showStudentProfile = false>
<cfset studentFlagIDs     = []>
<cfloop from="1" to="#arrayLen(allFlags)#" index="i">
    <cfif lCase(trim(allFlags[i].FLAGNAME)) EQ "current-student">
        <cfset arrayAppend(studentFlagIDs, allFlags[i].FLAGID)>
        <cfif arrayFindNoCase(userFlagIDs, allFlags[i].FLAGID) GT 0>
            <cfset showStudentProfile = true>
        </cfif>
    </cfif>
</cfloop>
<cfif showStudentProfile>
    <cfset studentProfileSvc = createObject("component", "dir.cfc.studentProfile_service").init()>
    <cfset spProfile  = studentProfileSvc.getProfile(url.userID).data>
    <cfset spAwards   = studentProfileSvc.getAwards(url.userID).data>
    <cfset spHometown  = structIsEmpty(spProfile) ? "" : (spProfile.HOMETOWN          ?: "")>
    <cfset spFirstExt  = structIsEmpty(spProfile) ? "" : (spProfile.FIRSTEXTERNSHIP   ?: "")>
    <cfset spSecondExt = structIsEmpty(spProfile) ? "" : (spProfile.SECONDEXTERNSHIP  ?: "")>
<cfelse>
    <cfset spAwards    = []>
    <cfset spHometown  = "">
    <cfset spFirstExt  = "">
    <cfset spSecondExt = "">
</cfif>

<cfset userExternalIDs = userExtIDsResult.data>
<cfset externalBySystem = {}>
<cfloop from="1" to="#arrayLen(userExternalIDs)#" index="i">
    <cfset externalBySystem[toString(userExternalIDs[i].SYSTEMID)] = userExternalIDs[i].EXTERNALVALUE>
</cfloop>

<cfset extIDHtml = "<div class='mb-3'><label class='form-label fw-semibold'>External IDs</label><div class='border p-3 rounded'><div class='row g-2'>">
<cfif arrayLen(allSystems) GT 0>
    <cfloop from="1" to="#arrayLen(allSystems)#" index="i">
        <cfset sys = allSystems[i]>
        <cfset sysVal = structKeyExists(externalBySystem, toString(sys.SYSTEMID)) ? externalBySystem[toString(sys.SYSTEMID)] : "">
        <cfset extIDHtml &= "<div class='col-md-6 col-lg-4'><label class='form-label form-label-sm text-muted mb-1'>" & EncodeForHTML(sys.SYSTEMNAME) & "</label><input class='form-control form-control-sm' name='extID_" & sys.SYSTEMID & "' value='" & EncodeForHTMLAttribute(sysVal) & "' placeholder='Not set'></div>">
    </cfloop>
<cfelse>
    <cfset extIDHtml &= "<p class='text-muted mb-0'>No external systems configured.</p>">
</cfif>
<cfset extIDHtml &= "</div></div></div>">

<cfset orgIds = {}>
<cfset orgChildrenByParent = {}>

<cfloop from="1" to="#arrayLen(allOrganizations)#" index="i">
    <cfset org = allOrganizations[i]>
    <cfset orgIds[toString(org.ORGID)] = true>
</cfloop>

<cfloop from="1" to="#arrayLen(allOrganizations)#" index="i">
    <cfset org = allOrganizations[i]>
    <cfset parentValue = trim((org.PARENTORGID ?: "") & "")>
    <cfset parentKey = "ROOT">

    <cfif len(parentValue) AND structKeyExists(orgIds, parentValue)>
        <cfset parentKey = parentValue>
    </cfif>

    <cfif NOT structKeyExists(orgChildrenByParent, parentKey)>
        <cfset orgChildrenByParent[parentKey] = []>
    </cfif>
    <cfset arrayAppend(orgChildrenByParent[parentKey], org)>
</cfloop>

<cffunction name="renderOrgPanels" access="private" returntype="string" output="false">
    <cfargument name="selectedOrgIDs" type="array" required="true">

    <cfset var html         = "">
    <cfset var rootOrgs     = []>
    <cfset var ro           = {}>
    <cfset var children     = []>
    <cfset var child        = {}>
    <cfset var gcKey        = "">
    <cfset var grandchildren = []>
    <cfset var gc           = {}>
    <cfset var i            = 0>
    <cfset var j            = 0>
    <cfset var k            = 0>
    <cfset var isRootChecked  = false>
    <cfset var isChildChecked = false>
    <cfset var isGcChecked    = false>
    <cfset var collapseID     = "">

    <cfif NOT structKeyExists(orgChildrenByParent, "ROOT") OR arrayLen(orgChildrenByParent["ROOT"]) EQ 0>
        <cfreturn "<p class='text-muted'>No organizations available</p>">
    </cfif>

    <cfset rootOrgs = orgChildrenByParent["ROOT"]>
    <cfset html = "<div class='row row-cols-1 row-cols-md-2 row-cols-xl-3 g-3'>">

    <cfloop from="1" to="#arrayLen(rootOrgs)#" index="i">
        <cfset ro           = rootOrgs[i]>
        <cfset collapseID   = "orgPanel#ro.ORGID#">
        <cfset isRootChecked = arrayFindNoCase(arguments.selectedOrgIDs, val(ro.ORGID)) GT 0>
        <cfset children     = structKeyExists(orgChildrenByParent, toString(ro.ORGID)) ? orgChildrenByParent[toString(ro.ORGID)] : []>

        <cfset html &= "<div class='col'><div class='card shadow-sm h-100'>">

        <!--- Card header with parent checkbox --->
        <cfset html &= "<div class='card-header d-flex align-items-center gap-2 py-2 px-3'>">
        <cfset var roRoleTitle = (structKeyExists(orgRoleMap, toString(ro.ORGID)) ? orgRoleMap[toString(ro.ORGID)].roleTitle : '')>
        <cfset var roRoleOrder = (structKeyExists(orgRoleMap, toString(ro.ORGID)) ? val(orgRoleMap[toString(ro.ORGID)].roleOrder) : 0)>
        <cfset html &= "<div class='form-check mb-0 flex-grow-1 d-flex align-items-center gap-1'>">
        <cfset html &= "<input class='form-check-input flex-shrink-0 org-checkbox' type='checkbox' name='Organizations' value='#ro.ORGID#' id='org#ro.ORGID#' data-orgid='#ro.ORGID#' data-orgname='#EncodeForHTMLAttribute(ro.ORGNAME)#' data-parentorgid='' data-panelid='#collapseID#' data-isparent='1' #(isRootChecked ? 'checked' : '')#>">
        <cfset html &= "<label class='form-check-label fw-semibold user-select-none' for='org#ro.ORGID#'>#EncodeForHTML(ro.ORGNAME)#</label>">
        <cfset html &= "</div>">
        <cfif arrayLen(children) GT 0>
            <cfset html &= "<button class='btn btn-sm border-0 text-muted p-0 ms-1 org-chevron' type='button' data-bs-toggle='collapse' data-bs-target='###collapseID#' aria-expanded='true'><i class='bi bi-chevron-down'></i></button>">
        </cfif>
        <cfset html &= "</div>">

        <!--- Description (parent orgs only) --->
        <cfset var roDesc = trim(ro.ORGDESCRIPTION ?: '')>
        <cfif len(roDesc)>
            <cfset html &= "<div class='px-3 pt-2 pb-1 text-muted small border-bottom'>#EncodeForHTML(roDesc)#</div>">
        </cfif>

        <!--- Collapsible card body with children --->
        <cfif arrayLen(children) GT 0>
            <cfset html &= "<div id='#collapseID#' class='collapse show'>">
            <cfset html &= "<div class='card-body py-2 px-3'>">

            <cfloop from="1" to="#arrayLen(children)#" index="j">
                <cfset child        = children[j]>
                <cfset isChildChecked = arrayFindNoCase(arguments.selectedOrgIDs, val(child.ORGID)) GT 0>
                <cfset gcKey        = toString(child.ORGID)>
                <cfset grandchildren = structKeyExists(orgChildrenByParent, gcKey) ? orgChildrenByParent[gcKey] : []>

                <cfset var chRoleTitle = (structKeyExists(orgRoleMap, toString(child.ORGID)) ? orgRoleMap[toString(child.ORGID)].roleTitle : '')>
                <cfset var chRoleOrder = (structKeyExists(orgRoleMap, toString(child.ORGID)) ? val(orgRoleMap[toString(child.ORGID)].roleOrder) : 0)>
                <cfset var chAdditionalRoles = (isNumeric(child.ADDITIONALROLES ?: '') AND val(child.ADDITIONALROLES) EQ 1) ? 1 : 0>
                <cfset html &= "<div class='form-check mb-1 d-flex align-items-center gap-1'>">
                <cfset html &= "<input class='form-check-input flex-shrink-0 org-checkbox' type='checkbox' name='Organizations' value='#child.ORGID#' id='org#child.ORGID#' data-orgid='#child.ORGID#' data-orgname='#EncodeForHTMLAttribute(child.ORGNAME)#' data-parentorgid='#ro.ORGID#' data-additionalroles='#chAdditionalRoles#' #(isChildChecked ? 'checked' : '')#>">
                <cfset html &= "<label class='form-check-label user-select-none' for='org#child.ORGID#'>#EncodeForHTML(child.ORGNAME)#</label>">
                <cfif chAdditionalRoles>
                    <cfset html &= "<button type='button' class='org-role-edit btn btn-link p-0 ms-1 text-secondary' data-orgid='#child.ORGID#' data-orgname='#EncodeForHTMLAttribute(child.ORGNAME)#' title='Edit role' style='display:#(isChildChecked ? 'inline-flex' : 'none')#;font-size:13px;line-height:1;'><i class='bi bi-pencil-square'></i></button>">
                </cfif>
                <cfif isChildChecked>
                    <cfset html &= "<input type='hidden' name='roleTitle_#child.ORGID#' id='roleTitle_#child.ORGID#' value='#EncodeForHTMLAttribute(chRoleTitle)#'><input type='hidden' name='roleOrder_#child.ORGID#' id='roleOrder_#child.ORGID#' value='#chRoleOrder#'>">
                </cfif>
                <cfset html &= "</div>">

                <cfloop from="1" to="#arrayLen(grandchildren)#" index="k">
                    <cfset gc = grandchildren[k]>
                    <cfset isGcChecked = arrayFindNoCase(arguments.selectedOrgIDs, val(gc.ORGID)) GT 0>
                    <cfset var gcRoleTitle = (structKeyExists(orgRoleMap, toString(gc.ORGID)) ? orgRoleMap[toString(gc.ORGID)].roleTitle : '')>
                    <cfset var gcRoleOrder = (structKeyExists(orgRoleMap, toString(gc.ORGID)) ? val(orgRoleMap[toString(gc.ORGID)].roleOrder) : 0)>
                    <cfset var gcAdditionalRoles = (isNumeric(gc.ADDITIONALROLES ?: '') AND val(gc.ADDITIONALROLES) EQ 1) ? 1 : 0>
                    <cfset html &= "<div class='form-check mb-1 ms-3 d-flex align-items-center gap-1'>">
                    <cfset html &= "<input class='form-check-input flex-shrink-0 org-checkbox' type='checkbox' name='Organizations' value='#gc.ORGID#' id='org#gc.ORGID#' data-orgid='#gc.ORGID#' data-orgname='#EncodeForHTMLAttribute(gc.ORGNAME)#' data-parentorgid='#child.ORGID#' data-additionalroles='#gcAdditionalRoles#' #(isGcChecked ? 'checked' : '')#>">
                    <cfset html &= "<label class='form-check-label user-select-none small text-muted' for='org#gc.ORGID#'>#EncodeForHTML(gc.ORGNAME)#</label>">
                    <cfif gcAdditionalRoles>
                        <cfset html &= "<button type='button' class='org-role-edit btn btn-link p-0 ms-1 text-secondary' data-orgid='#gc.ORGID#' data-orgname='#EncodeForHTMLAttribute(gc.ORGNAME)#' title='Edit role' style='display:#(isGcChecked ? 'inline-flex' : 'none')#;font-size:13px;line-height:1;'><i class='bi bi-pencil-square'></i></button>">
                    </cfif>
                    <cfif isGcChecked>
                        <cfset html &= "<input type='hidden' name='roleTitle_#gc.ORGID#' id='roleTitle_#gc.ORGID#' value='#EncodeForHTMLAttribute(gcRoleTitle)#'><input type='hidden' name='roleOrder_#gc.ORGID#' id='roleOrder_#gc.ORGID#' value='#gcRoleOrder#'>">
                    </cfif>
                    <cfset html &= "</div>">
                </cfloop>
            </cfloop>

            <cfset html &= "</div></div>">
        </cfif>

        <cfset html &= "</div></div>">
    </cfloop>

    <cfset html &= "</div>">
    <cfreturn html>
</cffunction>

<!--- ── Data Quality Exclusions ── --->
<cfset dqDAO            = createObject("component", "dir.dao.dataQuality_DAO").init()>
<cfset dqExclusionsList = dqDAO.getExclusionsForUser(url.userID)>
<cfset dqExclusionMap   = {}>
<cfloop from="1" to="#arrayLen(dqExclusionsList)#" index="i">
    <cfset dqExclusionMap[dqExclusionsList[i]] = true>
</cfloop>

<cfset dqAllCodes = [
    { code="missing_uh_api_id",       label="Missing UH API ID" },
    { code="missing_firstname",        label="Missing First Name" },
    { code="missing_lastname",         label="Missing Last Name" },
    { code="missing_email_primary",    label="Missing Primary Email" },
    { code="missing_email_secondary",  label="Missing Secondary Email" },
    { code="missing_title1",           label="Missing Title" },
    { code="missing_room",             label="Missing Room" },
    { code="missing_building",         label="Missing Building" },
    { code="missing_phone",            label="Missing Phone" },
    { code="missing_degrees",          label="Missing Degrees" },
    { code="no_flags",                 label="Zero Flags" },
    { code="no_orgs",                  label="Zero Organizations" },
    { code="no_images",                label="No Images" },
    { code="missing_cougarnet",        label="Missing CougarNet ID" },
    { code="missing_peoplesoft",       label="Missing PeopleSoft ID" },
    { code="missing_legacy_id",        label="Missing Legacy ID" },
    { code="missing_grad_year",        label="Missing Grad Year (Students Only)" }
]>

<cfset returnTo = structKeyExists(url, "returnTo") AND len(trim(url.returnTo)) ? trim(url.returnTo) : (len(trim(cgi.HTTP_REFERER)) ? trim(cgi.HTTP_REFERER) : "/dir/admin/users/index.cfm")>

<!--- ── UH Sync pending diffs for this user ── --->
<cfset uhSyncPendingDiffs = []>
<cfset uhSyncPanelHtml    = "">
<cftry>
    <cfset uhSyncDAO_edit = createObject("component", "dir.dao.uhSync_DAO").init()>
    <cfset uhSyncPendingDiffs = uhSyncDAO_edit.getUnresolvedDiffsForUser(val(url.userID))>
<cfcatch>
    <!--- Non-fatal: sync panel is suppressed if tables don't exist yet --->
</cfcatch>
</cftry>

<cfif arrayLen(uhSyncPendingDiffs) GT 0>
    <cfset uhSyncFieldLabels_edit = {
        "FirstName"              : "First Name",
        "LastName"               : "Last Name",
        "EmailPrimary"           : "Primary Email",
        "Phone"                  : "Phone",
        "Room"                   : "Room",
        "Building"               : "Building",
        "Title1"                 : "Title",
        "Division"               : "Division",
        "DivisionName"           : "Division Name",
        "Campus"                 : "Campus",
        "Department"             : "Department",
        "DepartmentName"         : "Department Name",
        "Office_Mailing_Address" : "Office Mailing Address",
        "Mailcode"               : "Mailcode"
    }>
    <cfset editReturnTo = "/dir/admin/users/edit.cfm?userID=" & urlEncodedFormat(url.userID)>

    <cfset uhSyncPanelHtml = "
    <div class='alert alert-warning border-warning mb-4 p-0'>
        <div class='d-flex align-items-center justify-content-between px-3 pt-3 pb-2 border-bottom'>
            <div>
                <i class='bi bi-arrow-left-right me-2 text-warning'></i>
                <strong>#arrayLen(uhSyncPendingDiffs)# UH Sync difference(s) detected</strong>
                <span class='text-muted small ms-2'>from the last sync report run</span>
            </div>
            <div class='d-flex gap-2'>
                <a href='/dir/admin/reporting/uh_sync_report.cfm' class='btn btn-sm btn-outline-secondary py-0'>
                    <i class='bi bi-clipboard-data'></i> View Full Report
                </a>
                <button class='btn btn-sm btn-outline-warning py-0' type='button'
                        data-bs-toggle='collapse' data-bs-target='##uhSyncDiffPanel'>
                    <i class='bi bi-chevron-down'></i> Details
                </button>
            </div>
        </div>
        <div class='collapse show' id='uhSyncDiffPanel'>
            <div class='px-3 py-2'>
                <table class='table table-sm table-bordered mb-2'>
                    <thead class='table-light'>
                        <tr>
                            <th style='width:20%'>Field</th>
                            <th style='width:32%'>Local Value</th>
                            <th style='width:32%'>API Value</th>
                            <th class='text-end' style='width:16%'>Actions</th>
                        </tr>
                    </thead>
                    <tbody>
    ">
    <cfloop from="1" to="#arrayLen(uhSyncPendingDiffs)#" index="dIdx">
        <cfset pd     = uhSyncPendingDiffs[dIdx]>
        <cfset pdLbl  = structKeyExists(uhSyncFieldLabels_edit, pd.FIELDNAME) ? uhSyncFieldLabels_edit[pd.FIELDNAME] : pd.FIELDNAME>
        <cfset uhSyncPanelHtml &= "
                        <tr>
                            <td class='fw-semibold small'>#EncodeForHTML(pdLbl)#</td>
                            <td class='text-muted small'>#(len(trim(pd.LOCALVALUE)) ? EncodeForHTML(pd.LOCALVALUE) : '<em>empty</em>')#</td>
                            <td class='small'><strong>#EncodeForHTML(pd.APIVALUE)#</strong></td>
                            <td class='text-end text-nowrap'>
                                <form method='post' action='/dir/admin/users/resolve_uh_sync_diff.cfm' class='d-inline'>
                                    <input type='hidden' name='diffID'     value='#pd.DIFFID#'>
                                    <input type='hidden' name='resolution' value='synced'>
                                    <input type='hidden' name='returnTo'   value='#EncodeForHTMLAttribute(editReturnTo)#'>
                                    <button type='submit' class='btn btn-xs btn-sm btn-success py-0 px-2'>
                                        <i class='bi bi-cloud-download'></i> Sync
                                    </button>
                                </form>
                                <form method='post' action='/dir/admin/users/resolve_uh_sync_diff.cfm' class='d-inline ms-1'>
                                    <input type='hidden' name='diffID'     value='#pd.DIFFID#'>
                                    <input type='hidden' name='resolution' value='discarded'>
                                    <input type='hidden' name='returnTo'   value='#EncodeForHTMLAttribute(editReturnTo)#'>
                                    <button type='submit' class='btn btn-xs btn-sm btn-outline-secondary py-0 px-2'>
                                        <i class='bi bi-x'></i> Discard
                                    </button>
                                </form>
                            </td>
                        </tr>
        ">
    </cfloop>
    <cfset uhSyncSyncAllBtn = "">
    <cfif len(trim(user.UH_API_ID ?: ""))>
        <cfset uhSyncSyncAllBtn = "<a href='/dir/admin/users/uh_sync.cfm?userID=#urlEncodedFormat(url.userID)#&returnTo=#urlEncodedFormat(editReturnTo)#' class='btn btn-sm btn-success'><i class='bi bi-cloud-download me-1'></i>Sync All Fields from UH API</a>">
    </cfif>
    <cfset uhSyncPanelHtml &= "
                    </tbody>
                </table>
                <div class='d-flex gap-2 pb-1'>
                    #uhSyncSyncAllBtn#
                </div>
            </div>
        </div>
    </div>
    ">
</cfif>

<cfset content = "
<h1>Edit User</h1>
" & uhSyncPanelHtml & "


<form class='mt-4' method='POST' action='/dir/admin/users/saveUser.cfm'>
    <input type='hidden' name='UserID' value='#user.USERID#'>
    <input type='hidden' name='returnTo' value='#EncodeForHTMLAttribute(returnTo)#'>
    <input type='hidden' name='processOrganizations' value='1'>
    <input type='hidden' name='processExternalIDs' value='1'>
    <input type='hidden' name='processAcademicInfo' value='1'>
    " & (showStudentProfile ? "<input type='hidden' name='processStudentProfile' value='1'>" : "") & "

    <ul class='nav nav-tabs mb-3' id='editTabs' role='tablist'>
        <li class='nav-item' role='presentation'>
            <button class='nav-link active' id='general-tab' data-bs-toggle='tab' data-bs-target='##general-pane' type='button' role='tab' aria-controls='general-pane' aria-selected='true'>General Information</button>
        </li>
        <li class='nav-item' role='presentation'>
            <button class='nav-link' id='flags-tab' data-bs-toggle='tab' data-bs-target='##flags-pane' type='button' role='tab' aria-controls='flags-pane' aria-selected='false'>Flags</button>
        </li>
        <li class='nav-item' role='presentation'>
            <button class='nav-link' id='orgs-tab' data-bs-toggle='tab' data-bs-target='##orgs-pane' type='button' role='tab' aria-controls='orgs-pane' aria-selected='false'>Organizations</button>
        </li>
        <li class='nav-item' role='presentation'>
            <button class='nav-link' id='extids-tab' data-bs-toggle='tab' data-bs-target='##extids-pane' type='button' role='tab' aria-controls='extids-pane' aria-selected='false'>External IDs</button>
        </li>
        <li class='nav-item' role='presentation'>
            <button class='nav-link' id='address-tab' data-bs-toggle='tab' data-bs-target='##address-pane' type='button' role='tab' aria-controls='address-pane' aria-selected='false'>Address</button>
        </li>
        <li class='nav-item#(showStudentProfile ? "" : " d-none")#' id='student-profile-tab-li' role='presentation'>
            <button class='nav-link' id='student-profile-tab' data-bs-toggle='tab' data-bs-target='##student-profile-pane' type='button' role='tab' aria-controls='student-profile-pane' aria-selected='false'>Student Profile</button>
        </li>
        <li class='nav-item#(showGradYear ? "" : " d-none")#' id='academic-tab-li' role='presentation'>
            <button class='nav-link' id='academic-tab' data-bs-toggle='tab' data-bs-target='##academic-pane' type='button' role='tab' aria-controls='academic-pane' aria-selected='false'>Academic Info</button>
        </li>
    </ul>

    <div class='tab-content' id='editTabsContent'>

        <div class='tab-pane fade show active' id='general-pane' role='tabpanel' aria-labelledby='general-tab'>
            <div class='row mb-3'>
                <div class='col-md-4'>
                    <label class='form-label'>Prefix</label>
                    <input class='form-control' name='Prefix' value='#(user.PREFIX ?: "")#'>
                </div>
                <div class='col-md-4'>
                    <label class='form-label'>Suffix</label>
                    <input class='form-control' name='Suffix' value='#(user.SUFFIX ?: "")#'>
                </div>
            </div>
            <div class='row mb-3'>
                <div class='col-md-4'>
                    <label class='form-label'>First Name</label>
                    <input class='form-control' name='FirstName' value='#user.FIRSTNAME#' required>
                </div>
                <div class='col-md-4'>
                    <label class='form-label'>Middle Name</label>
                    <input class='form-control' name='MiddleName' value='#user.MIDDLENAME#'>
                </div>
                <div class='col-md-4'>
                    <label class='form-label'>Last Name</label>
                    <input class='form-control' name='LastName' value='#user.LASTNAME#' required>
                </div>
            </div>

            <div class='row mb-3'>
                <div class='col-md-4'>
                    <label class='form-label'>Maiden Name</label>
                    <input class='form-control' name='MaidenName' value='#user.MAIDENNAME#'>
                </div>
                <div class='col-md-4'>
                    <label class='form-label'>Preferred Name</label>
                    <input class='form-control' name='PreferredName' value='#user.PREFERREDNAME#'>
                </div>
                <div class='col-md-4'>
                    <label class='form-label'>Degrees</label>
                    <input class='form-control' name='Degrees' value='#(user.DEGREES ?: "")#'>
                </div>
            </div>

            <div class='row mb-3'>
                <div class='col-md-6'>
                    <label class='form-label'>Email (@uh)</label>
                    <input class='form-control' id='emailPrimary' name='EmailPrimary' value='#user.EMAILPRIMARY#' type='email'>
                    <div class='invalid-feedback' id='emailPrimaryErr'></div>
                </div>
                <div class='col-md-6'>
                    <label class='form-label'>Email (@central/@cougarnet)</label>
                    <input class='form-control' id='emailSecondary' name='EmailSecondary' value='#user.EMAILSECONDARY#' type='email'>
                    <div class='invalid-feedback' id='emailSecondaryErr'></div>
                </div>
            </div>

            <div class='row mb-3'>
                <div class='col-md-6'>
                    <label class='form-label'>Phone</label>
                    <input class='form-control' name='Phone' value='#user.PHONE#'>
                </div>
                <div class='col-md-6'>
                    <label class='form-label'>UH API ID</label>
                    <input class='form-control' name='UH_API_ID' value='#user.UH_API_ID#'>
                </div>
            </div>

            <div class='row mb-3'>
                <div class='col-md-4'>
                    <label class='form-label'>Title 1</label>
                    <input class='form-control' name='Title1' value='#user.TITLE1#'>
                </div>
                <div class='col-md-4'>
                    <label class='form-label'>Title 2</label>
                    <input class='form-control' name='Title2' value='#user.TITLE2#'>
                </div>
                <div class='col-md-4'>
                    <label class='form-label'>Title 3</label>
                    <input class='form-control' name='Title3' value='#user.TITLE3#'>
                </div>
            </div>

            <div class='row mb-3'>
                <div class='col-md-4'>
                    <label class='form-label'>Pronouns</label>
                    <input class='form-control' name='Pronouns' value='#(user.PRONOUNS ?: "")#'>
                </div>
            </div>
        </div>

        <div class='tab-pane fade' id='flags-pane' role='tabpanel' aria-labelledby='flags-tab'>
            <div class='border p-3 rounded' style='max-height: 400px; overflow-y: auto;'>
" />

<cfif arrayLen(allFlags) gt 0>
    <cfloop from="1" to="#arrayLen(allFlags)#" index="i">
        <cfset flag = allFlags[i]>
        <cfset isChecked = arrayFindNoCase(userFlagIDs, flag.FLAGID) gt 0>
        <cfset content &= "
            <div class='form-check form-check-inline'>
                <input class='form-check-input' type='checkbox' name='Flags' value='#flag.FLAGID#' id='flag#flag.FLAGID#' " & (isChecked ? "checked" : "") & ">
                <label class='form-check-label' for='flag#flag.FLAGID#'>
                    #flag.FLAGNAME#
                </label>
            </div>
        ">
    </cfloop>
<cfelse>
    <cfset content &= "<p class='text-muted'>No flags available</p>">
</cfif>

<cfset content &= "
            </div>
        </div>

        <div class='tab-pane fade' id='orgs-pane' role='tabpanel' aria-labelledby='orgs-tab'>
            <style>.org-chevron{transition:transform .2s;}.org-chevron[aria-expanded='true']{transform:rotate(180deg);}</style>
" />

<cfset content &= renderOrgPanels(userOrgIDs)>

<cfset content &= "
        </div>

        <div class='tab-pane fade' id='extids-pane' role='tabpanel' aria-labelledby='extids-tab'>
            #extIDHtml#
        </div>

        <div class='tab-pane fade' id='address-pane' role='tabpanel' aria-labelledby='address-tab'>
            <div class='row mb-3'>
                <div class='col-md-4'>
                    <label class='form-label'>Room</label>
                    <input class='form-control' name='Room' value='#(user.ROOM ?: "")#'>
                </div>
                <div class='col-md-4'>
                    <label class='form-label'>Building</label>
                    <input class='form-control' name='Building' value='#(user.BUILDING ?: "")#'>
                </div>
            </div>
            <div class='row mb-3'>
                <div class='col-md-4'>
                    <label class='form-label'>Campus</label>
                    <input class='form-control' name='Campus' value='#(user.CAMPUS ?: "")#'>
                </div>
                <div class='col-md-4'>
                    <label class='form-label'>Division</label>
                    <input class='form-control' name='Division' value='#(user.DIVISION ?: "")#'>
                </div>
                <div class='col-md-4'>
                    <label class='form-label'>Division Name</label>
                    <input class='form-control' name='DivisionName' value='#(user.DIVISIONNAME ?: "")#'>
                </div>
            </div>
            <div class='row mb-3'>
                <div class='col-md-4'>
                    <label class='form-label'>Department</label>
                    <input class='form-control' name='Department' value='#(user.DEPARTMENT ?: "")#'>
                </div>
                <div class='col-md-4'>
                    <label class='form-label'>Department Name</label>
                    <input class='form-control' name='DepartmentName' value='#(user.DEPARTMENTNAME ?: "")#'>
                </div>
                <div class='col-md-4'></div>
            </div>
            <div class='row mb-3'>
                <div class='col-md-8'>
                    <label class='form-label'>Office Mailing Address</label>
                    <input class='form-control' name='Office_Mailing_Address' value='#(user.OFFICE_MAILING_ADDRESS ?: "")#'>
                </div>
                <div class='col-md-4'>
                    <label class='form-label'>Mailcode</label>
                    <input class='form-control' name='Mailcode' value='#(user.MAILCODE ?: "")#'>
                </div>
            </div>
        </div>

        <div class='tab-pane fade' id='academic-pane' role='tabpanel' aria-labelledby='academic-tab'>
            <div class='row mb-3'>
                <div class='col-md-6'>
                    <label class='form-label'>Current Grad Year</label>
                    <input class='form-control' name='CurrentGradYear' id='currentGradYear' value='#currentGradYear#' placeholder='e.g. 2028'>
                </div>
                <div class='col-md-6'>
                    <label class='form-label'>Original Grad Year</label>
                    <input class='form-control' name='OriginalGradYear' id='originalGradYear' value='#originalGradYear#' placeholder='e.g. 2027' #(len(currentGradYear) ? '' : 'disabled')#>
                    <div class='form-text'>Requires a Current Grad Year.</div>
                </div>
            </div>
        </div>">

<!--- ── Student Profile pane ── --->
<cfset content &= "<div class='tab-pane fade' id='student-profile-pane' role='tabpanel' aria-labelledby='student-profile-tab'>">
<cfif showStudentProfile>
    <cfset content &= "
        <div class='row mb-3'>
            <div class='col-md-4'>
                <label class='form-label'>Hometown</label>
                <input class='form-control' name='sp_hometown' value='#EncodeForHTMLAttribute(spHometown)#'>
            </div>
        </div>
        <div class='row mb-3'>
            <div class='col-md-6'>
                <label class='form-label'>First Externship</label>
                <input class='form-control' name='sp_first_externship' value='#EncodeForHTMLAttribute(spFirstExt)#'>
            </div>
            <div class='col-md-6'>
                <label class='form-label'>Second Externship</label>
                <input class='form-control' name='sp_second_externship' value='#EncodeForHTMLAttribute(spSecondExt)#'>
            </div>
        </div>
        <div class='mb-4'>
            <label class='form-label fw-semibold'>Awards</label>
            <div id='awardsContainer'>
    ">
    <cfloop from="1" to="#arrayLen(spAwards)#" index="ai">
        <cfset aw = spAwards[ai]>
        <cfset content &= "<div class='row g-2 mb-2 award-row'>
                <div class='col-md-5'><input class='form-control form-control-sm' name='award_name_#(ai-1)#' data-field='name' value='#EncodeForHTMLAttribute(aw.AWARDNAME)#' placeholder='Award Name'></div>
                <div class='col-md-5'><input class='form-control form-control-sm' name='award_type_#(ai-1)#' data-field='type' value='#EncodeForHTMLAttribute(aw.AWARDTYPE)#' placeholder='Award Type'></div>
                <div class='col-md-2'><button type='button' class='btn btn-sm btn-outline-danger remove-award-row w-100'>Remove</button></div>
            </div>">
    </cfloop>
    <cfset content &= "
            </div>
            <input type='hidden' name='award_count' id='awardCount' value='#arrayLen(spAwards)#'>
            <button type='button' class='btn btn-sm btn-outline-primary mt-2' id='addAwardRow'>+ Add Award</button>
        </div>
    ">
</cfif>
<cfset content &= "</div>">

<cfset content &= "
    </div>

    
    <div class='mt-3'>
    " & (user.UH_API_ID != "" ? "<a href='/dir/admin/users/uh_sync.cfm?userID=#urlEncodedFormat(user.USERID)#&uhApiId=#urlEncodedFormat(user.UH_API_ID)#' class='btn btn-info me-2'>UH Sync</a>" : "") & "
    
        <button class='btn btn-primary'>Update User</button>
        <a href='/dir/admin/users/index.cfm' class='btn btn-secondary'>Cancel</a>
    </div>

</form>

    <script>
    (function () {
        var epEl  = document.getElementById('emailPrimary');
        var esEl  = document.getElementById('emailSecondary');
        var epErr = document.getElementById('emailPrimaryErr');
        var esErr = document.getElementById('emailSecondaryErr');
        function showError(el, errEl, msg) { el.classList.add('is-invalid'); errEl.textContent = msg; }
        function clearError(el, errEl)     { el.classList.remove('is-invalid'); errEl.textContent = ''; }
        function validatePrimary() {
            var val = (epEl ? epEl.value : '').trim().toLowerCase();
            if (val && !val.endsWith('@uh.edu')) {
                showError(epEl, epErr, 'Must be a @uh.edu address (e.g. jsmith@uh.edu).');
                return false;
            }
            if (epEl) clearError(epEl, epErr);
            return true;
        }
        function validateSecondary() {
            var val = (esEl ? esEl.value : '').trim().toLowerCase();
            if (val && !val.endsWith('@cougarnet.uh.edu') && !val.endsWith('@central.uh.edu')) {
                showError(esEl, esErr, 'Must be a @cougarnet.uh.edu or @central.uh.edu address.');
                return false;
            }
            if (esEl) clearError(esEl, esErr);
            return true;
        }
        if (epEl) epEl.addEventListener('blur', validatePrimary);
        if (esEl) esEl.addEventListener('blur', validateSecondary);
        var form = epEl ? epEl.closest('form') : null;
        if (form) {
            form.addEventListener('submit', function (e) {
                var ok = validatePrimary() & validateSecondary();
                if (!ok) { e.preventDefault(); var inv = document.querySelector('.is-invalid'); if (inv) inv.focus(); }
            });
        }
    })();
    </script>

    <script>
    document.addEventListener('DOMContentLoaded', function () {
        var orgCheckboxes = Array.prototype.slice.call(document.querySelectorAll('input.org-checkbox'));
        if (!orgCheckboxes.length) return;

        var byOrgId = {};
        var childrenByParent = {};

        orgCheckboxes.forEach(function (cb) {
            var orgId    = cb.getAttribute('data-orgid')       || '';
            var parentId = cb.getAttribute('data-parentorgid') || '';
            byOrgId[orgId] = cb;
            if (!childrenByParent[parentId]) childrenByParent[parentId] = [];
            childrenByParent[parentId].push(cb);
        });

        // ── Ancestor cascade helpers ──────────────────────────────────────
        function checkAncestors(cb) {
            var parentId = cb.getAttribute('data-parentorgid') || '';
            while (parentId && byOrgId[parentId]) {
                byOrgId[parentId].checked = true;
                parentId = byOrgId[parentId].getAttribute('data-parentorgid') || '';
            }
        }

        function hasAnyCheckedDescendant(orgId) {
            var stack = (childrenByParent[orgId] || []).slice();
            while (stack.length) {
                var child = stack.pop();
                if (child.checked) return true;
                var grandChildren = childrenByParent[child.getAttribute('data-orgid') || ''] || [];
                for (var i = 0; i < grandChildren.length; i++) stack.push(grandChildren[i]);
            }
            return false;
        }

        function uncheckAncestorsIfNoCheckedChildren(cb) {
            var parentId = cb.getAttribute('data-parentorgid') || '';
            while (parentId && byOrgId[parentId]) {
                if (!hasAnyCheckedDescendant(parentId)) byOrgId[parentId].checked = false;
                parentId = byOrgId[parentId].getAttribute('data-parentorgid') || '';
            }
        }

        // ── Role modal ────────────────────────────────────────────────────
        var modalEl      = document.getElementById('orgRoleModal');
        var bsModal      = new bootstrap.Modal(modalEl);
        var modalOrgName = document.getElementById('orgRoleModalOrgName');
        var modalTitle   = document.getElementById('modalRoleTitle');
        var modalOrder   = document.getElementById('modalRoleOrder');
        var modalSaveBtn = document.getElementById('orgRoleModalSave');
        var pendingCheckbox = null;   // set when modal opened by a new check

        function getEditBtn(orgId) {
            var cb = byOrgId[orgId];
            return cb ? cb.parentNode.querySelector('.org-role-edit') : null;
        }

        function setOrgRole(orgId, roleTitle, roleOrder) {
            var tEl = document.getElementById('roleTitle_' + orgId);
            var oEl = document.getElementById('roleOrder_' + orgId);
            var cb  = byOrgId[orgId];
            if (!tEl) {
                tEl = document.createElement('input');
                tEl.type = 'hidden'; tEl.name = 'roleTitle_' + orgId; tEl.id = 'roleTitle_' + orgId;
                if (cb) cb.parentNode.appendChild(tEl);
            }
            if (!oEl) {
                oEl = document.createElement('input');
                oEl.type = 'hidden'; oEl.name = 'roleOrder_' + orgId; oEl.id = 'roleOrder_' + orgId;
                if (cb) cb.parentNode.appendChild(oEl);
            }
            tEl.value = roleTitle;
            oEl.value = roleOrder;
        }

        function removeOrgRole(orgId) {
            ['roleTitle_', 'roleOrder_'].forEach(function (prefix) {
                var el = document.getElementById(prefix + orgId);
                if (el) el.remove();
            });
        }

        function openRoleModal(cb) {
            var orgId   = cb.getAttribute('data-orgid');
            var orgName = cb.getAttribute('data-orgname');
            var tEl     = document.getElementById('roleTitle_' + orgId);
            var oEl     = document.getElementById('roleOrder_' + orgId);
            modalOrgName.textContent = orgName;
            modalTitle.value = tEl ? tEl.value : '';
            modalOrder.value = oEl ? oEl.value : '';
            modalEl.setAttribute('data-current-orgid', orgId);
            bsModal.show();
        }

        modalSaveBtn.addEventListener('click', function () {
            var orgId = modalEl.getAttribute('data-current-orgid');
            setOrgRole(orgId, modalTitle.value.trim(), modalOrder.value.trim());
            var btn = getEditBtn(orgId);
            if (btn) btn.style.display = 'inline-flex';
            pendingCheckbox = null;
            bsModal.hide();
        });

        // Cancel / backdrop: if triggered by a new check, undo it
        modalEl.addEventListener('hidden.bs.modal', function () {
            if (pendingCheckbox) {
                var orgId = pendingCheckbox.getAttribute('data-orgid');
                pendingCheckbox.checked = false;
                uncheckAncestorsIfNoCheckedChildren(pendingCheckbox);
                orgCheckboxes.forEach(function (c) {
                    var btn = getEditBtn(c.getAttribute('data-orgid'));
                    if (btn) btn.style.display = c.checked ? 'inline-flex' : 'none';
                });
                removeOrgRole(orgId);
                pendingCheckbox = null;
            }
        });

        // Edit button click (existing assignments)
        document.querySelectorAll('.org-role-edit').forEach(function (btn) {
            btn.addEventListener('click', function (e) {
                e.preventDefault();
                var orgId = btn.getAttribute('data-orgid');
                var cb = byOrgId[orgId];
                if (!cb) return;
                pendingCheckbox = null;
                openRoleModal(cb);
            });
        });

        // ── Wire up checkboxes ────────────────────────────────────────────
        orgCheckboxes.forEach(function (cb) {
            if (cb.checked) checkAncestors(cb);

            cb.addEventListener('change', function () {
                var isParent = cb.getAttribute('data-isparent') === '1';
                var hasRoles = cb.getAttribute('data-additionalroles') === '1';
                if (cb.checked) {
                    checkAncestors(cb);
                    if (!isParent && hasRoles) {
                        pendingCheckbox = cb;
                        openRoleModal(cb);
                    }
                } else {
                    uncheckAncestorsIfNoCheckedChildren(cb);
                    if (!isParent && hasRoles) {
                        var orgId = cb.getAttribute('data-orgid');
                        var btn = getEditBtn(orgId);
                        if (btn) btn.style.display = 'none';
                        removeOrgRole(orgId);
                    }
                }
            });
        });

        // Expand card panel when parent org checkbox is checked
        orgCheckboxes.forEach(function (cb) {
            var panelId = cb.getAttribute('data-panelid');
            if (!panelId) return;
            cb.addEventListener('change', function () {
                if (cb.checked) {
                    var el = document.getElementById(panelId);
                    if (el) bootstrap.Collapse.getOrCreateInstance(el, { toggle: false }).show();
                }
            });
        });
    });
    </script>

    <script>
    (function () {
        var gradYearFlagIDs = [#arrayToList(gradYearFlagIDs)#];
        var tabLi  = document.getElementById('academic-tab-li');
        var tabBtn = document.getElementById('academic-tab');
        var curr   = document.getElementById('currentGradYear');
        var orig   = document.getElementById('originalGradYear');

        function syncOriginal() {
            if (!curr || !orig) return;
            var hasValue = curr.value.trim().length > 0;
            orig.disabled = !hasValue;
            if (!hasValue) orig.value = '';
        }

        function isAnyGradFlagChecked() {
            return gradYearFlagIDs.some(function (id) {
                var cb = document.querySelector('input[name=""Flags""][value=""' + id + '""]');
                return cb && cb.checked;
            });
        }

        function syncTabVisibility() {
            if (!tabLi) return;
            if (isAnyGradFlagChecked()) {
                tabLi.classList.remove('d-none');
            } else {
                tabLi.classList.add('d-none');
                if (curr) curr.value = '';
                if (orig) { orig.value = ''; orig.disabled = true; }
                if (tabBtn && tabBtn.classList.contains('active')) {
                    var generalTab = document.getElementById('general-tab');
                    if (generalTab) generalTab.click();
                }
            }
        }

        if (curr) curr.addEventListener('input', syncOriginal);

        gradYearFlagIDs.forEach(function (id) {
            var cb = document.querySelector('input[name=""Flags""][value=""' + id + '""]');
            if (cb) cb.addEventListener('change', syncTabVisibility);
        });
    })();
    </script>
</form>

<div class='modal fade' id='orgRoleModal' tabindex='-1' aria-labelledby='orgRoleModalLabel' aria-hidden='true'>
    <div class='modal-dialog modal-sm'>
        <div class='modal-content'>
            <div class='modal-header py-2'>
                <h6 class='modal-title fw-semibold mb-0' id='orgRoleModalLabel'>
                    <i class='bi bi-pencil-square me-1 text-primary'></i>
                    <span id='orgRoleModalOrgName'></span>
                </h6>
                <button type='button' class='btn-close' data-bs-dismiss='modal' aria-label='Close'></button>
            </div>
            <div class='modal-body'>
                <div class='mb-3'>
                    <label class='form-label fw-semibold' for='modalRoleTitle'>Role Title</label>
                    <input type='text' class='form-control' id='modalRoleTitle' placeholder='e.g. Program Director'>
                    <div class='form-text'>Optional. Describe this person's role within the organization.</div>
                </div>
                <div class='mb-1'>
                    <label class='form-label fw-semibold' for='modalRoleOrder'>Display Order</label>
                    <input type='number' class='form-control' id='modalRoleOrder' placeholder='e.g. 1' min='0'>
                    <div class='form-text'>Optional. Lower numbers appear first in listings.</div>
                </div>
            </div>
            <div class='modal-footer py-2'>
                <button type='button' class='btn btn-sm btn-secondary' data-bs-dismiss='modal'>Cancel</button>
                <button type='button' class='btn btn-sm btn-primary' id='orgRoleModalSave'>Save Role</button>
            </div>
        </div>
    </div>
</div>

    <script>
    document.addEventListener('DOMContentLoaded', function () {
        var container  = document.getElementById('awardsContainer');
        var countInput = document.getElementById('awardCount');
        if (!container || !countInput) return;

        function reindex() {
            var rows = container.querySelectorAll('.award-row');
            rows.forEach(function (row, idx) {
                var n = row.querySelector('[data-field=name]');
                var t = row.querySelector('[data-field=type]');
                if (n) n.name = 'award_name_' + idx;
                if (t) t.name = 'award_type_' + idx;
            });
            countInput.value = rows.length;
        }

        function makeRemovable(btn) {
            btn.addEventListener('click', function () {
                this.closest('.award-row').remove();
                reindex();
            });
        }

        container.querySelectorAll('.remove-award-row').forEach(makeRemovable);

        var addBtn = document.getElementById('addAwardRow');
        if (addBtn) {
            addBtn.addEventListener('click', function () {
                var idx = parseInt(countInput.value, 10);
                var row = document.createElement('div');
                row.className = 'row g-2 mb-2 award-row';
                var c1 = document.createElement('div'); c1.className = 'col-md-5';
                var n  = document.createElement('input');
                n.className = 'form-control form-control-sm';
                n.name = 'award_name_' + idx;
                n.setAttribute('data-field', 'name');
                n.placeholder = 'Award Name';
                c1.appendChild(n);
                var c2 = document.createElement('div'); c2.className = 'col-md-5';
                var t  = document.createElement('input');
                t.className = 'form-control form-control-sm';
                t.name = 'award_type_' + idx;
                t.setAttribute('data-field', 'type');
                t.placeholder = 'Award Type';
                c2.appendChild(t);
                var c3  = document.createElement('div'); c3.className = 'col-md-2';
                var btn = document.createElement('button');
                btn.type = 'button';
                btn.className = 'btn btn-sm btn-outline-danger remove-award-row w-100';
                btn.textContent = 'Remove';
                makeRemovable(btn);
                c3.appendChild(btn);
                row.appendChild(c1); row.appendChild(c2); row.appendChild(c3);
                container.appendChild(row);
                countInput.value = idx + 1;
            });
        }
    });
    </script>

    <script>
    (function () {
        var studentFlagIDs = [#arrayToList(studentFlagIDs)#];
        var spTabLi  = document.getElementById('student-profile-tab-li');
        var spTabBtn = document.getElementById('student-profile-tab');

        function isStudentFlagChecked() {
            return studentFlagIDs.some(function (id) {
                var cb = document.querySelector('input[name=""Flags""][value=""' + id + '""]');
                return cb && cb.checked;
            });
        }

        function syncSpTabVisibility() {
            if (!spTabLi) return;
            if (isStudentFlagChecked()) {
                spTabLi.classList.remove('d-none');
            } else {
                spTabLi.classList.add('d-none');
                if (spTabBtn && spTabBtn.classList.contains('active')) {
                    var generalTab = document.getElementById('general-tab');
                    if (generalTab) generalTab.click();
                }
            }
        }

        studentFlagIDs.forEach(function (id) {
            var cb = document.querySelector('input[name=""Flags""][value=""' + id + '""]');
            if (cb) cb.addEventListener('change', syncSpTabVisibility);
        });
    })();
    </script>
"  />

<!--- ── Data Quality Exclusions panel ── --->
<cfsavecontent variable="local.dqPanel">
<cfoutput>
<div class='card mt-4 border-warning'>
    <div class='card-header bg-warning bg-opacity-10 d-flex align-items-center justify-content-between'>
        <strong><i class='bi bi-funnel'></i> Data Quality Report Exclusions</strong>
        <span class='text-muted small'>Checked = included in report &nbsp;|&nbsp; Unchecked = excluded</span>
    </div>
    <div class='card-body'>
        <p class='text-muted small mb-3'>Uncheck any item to exclude this user from that specific data quality check.</p>
        <form method='POST' action='/dir/admin/users/saveDQExclusions.cfm'>
            <input type='hidden' name='UserID'   value='#user.USERID#'>
            <input type='hidden' name='returnTo' value='#EncodeForHTMLAttribute(returnTo)#'>
            <div class='row g-2'>
</cfoutput>
<cfloop array="#dqAllCodes#" item="dqItem">
    <cfset isExcluded = structKeyExists(dqExclusionMap, dqItem.code)>
    <cfoutput>
    <div class='col-sm-6 col-md-4'>
        <div class='form-check'>
            <input class='form-check-input' type='checkbox'
                   name='dqInclude' value='#dqItem.code#'
                   id='dq_#dqItem.code#'
                   #isExcluded ? '' : 'checked'#>
            <label class='form-check-label small' for='dq_#dqItem.code#'>
                #dqItem.label#
            </label>
        </div>
    </div>
    </cfoutput>
</cfloop>
<cfoutput>
            </div>
            <div class='mt-3'>
                <button type='submit' class='btn btn-warning btn-sm'>
                    <i class='bi bi-save'></i> Save Exclusions
                </button>
            </div>
        </form>
    </div>
</div>
</cfoutput>
</cfsavecontent>
<cfset content &= local.dqPanel>

<cfinclude template="/dir/admin/layout.cfm">