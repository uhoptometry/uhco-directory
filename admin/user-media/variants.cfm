<!--- ── Authorization ─────────────────────────────────────────────────────── --->
<cfif NOT (
    application.authService.hasRole("USER_MEDIA_ADMIN")
    OR application.authService.hasRole("SUPER_ADMIN")
)>
    <cflocation url="#request.webRoot#/admin/unauthorized.cfm" addtoken="false">
</cfif>

<!--- ── Validate required URL parameters ─────────────────────────────────── --->
<cfif NOT structKeyExists(url, "userid") OR NOT isNumeric(url.userid) OR val(url.userid) LTE 0>
    <cflocation url="#request.webRoot#/admin/user-media/index.cfm" addtoken="false">
</cfif>
<cfif NOT structKeyExists(url, "sourceid") OR NOT isNumeric(url.sourceid) OR val(url.sourceid) LTE 0>
    <cflocation url="#request.webRoot#/admin/user-media/sources.cfm?userid=#val(url.userid)#" addtoken="false">
</cfif>

<cfset userID   = val(url.userid)>
<cfset sourceID = val(url.sourceid)>

<!--- ── Services (no SQL, no filesystem in this file) ────────────────────── --->
<cfset usersService   = createObject("component", "cfc.users_service").init()>
<cfset variantService = createObject("component", "cfc.UserImageVariantService").init()>
<cfset sourceService  = createObject("component", "cfc.UserImageSourceService").init()>

<!--- ── Load user — stop gracefully if not found ─────────────────────────── --->
<cfset userResult = usersService.getUser(userID)>

<cfif NOT userResult.success>
    <cfset content = "
    <div class='alert alert-danger'>
        User not found. <a href='/admin/user-media/index.cfm'>Return to User Media</a>
    </div>
    ">
    <cfinclude template="/admin/layout.cfm">
    <cfabort>
</cfif>

<cfset user = userResult.data>

<!--- ── Handle POST actions ──────────────────────────────────────────────── --->
<!---
     Generation requires USER_MEDIA_ADMIN or SUPER_ADMIN.
     Authorization is already enforced at the top of this page.
     Individual actions are not silently elevated — no further privilege
     branching is needed because the page gate covers both actions.
--->
<cfset actionMessage      = "">
<cfset actionMessageClass = "alert-success">

<cfif cgi.request_method EQ "POST">
    <cfset action = trim(form.action ?: "")>

    <!--- ── Assign a variant type to this source ─────────────────────── --->
    <cfif action EQ "assign" AND isNumeric(form.imageVariantTypeID ?: "") AND val(form.imageVariantTypeID) GT 0>
        <cfset result = variantService.assignSource(
            userID             = userID,
            imageVariantTypeID = val(form.imageVariantTypeID),
            userImageSourceID  = sourceID
        )>
        <cfset actionMessage      = result.message>
        <cfset actionMessageClass = result.success ? "alert-success" : "alert-danger">

    <!--- ── Generate a single variant ───────────────────────────────── --->
    <cfelseif action EQ "generate" AND isNumeric(form.imageVariantTypeID ?: "") AND val(form.imageVariantTypeID) GT 0>
        <cfset result = variantService.generateVariant(
            userID             = userID,
            imageVariantTypeID = val(form.imageVariantTypeID),
            userImageSourceID  = sourceID
        )>
        <cfset actionMessage      = result.message>
        <cfset actionMessageClass = result.success ? "alert-success" : "alert-danger">

    <!--- ── Publish all current variants ─────────────────────────────── --->
    <cfelseif action EQ "publishAll">
        <cfset publishingService = createObject("component", "cfc.PublishingService").init()>
        <cfset result = publishingService.publishAllVariants(userID, sourceID)>
        <cfset actionMessage      = result.message>
        <cfset actionMessageClass = result.success ? "alert-success" : "alert-danger">

        <!--- Append per-variant details if there are mixed results --->
        <cfif arrayLen(result.results) GT 0 AND NOT result.success>
            <cfloop from="1" to="#arrayLen(result.results)#" index="px">
                <cfset pr = result.results[px]>
                <cfif NOT pr.success>
                    <cfset actionMessage = actionMessage & " | " & pr.message>
                </cfif>
            </cfloop>
        </cfif>

    </cfif>
