<!--- Duplicate merge workspace (phase 2: decision capture + status update). --->
<cfif NOT application.authService.hasRole("SUPER_ADMIN")>
    <cflocation url="#request.webRoot#/admin/unauthorized.cfm" addtoken="false">
</cfif>

<cfset pairID = (isNumeric(url.pairID ?: "") AND val(url.pairID) GT 0) ? val(url.pairID) : 0>
<cfset duplicateSvc = createObject("component", "cfc.duplicateUsers_service").init()>
<cfset msgParam = trim(url.msg ?: "")>
<cfset errParam = trim(url.err ?: "")>
<cfset warnParam = trim(url.warn ?: "")>
<cfset pair = {}>
<cfset latestMerge = {}>
<cfset latestMergeChoices = {}>
<cfset mergeSummary = {}>
<cfset mergeWarnings = []>

<cfif cgi.request_method EQ "POST">
    <cfset action = trim(form.action ?: "")>
    <cfif action EQ "mergePair" AND isNumeric(form.pairID ?: "") AND isNumeric(form.primaryUserID ?: "")>
        <cfset submittedPairID = val(form.pairID)>
        <cfset submittedPrimaryUserID = val(form.primaryUserID)>
        <cfset requestedHardDelete = listFindNoCase("1,true,yes,on", trim(form.hardDeleteSecondary ?: "")) GT 0>
        <cfset adminUserID = (structKeyExists(session, "user") AND isStruct(session.user) AND isNumeric(session.user.adminUserID ?: "")) ? val(session.user.adminUserID) : 0>
        <cfset result = duplicateSvc.mergePair(
            pairID = submittedPairID,
            primaryUserID = submittedPrimaryUserID,
            mergedByAdminUserID = adminUserID,
            notes = trim(form.notes ?: ""),
            hardDeleteSecondary = requestedHardDelete
        )>

        <cfif result.success>
            <cfset successWarn = "">
            <cfset successRedirectUrl = request.webRoot & "/admin/users/merge.cfm?pairID=" & urlEncodedFormat(submittedPairID) & "&msg=merged">
            <cfif structKeyExists(result, "warnings") AND isArray(result.warnings) AND arrayLen(result.warnings)>
                <cfset successWarn = result.warnings[1]>
            </cfif>
            <cfif len(successWarn)>
                <cfset successRedirectUrl &= "&warn=" & urlEncodedFormat(successWarn)>
            </cfif>
            <cflocation url="#successRedirectUrl#" addtoken="false">
        <cfelse>
            <cflocation url="#request.webRoot#/admin/users/merge.cfm?pairID=#urlEncodedFormat(submittedPairID)#&msg=error&err=#urlEncodedFormat(result.message ?: 'Merge failed.')#" addtoken="false">
        </cfif>
    </cfif>
</cfif>

<cfif pairID GT 0>
    <cfset pair = duplicateSvc.getPairByID(pairID)>
    <cfset latestMerge = duplicateSvc.getLatestMergeByPairID(pairID)>

    <cfif NOT structIsEmpty(latestMerge) AND isJSON(latestMerge.MERGECHOICES ?: "")>
        <cfset latestMergeChoices = deserializeJSON(latestMerge.MERGECHOICES)>
        <cfif isStruct(latestMergeChoices) AND structKeyExists(latestMergeChoices, "dataMigrationSummary") AND isStruct(latestMergeChoices.dataMigrationSummary)>
            <cfset mergeSummary = latestMergeChoices.dataMigrationSummary>
        </cfif>
        <cfif isStruct(latestMergeChoices) AND structKeyExists(latestMergeChoices, "warnings") AND isArray(latestMergeChoices.warnings)>
            <cfset mergeWarnings = latestMergeChoices.warnings>
        </cfif>
    </cfif>
</cfif>

<cfset content = "">
<cfsavecontent variable="content">
<cfoutput>
<h1 class="mb-1">Merge Duplicate Users</h1>
<p class="text-muted">Select which user to keep as primary. The merge will move non-duplicate secondary data to the primary record and deactivate the secondary user.</p>

<cfif msgParam EQ "merged">
    <div class="alert alert-success mt-3"><i class="bi bi-check-circle-fill"></i> Pair was marked as merged successfully.</div>
<cfelseif msgParam EQ "error">
    <div class="alert alert-danger mt-3"><strong>Merge failed:</strong> #encodeForHTML(errParam ?: "Unknown error")#</div>
</cfif>

<cfif len(warnParam)>
    <div class="alert alert-warning mt-3"><strong>Merge note:</strong> #encodeForHTML(warnParam)#</div>
</cfif>

<cfif pairID LTE 0>
    <div class="alert alert-warning">Missing or invalid pair ID.</div>
<cfelseif structIsEmpty(pair)>
    <div class="alert alert-warning">Pair not found.</div>
<cfelse>
    <cfset isMerged = lCase(trim(pair.STATUS ?: "")) EQ "merged">

    <cfif isMerged>
        <div class="alert alert-info">
            This pair is already merged.
            <cfif NOT structIsEmpty(latestMerge)>
                Primary user ## #val(latestMerge.PRIMARYUSERID ?: 0)#, secondary user ## #val(latestMerge.SECONDARYUSERID ?: 0)#.
            </cfif>
        </div>

        <cfif arrayLen(mergeWarnings)>
            <div class="alert alert-warning">
                <strong>Merge warnings:</strong>
                <ul class="mb-0 mt-2">
                    <cfloop from="1" to="#arrayLen(mergeWarnings)#" index="wIdx">
                        <li>#encodeForHTML(mergeWarnings[wIdx] ?: "")#</li>
                    </cfloop>
                </ul>
            </div>
        </cfif>

        <cfif structCount(mergeSummary)>
            <div class="card card-body mt-3">
                <h5 class="mb-2">Merge Result Summary</h5>
                <div class="table-responsive">
                    <table class="table table-sm align-middle mb-0">
                        <thead>
                            <tr>
                                <th>Area</th>
                                <th class="text-end">Moved</th>
                                <th class="text-end">Deduped</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr><td>Emails</td><td class="text-end">#val(mergeSummary.EMAILSMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.EMAILSDEDUPED ?: 0)#</td></tr>
                            <tr><td>Phones</td><td class="text-end">#val(mergeSummary.PHONESMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.PHONESDEDUPED ?: 0)#</td></tr>
                            <tr><td>Addresses</td><td class="text-end">#val(mergeSummary.ADDRESSESMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.ADDRESSESDEDUPED ?: 0)#</td></tr>
                            <tr><td>Flags</td><td class="text-end">#val(mergeSummary.FLAGSMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.FLAGSDEDUPED ?: 0)#</td></tr>
                            <tr><td>Organizations</td><td class="text-end">#val(mergeSummary.ORGANIZATIONSMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.ORGANIZATIONSDEDUPED ?: 0)#</td></tr>
                            <tr><td>Access Assignments</td><td class="text-end">#val(mergeSummary.ACCESSASSIGNMENTSMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.ACCESSASSIGNMENTSDEDUPED ?: 0)#</td></tr>
                            <tr><td>External IDs</td><td class="text-end">#val(mergeSummary.EXTERNALIDSMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.EXTERNALIDSDEDUPED ?: 0)#</td></tr>
                            <tr><td>Aliases</td><td class="text-end">#val(mergeSummary.ALIASESMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.ALIASESDEDUPED ?: 0)#</td></tr>
                            <tr><td>Degrees</td><td class="text-end">#val(mergeSummary.DEGREESMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.DEGREESDEDUPED ?: 0)#</td></tr>
                            <tr><td>Awards</td><td class="text-end">#val(mergeSummary.AWARDSMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.AWARDSDEDUPED ?: 0)#</td></tr>
                            <tr><td>Images</td><td class="text-end">#val(mergeSummary.IMAGESMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.IMAGESDEDUPED ?: 0)#</td></tr>
                            <tr><td>Review Submissions</td><td class="text-end">#val(mergeSummary.REVIEWSUBMISSIONSMOVED ?: 0)#</td><td class="text-end">0</td></tr>
                            <tr><td>Academic Info</td><td class="text-end">#val(mergeSummary.ACADEMICINFOMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.ACADEMICINFOMERGED ?: 0)#</td></tr>
                            <tr><td>Bio</td><td class="text-end">#val(mergeSummary.BIOMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.BIOMERGED ?: 0)#</td></tr>
                            <tr><td>Student Profile</td><td class="text-end">#val(mergeSummary.STUDENTPROFILEMOVED ?: 0)#</td><td class="text-end">#val(mergeSummary.STUDENTPROFILEMERGED ?: 0)#</td></tr>
                            <tr><td>Secondary Deactivated</td><td class="text-end">#val(mergeSummary.SECONDARYDEACTIVATED ?: 0)#</td><td class="text-end">0</td></tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </cfif>
    <cfelse>
        <div class="alert alert-warning">This operation reassigns non-duplicate child records (emails, phones, addresses, flags, organizations, access, external IDs, aliases, degrees, awards, images, review submissions), merges singleton profile data where primary fields are empty, and deactivates the secondary user.</div>
    </cfif>

    <div class="row g-3">
        <div class="col-md-6">
            <div class="card card-body h-100">
                <h5 class="mb-2">User A (#pair.USERID_A#)</h5>
                <div><strong>Name:</strong> #encodeForHTML(trim((pair.USERAFIRSTNAME ?: "") & " " & (pair.USERALASTNAME ?: "")))#</div>
                <div><strong>Email:</strong> #encodeForHTML(pair.USERAEMAIL ?: "")#</div>
                <div><strong>Flags:</strong> #encodeForHTML(pair.USERAFLAGS ?: "none")#</div>
                <div><strong>Grad Year:</strong> #val(pair.USERAGRADYEAR ?: 0)#</div>
            </div>
        </div>
        <div class="col-md-6">
            <div class="card card-body h-100">
                <h5 class="mb-2">User B (#pair.USERID_B#)</h5>
                <div><strong>Name:</strong> #encodeForHTML(trim((pair.USERBFIRSTNAME ?: "") & " " & (pair.USERBLASTNAME ?: "")))#</div>
                <div><strong>Email:</strong> #encodeForHTML(pair.USERBEMAIL ?: "")#</div>
                <div><strong>Flags:</strong> #encodeForHTML(pair.USERBFLAGS ?: "none")#</div>
                <div><strong>Grad Year:</strong> #val(pair.USERBGRADYEAR ?: 0)#</div>
            </div>
        </div>
    </div>

    <cfif NOT isMerged>
        <form method="post" class="card card-body mt-3">
            <input type="hidden" name="action" value="mergePair">
            <input type="hidden" name="pairID" value="#pairID#">

            <h5 class="mb-2">Merge Decision</h5>
            <p class="text-muted mb-2">Choose the user profile to keep as the primary account. Duplicate child rows are skipped, and the secondary account is set inactive (not deleted).</p>

            <div class="form-check form-switch mb-3">
                <input class="form-check-input" type="checkbox" role="switch" id="hardDeleteSecondary" name="hardDeleteSecondary" value="1">
                <label class="form-check-label" for="hardDeleteSecondary">Attempt hard delete of secondary user after merge</label>
                <div class="form-text text-warning">Hard delete is currently blocked by duplicate-merge audit foreign-key history. If selected, the merge will still complete with secondary deactivation.</div>
            </div>

            <div class="form-check mb-1">
                <input class="form-check-input" type="radio" name="primaryUserID" id="keepUserA" value="#val(pair.USERID_A)#" checked>
                <label class="form-check-label" for="keepUserA">Keep User A as Primary (## #val(pair.USERID_A)#)</label>
            </div>
            <div class="form-check mb-3">
                <input class="form-check-input" type="radio" name="primaryUserID" id="keepUserB" value="#val(pair.USERID_B)#">
                <label class="form-check-label" for="keepUserB">Keep User B as Primary (## #val(pair.USERID_B)#)</label>
            </div>

            <label for="mergeNotes" class="form-label">Notes (optional)</label>
            <textarea id="mergeNotes" name="notes" class="form-control" rows="3" maxlength="500" placeholder="Why this primary user was selected"></textarea>

            <div class="mt-3 d-flex gap-2">
                <button type="submit" class="btn btn-primary">Confirm Merge</button>
                <a href="/admin/reporting/duplicate_users_report.cfm" class="btn btn-outline-secondary">Cancel</a>
            </div>
        </form>
    </cfif>
</cfif>

<div class="mt-3">
    <a href="/admin/reporting/duplicate_users_report.cfm" class="btn btn-outline-secondary">Back to Duplicate Report</a>
</div>
</cfoutput>
</cfsavecontent>

<cfinclude template="/admin/layout.cfm">