</cfif>

<!--- ── Load data after any POST so the matrix reflects current state ─────── --->
<cfset sourceRecord = sourceService.getSourceByID(sourceID)>
<cfif structIsEmpty(sourceRecord) OR val(sourceRecord.USERID ?: 0) NEQ userID>
    <cflocation url="#request.webRoot#/admin/user-media/sources.cfm?userid=#userID#" addtoken="false">
</cfif>
<cfset sourceFilename = listLast(sourceRecord.DROPBOXPATH ?: "", "/\")>

<cfset variantMatrix = variantService.getVariantMatrix(userID, sourceID)>

<!--- ── Build display values ─────────────────────────────────────────────── --->
<cfset displayName  = encodeForHTML(trim((user.FIRSTNAME ?: "") & " " & (user.LASTNAME ?: "")))>
<cfset displayEmail = encodeForHTML(user.EMAILPRIMARY ?: "")>

<!--- ═══════════════════════════════════════════════════════════════════════
     Page content — uses cfset content / cfset content &= convention
     matching all other admin pages.
     ═══════════════════════════════════════════════════════════════════════ --->

<!--- ── Breadcrumb + heading ─────────────────────────────────────────────── --->
<cfset content = "
<nav aria-label='breadcrumb' class='mb-3'>
    <ol class='breadcrumb'>
        <li class='breadcrumb-item'><a href='/admin/user-media/index.cfm'>User Media</a></li>
        <li class='breadcrumb-item'><a href='/admin/user-media/sources.cfm?userid=#userID#'>Image Sources</a></li>
        <li class='breadcrumb-item active' aria-current='page'>Image Variants</li>
    </ol>
</nav>
<h1 class='mb-1'>Image Variants</h1>
<p class='text-muted mb-4'>
    Assign variant types to this source, then generate and publish.
    Each source image gets its own independent set of variants.
</p>
">

<!--- ── User context card ────────────────────────────────────────────────── --->
<cfset content &= "
<div class='card mb-4'>
    <div class='card-header fw-semibold'><i class='bi bi-person-circle me-1'></i> User &amp; Source</div>
    <div class='card-body'>
        <dl class='row mb-0'>
            <dt class='col-sm-2'>Name</dt>
            <dd class='col-sm-10'>#displayName#</dd>
            <dt class='col-sm-2'>Email</dt>
            <dd class='col-sm-10'>#displayEmail#</dd>
            <dt class='col-sm-2'>User ID</dt>
            <dd class='col-sm-10'>#userID#</dd>
            <dt class='col-sm-2'>Source</dt>
            <dd class='col-sm-10'>
                <span class='badge bg-primary me-1'>#encodeForHTML(sourceRecord.SOURCEKEY ?: "")#</span>
                <code>#encodeForHTML(sourceFilename)#</code>
                <span class='text-muted small ms-2'>(Source ID: #sourceID#)</span>
            </dd>
        </dl>
    </div>
</div>
">

<!--- ── Action feedback ──────────────────────────────────────────────────── --->
<cfif len(actionMessage)>
    <cfset content &= "
    <div class='alert #actionMessageClass# alert-dismissible fade show' role='alert'>
        #encodeForHTML(actionMessage)#
        <button type='button' class='btn-close' data-bs-dismiss='alert' aria-label='Close'></button>
    </div>
    ">
</cfif>

<!--- ── Variant matrix ───────────────────────────────────────────────────── --->
<cfset content &= "
<div class='card mb-4'>
    <div class='card-header d-flex justify-content-between align-items-center'>
        <span class='fw-semibold'><i class='bi bi-grid-3x3-gap me-1'></i> Variant Matrix</span>
        <div class='d-flex align-items-center gap-2'>
">

<cfif application.authService.hasRole("SUPER_ADMIN")>
    <cfset content &= "
            <a href='/admin/settings/media-config/variant-types.cfm' class='btn btn-sm btn-outline-secondary'>
                <i class='bi bi-sliders me-1'></i> Types
            </a>
    ">
</cfif>

<cfset content &= "
            <span class='badge bg-secondary'>#arrayLen(variantMatrix)# type(s)</span>
        </div>
    </div>
">

<cfif arrayLen(variantMatrix) GT 0>

    <cfset content &= "
    <div class='table-responsive'>
        <table class='table table-hover align-middle mb-0'>
            <thead class='table-dark'>
                <tr>
                    <th>Variant</th>
                    <th>Audience</th>
                    <th class='text-center'>Status</th>
                    <th>Last Generated</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
    ">

    <cfloop from="1" to="#arrayLen(variantMatrix)#" index="i">
        <cfset v = variantMatrix[i]>

        <!--- ── Status badge ────────────────────────────────────────── --->
        <cfset statusBadge = "">
        <cfif v.STATUS EQ "current">
            <cfset statusBadge = "<span class='badge bg-success'><i class='bi bi-check-circle me-1'></i>Current</span>">
        <cfelseif v.STATUS EQ "stale">
            <cfset statusBadge = "<span class='badge bg-warning text-dark'><i class='bi bi-arrow-clockwise me-1'></i>Stale</span>">
        <cfelseif v.STATUS EQ "error">
            <cfset statusBadge = "<span class='badge bg-danger'><i class='bi bi-x-circle me-1'></i>Error</span>">
        <cfelse><!--- missing — not yet assigned to this source --->
            <cfset statusBadge = "<span class='badge bg-secondary'><i class='bi bi-dash-circle me-1'></i>Not Assigned</span>">
        </cfif>

        <!--- ── Last generated display ──────────────────────────────── --->
        <cfset generatedDisplay = "">
        <cfif len(v.GENERATEDAT)>
            <cfset generatedDisplay = dateTimeFormat(v.GENERATEDAT, "mmm d, yyyy h:nn tt")>
        <cfelse>
            <cfset generatedDisplay = "<span class='text-muted'>Never</span>">
        </cfif>

        <!--- ── Dimensions display ───────────────────────────────────── --->
        <cfset dimDisplay = "">
        <cfset hasWidthPx = isNumeric(v.WIDTHPX ?: "") AND val(v.WIDTHPX) GT 0>
        <cfset hasHeightPx = isNumeric(v.HEIGHTPX ?: "") AND val(v.HEIGHTPX) GT 0>
        <cfif hasWidthPx AND hasHeightPx>
            <cfset dimDisplay = " <small class='text-muted'>(#val(v.WIDTHPX)# &times; #val(v.HEIGHTPX)#)</small>">
        <cfelseif hasWidthPx>
            <cfset dimDisplay = " <small class='text-muted'>(#val(v.WIDTHPX)# &times; auto)</small>">
        <cfelseif hasHeightPx>
            <cfset dimDisplay = " <small class='text-muted'>(auto &times; #val(v.HEIGHTPX)#)</small>">
        </cfif>

        <cfset content &= "
            <tr>
                <td>
                    <span class='fw-semibold'>#encodeForHTML(v.DESCRIPTION)#</span>#dimDisplay#
                    <div class='text-muted small font-monospace'>#encodeForHTML(v.CODE)#</div>
                </td>
                <td>#encodeForHTML(v.AUDIENCE)#</td>
                <td class='text-center'>#statusBadge#">

        <!--- Show error message beneath badge when status is error --->
        <cfif v.STATUS EQ "error" AND len(v.ERRORMESSAGE)>
            <cfset content &= "
                    <div class='text-danger small mt-1'>#encodeForHTML(left(v.ERRORMESSAGE, 200))#</div>">
        </cfif>

        <cfset content &= "
                </td>
                <td class='small'>#generatedDisplay#</td>
                <td>
        ">

        <cfif v.STATUS EQ "missing">
            <!--- Not yet assigned — show Assign button --->
            <cfset content &= "
                    <form method='post' class='d-inline'>
                        <input type='hidden' name='action' value='assign'>
                        <input type='hidden' name='imageVariantTypeID' value='#encodeForHTMLAttribute(v.IMAGEVARIANTTYPEID)#'>
                        <button type='submit' class='btn btn-sm btn-outline-primary'>
                            <i class='bi bi-plus-circle me-1'></i> Assign
                        </button>
                    </form>
            ">
        <cfelse>
            <!--- Already assigned — show Generate/Crop/Transfer link --->
            <cfset vtAllowCrop   = isBoolean(v.ALLOWMANUALCROP ?: false) AND v.ALLOWMANUALCROP>
            <cfset vtAllowResize = isBoolean(v.ALLOWRESIZE ?: true) AND v.ALLOWRESIZE>

            <cfif vtAllowCrop>
                <cfset content &= "
                    <a href='/admin/user-media/crop.cfm?userid=#userID#&sourceid=#sourceID#&imageVariantTypeID=#encodeForHTMLAttribute(v.IMAGEVARIANTTYPEID)#'
                       class='btn btn-sm btn-success'>
                        <i class='bi bi-crop'></i> Crop &amp; Generate
                    </a>
                ">
            <cfelse>
                <cfset content &= "
                    <a href='/admin/user-media/resize.cfm?userid=#userID#&sourceid=#sourceID#&imageVariantTypeID=#encodeForHTMLAttribute(v.IMAGEVARIANTTYPEID)#'
                       class='btn btn-sm btn-success'>
                        <i class='bi bi-gear'></i> #vtAllowResize ? 'Resize' : 'Transfer'#
                    </a>
                ">
            </cfif>
        </cfif>

        <cfset content &= "
                </td>
            </tr>
        ">
    </cfloop>

    <cfset content &= "
            </tbody>
        </table>
    </div>
    ">

<cfelse>
    <cfset content &= "
    <div class='card-body'>
        <p class='text-muted mb-0'>
            <i class='bi bi-info-circle me-1'></i>
            No active variant types are defined. Ask an administrator to seed the
            <code>ImageVariantTypes</code> table.
        </p>
    </div>
    ">
</cfif>

<cfset content &= "
</div>
">

<!--- ── Publish All button ───────────────────────────────────────────────── --->
<!---
     Show the Publish button only when at least one variant is "current"
     and has a temp file (non-empty LOCALPATH).  Publishing copies each
     current temp variant to /_published_images/, upserts UserImages, and
     deletes the temp file.
--->
<cfset publishableCount = 0>
<cfloop from="1" to="#arrayLen(variantMatrix)#" index="px">
    <cfif variantMatrix[px].STATUS EQ "current" AND len(variantMatrix[px].LOCALPATH)>
        <cfset publishableCount++>
    </cfif>
</cfloop>

<cfif publishableCount GT 0>
    <cfset content &= "
    <div class='card mb-4 border-primary'>
        <div class='card-body d-flex justify-content-between align-items-center'>
            <div>
                <i class='bi bi-upload me-1 text-primary'></i>
                <strong>#publishableCount#</strong> variant(s) ready to publish.
                Publishing copies images to the published folder and records them in the directory.
            </div>
            <form method='post' class='d-inline'>
                <input type='hidden' name='action' value='publishAll'>
                <button type='submit' class='btn btn-primary'>
                    <i class='bi bi-cloud-arrow-up me-1'></i> Publish All
                </button>
            </form>
        </div>
    </div>
    ">
</cfif>



<cfinclude template="/admin/layout.cfm">
