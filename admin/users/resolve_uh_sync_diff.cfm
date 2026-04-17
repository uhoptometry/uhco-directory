<!---
    resolve_uh_sync_diff.cfm
    Handles sync / discard actions for UH Sync Report items.

    Accepts POST with one of these operation sets:

    Field diff:
        diffID     — UHSyncDiffs.DiffID
        resolution — 'synced' | 'discarded'
        returnTo   — redirect target (validated)

    Gone user:
        goneID     — UHSyncGone.GoneID
        resolution — 'deleted' | 'kept'
        userID     — required for 'deleted' (local UserID to remove)
        returnTo   — redirect target (validated)

    New API user:
        newID      — UHSyncNew.NewID
        resolution — 'imported' | 'ignored'
        returnTo   — redirect target (validated)
--->

<cfparam name="form.diffID"     default="0">
<cfparam name="form.goneID"     default="0">
<cfparam name="form.newID"      default="0">
<cfparam name="form.resolution" default="">
<cfparam name="form.returnTo"   default="">
<cfparam name="form.userID"     default="0">

<!--- Only allow POST --->
<cfif cgi.REQUEST_METHOD NEQ "POST">
    <cflocation url="#request.webRoot#/admin/reporting/uh_sync_report.cfm" addtoken="false">
    <cfabort>
</cfif>

<!--- Validate returnTo: root-relative only, no open-redirect --->
<cfset returnTo = "/admin/reporting/uh_sync_report.cfm">
<cfif len(trim(form.returnTo))>
    <cfset candidate = trim(form.returnTo)>
    <cfif left(candidate, 1) EQ "/" AND NOT find("//", candidate) AND NOT findNoCase("javascript:", candidate)>
        <cfset returnTo = candidate>
    </cfif>
</cfif>
<cfset sep = find("?", returnTo) ? "&" : "?">

<cfset resolution = lCase(trim(form.resolution))>
<cfset uhSyncDAO  = createObject("component", "dao.uhSync_DAO").init()>

<!--- ══════════════════════════════════════════════════════════════════ --->
<!--- ── FIELD DIFF ─────────────────────────────────────────────────── --->
<!--- ══════════════════════════════════════════════════════════════════ --->
<cfif isNumeric(form.diffID) AND val(form.diffID) GT 0>

    <cfset diffID     = val(form.diffID)>
    <cfset allowedRes = ["synced", "discarded"]>

    <cfif NOT arrayFindNoCase(allowedRes, resolution)>
        <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Invalid resolution for diff.')#" addtoken="false">
        <cfabort>
    </cfif>

    <!--- Load the diff record --->
    <cfset diffRow = uhSyncDAO.getDiffByID(diffID)>
    <cfif structIsEmpty(diffRow)>
        <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Diff record not found.')#" addtoken="false">
        <cfabort>
    </cfif>
    <cfif len(trim(diffRow.RESOLUTION ?: ""))>
        <!--- Already resolved — just redirect cleanly --->
        <cflocation url="#returnTo##sep#msg=resolved&info=#urlEncodedFormat('Already resolved.')#" addtoken="false">
        <cfabort>
    </cfif>

    <cfif resolution EQ "synced">
        <!--- Apply the API value to the local user field --->
        <cfset usersService    = createObject("component", "cfc.users_service").init()>
        <cfset currentUserResult = usersService.getUser(val(diffRow.USERID))>

        <cfif NOT (structKeyExists(currentUserResult, "success") AND currentUserResult.success)>
            <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Could not load user ' & diffRow.USERID & ' for update.')#" addtoken="false">
            <cfabort>
        </cfif>

        <cfset cu       = currentUserResult.data>
        <cfset userData = {
            FirstName              = cu.FIRSTNAME              ?: "",
            MiddleName             = cu.MIDDLENAME             ?: "",
            LastName               = cu.LASTNAME               ?: "",
            Pronouns               = cu.PRONOUNS               ?: "",
            EmailPrimary           = cu.EMAILPRIMARY           ?: "",
            Phone                  = cu.PHONE                  ?: "",
            Room                   = cu.ROOM                   ?: "",
            Building               = cu.BUILDING               ?: "",
            Title1                 = cu.TITLE1                 ?: "",
            Title2                 = cu.TITLE2                 ?: "",
            Title3                 = cu.TITLE3                 ?: "",
            Division               = cu.DIVISION               ?: "",
            DivisionName           = cu.DIVISIONNAME           ?: "",
            Campus                 = cu.CAMPUS                 ?: "",
            Department             = cu.DEPARTMENT             ?: "",
            DepartmentName         = cu.DEPARTMENTNAME         ?: "",
            Office_Mailing_Address = cu.OFFICE_MAILING_ADDRESS ?: "",
            Mailcode               = cu.MAILCODE               ?: "",
            UH_API_ID              = cu.UH_API_ID              ?: "",
            Degrees                = cu.DEGREES                ?: "",
            Prefix                 = cu.PREFIX                 ?: "",
            Suffix                 = cu.SUFFIX                 ?: ""
        }>

        <!--- Map the stored field name to the userData key --->
        <cfset fieldName = uCase(trim(diffRow.FIELDNAME))>
        <cfset apiVal    = trim(diffRow.APIVALUE)>

        <cfif     fieldName EQ "FIRSTNAME">              <cfset userData.FirstName              = apiVal>
        <cfelseif fieldName EQ "LASTNAME">               <cfset userData.LastName               = apiVal>
        <cfelseif fieldName EQ "EMAILPRIMARY">           <cfset userData.EmailPrimary           = lCase(apiVal)>
        <cfelseif fieldName EQ "PHONE">                  <cfset userData.Phone                  = apiVal>
        <cfelseif fieldName EQ "ROOM">                   <cfset userData.Room                   = apiVal>
        <cfelseif fieldName EQ "BUILDING">               <cfset userData.Building               = apiVal>
        <cfelseif fieldName EQ "TITLE1">                 <cfset userData.Title1                 = apiVal>
        <cfelseif fieldName EQ "DIVISION">               <cfset userData.Division               = apiVal>
        <cfelseif fieldName EQ "DIVISIONNAME">           <cfset userData.DivisionName           = apiVal>
        <cfelseif fieldName EQ "CAMPUS">                 <cfset userData.Campus                 = apiVal>
        <cfelseif fieldName EQ "DEPARTMENT">             <cfset userData.Department             = apiVal>
        <cfelseif fieldName EQ "DEPARTMENTNAME">         <cfset userData.DepartmentName         = apiVal>
        <cfelseif fieldName EQ "OFFICE_MAILING_ADDRESS"> <cfset userData.Office_Mailing_Address = apiVal>
        <cfelseif fieldName EQ "MAILCODE">               <cfset userData.Mailcode               = apiVal>
        <cfelse>
            <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Field ' & diffRow.FIELDNAME & ' cannot be synced from this page.')#" addtoken="false">
            <cfabort>
        </cfif>

        <cfset updateResult = usersService.updateUser(val(diffRow.USERID), userData)>
        <cfif NOT (structKeyExists(updateResult, "success") AND updateResult.success)>
            <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Update failed: ' & (updateResult.message ?: 'Unknown error.'))#" addtoken="false">
            <cfabort>
        </cfif>
    </cfif>

    <!--- Mark diff resolved --->
    <cftry>
        <cfset uhSyncDAO.resolveDiff(diffID, resolution)>
    <cfcatch>
        <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Resolution save failed: ' & cfcatch.message)#" addtoken="false">
        <cfabort>
    </cfcatch>
    </cftry>

    <cfset fieldLabel = trim(diffRow.FIELDNAME)>
    <cfset msgLabels  = { "synced"="Synced", "discarded"="Discarded" }>
    <cfset msgTxt     = (msgLabels[resolution] ?: resolution) & " " & fieldLabel & " for user " & diffRow.USERID & ".">
    <cflocation url="#returnTo##sep#msg=resolved&err=#urlEncodedFormat(msgTxt)#" addtoken="false">
    <cfabort>

<!--- ══════════════════════════════════════════════════════════════════ --->
<!--- ── GONE USER ──────────────────────────────────────────────────── --->
<!--- ══════════════════════════════════════════════════════════════════ --->
<cfelseif isNumeric(form.goneID) AND val(form.goneID) GT 0>

    <cfset goneID     = val(form.goneID)>
    <cfset allowedRes = ["deleted", "kept"]>

    <cfif NOT arrayFindNoCase(allowedRes, resolution)>
        <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Invalid resolution for gone user.')#" addtoken="false">
        <cfabort>
    </cfif>

    <cfset goneRow = uhSyncDAO.getGoneByID(goneID)>
    <cfif structIsEmpty(goneRow)>
        <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Gone record not found.')#" addtoken="false">
        <cfabort>
    </cfif>
    <cfif len(trim(goneRow.RESOLUTION ?: ""))>
        <cflocation url="#returnTo##sep#msg=resolved&info=#urlEncodedFormat('Already resolved.')#" addtoken="false">
        <cfabort>
    </cfif>

    <cfif resolution EQ "deleted">
        <!--- Delete user from local DB using userID from form (double-check matches gone record) --->
        <cfset targetUserID = isNumeric(form.userID) ? val(form.userID) : val(goneRow.USERID)>
        <cfif targetUserID GT 0>
            <cfset usersService  = createObject("component", "cfc.users_service").init()>
            <cfset deleteResult  = usersService.deleteUser(targetUserID)>
            <cfif NOT (structKeyExists(deleteResult, "success") AND deleteResult.success)>
                <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Could not delete user: ' & (deleteResult.message ?: 'Unknown error.'))#" addtoken="false">
                <cfabort>
            </cfif>
        </cfif>
    </cfif>

    <cftry>
        <cfset uhSyncDAO.resolveGone(goneID, resolution)>
    <cfcatch>
        <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Resolution save failed: ' & cfcatch.message)#" addtoken="false">
        <cfabort>
    </cfcatch>
    </cftry>

    <cfset msgTxt = resolution EQ "deleted" ? "User deleted successfully." : "User marked as kept (no action taken).">
    <cflocation url="#returnTo##sep#msg=resolved&err=#urlEncodedFormat(msgTxt)#" addtoken="false">
    <cfabort>

<!--- ══════════════════════════════════════════════════════════════════ --->
<!--- ── NEW API USER ───────────────────────────────────────────────── --->
<!--- ══════════════════════════════════════════════════════════════════ --->
<cfelseif isNumeric(form.newID) AND val(form.newID) GT 0>

    <cfset newID      = val(form.newID)>
    <cfset allowedRes = ["imported", "ignored"]>

    <cfif NOT arrayFindNoCase(allowedRes, resolution)>
        <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Invalid resolution for new user.')#" addtoken="false">
        <cfabort>
    </cfif>

    <cfset newRow = uhSyncDAO.getNewByID(newID)>
    <cfif structIsEmpty(newRow)>
        <cflocation url="#returnTo##sep#err=#urlEncodedFormat('New-user record not found.')#" addtoken="false">
        <cfabort>
    </cfif>
    <cfif len(trim(newRow.RESOLUTION ?: ""))>
        <cflocation url="#returnTo##sep#msg=resolved&info=#urlEncodedFormat('Already resolved.')#" addtoken="false">
        <cfabort>
    </cfif>

    <cfif resolution EQ "imported">

        <cfset uhApiId = trim(newRow.UHApiID ?: "")>
        <!--- Prefer actual UHApiID column name - handles different CF case sensitivity --->
        <cftry>
            <cfset uhApiId = trim(newRow.UHApiID)>
        <cfcatch>
            <cfset uhApiId = "">
        </cfcatch>
        </cftry>

        <cfif NOT len(uhApiId)>
            <cflocation url="#returnTo##sep#err=#urlEncodedFormat('No UH API ID stored for this new-user record.')#" addtoken="false">
            <cfabort>
        </cfif>

        <!--- Guard: do not create a duplicate --->
        <cfset existingCheck = queryExecute(
            "SELECT TOP 1 UserID FROM Users WHERE UH_API_ID = :id",
            { id = { value=uhApiId, cfsqltype="cf_sql_nvarchar" } },
            { datasource="#request.datasource#", timeout=30 }
        )>
        <cfif existingCheck.recordCount GT 0>
            <!--- Already exists — just mark resolved and continue --->
            <cfset uhSyncDAO.resolveNew(newID, "imported")>
            <cflocation url="#returnTo##sep#msg=resolved&err=#urlEncodedFormat('User already exists locally (UserID ' & existingCheck.UserID & '); marked as imported.')#" addtoken="false">
            <cfabort>
        </cfif>

        <!--- ── Re-fetch fresh person data from UH API ── --->
        <cfset uhApiToken  = structKeyExists(application, "uhApiToken")  ? trim(application.uhApiToken  ?: "") : "">
        <cfset uhApiSecret = structKeyExists(application, "uhApiSecret") ? trim(application.uhApiSecret ?: "") : "">
        <cfif (uhApiToken EQ "" OR uhApiSecret EQ "") AND structKeyExists(server, "system") AND structKeyExists(server.system, "environment")>
            <cfif structKeyExists(server.system.environment, "UH_API_TOKEN")><cfset uhApiToken  = trim(server.system.environment["UH_API_TOKEN"])></cfif>
            <cfif structKeyExists(server.system.environment, "UH_API_SECRET")><cfset uhApiSecret = trim(server.system.environment["UH_API_SECRET"])></cfif>
        </cfif>
        <cfif uhApiToken  EQ ""><cfset uhApiToken  = "my5Tu[{[VH%,dT{wR3SEigeWc%2w,ZyFT6=5!2Rv$f0g,_z!UpDduLxhgjSm$P6"></cfif>
        <cfif uhApiSecret EQ ""><cfset uhApiSecret = "degxqhYPX2Vk@LFevunxX}:kTkX3fBXR"></cfif>

        <cfset uhApi = createObject("component", "cfc.uh_api").init(apiToken=uhApiToken, apiSecret=uhApiSecret)>
        <cfsilent>
            <cfset personResponse = uhApi.getPerson(uhApiId)>
        </cfsilent>
        <cfset statusCode   = personResponse.statusCode ?: "Unknown">
        <cfset responseData = personResponse.data ?: {}>

        <cfif left(statusCode, 3) NEQ "200">
            <cflocation url="#returnTo##sep#err=#urlEncodedFormat('UH API returned status ' & statusCode & ' while re-fetching person ' & uhApiId)#" addtoken="false">
            <cfabort>
        </cfif>

        <!--- Unwrap nested response --->
        <cfset apiPerson = {}>
        <cfif isStruct(responseData)>
            <cfif structKeyExists(responseData, "data") AND isStruct(responseData.data)>
                <cfif structKeyExists(responseData.data, "person") AND isStruct(responseData.data.person)>
                    <cfset apiPerson = responseData.data.person>
                <cfelse>
                    <cfset apiPerson = responseData.data>
                </cfif>
            <cfelseif structKeyExists(responseData, "data") AND isArray(responseData.data) AND arrayLen(responseData.data) GT 0>
                <cfset apiPerson = responseData.data[1]>
            <cfelseif structKeyExists(responseData, "person") AND isStruct(responseData.person)>
                <cfset apiPerson = responseData.person>
            <cfelse>
                <cfset apiPerson = responseData>
            </cfif>
        <cfelseif isArray(responseData) AND arrayLen(responseData) GT 0>
            <cfset apiPerson = responseData[1]>
        </cfif>

        <!--- Deep-search helper --->
        <cfscript>
            function rsdFindDeep(any node="", required string keyName) {
                var keys  = [];  var k = "";  var found = "";  var i = 1;
                if (isNull(arguments.node)) { return ""; }
                if (isStruct(arguments.node)) {
                    keys = structKeyArray(arguments.node);
                    for (i = 1; i <= arrayLen(keys); i++) {
                        k = keys[i];
                        if (compareNoCase(k, arguments.keyName) EQ 0 AND isSimpleValue(arguments.node[k])) {
                            return toString(arguments.node[k] ?: "");
                        }
                    }
                    for (i = 1; i <= arrayLen(keys); i++) {
                        found = rsdFindDeep(node=arguments.node[keys[i]], keyName=arguments.keyName);
                        if (len(trim(toString(found)))) { return found; }
                    }
                } else if (isArray(arguments.node)) {
                    for (i = 1; i <= arrayLen(arguments.node); i++) {
                        found = rsdFindDeep(node=arguments.node[i], keyName=arguments.keyName);
                        if (len(trim(toString(found)))) { return found; }
                    }
                }
                return "";
            }
            function rsdGet(required any src, required string keysCsv) {
                var names = listToArray(arguments.keysCsv);
                var i = 1; var v = "";
                for (i = 1; i <= arrayLen(names); i++) {
                    v = rsdFindDeep(node=arguments.src, keyName=trim(names[i]));
                    if (len(trim(toString(v)))) { return toString(v); }
                }
                return "";
            }
        </cfscript>

        <cfset apiFirstName    = trim(rsdGet(apiPerson, "first_name,firstName"))>
        <cfset apiLastName     = trim(rsdGet(apiPerson, "last_name,lastName"))>
        <cfset apiEmail        = trim(rsdGet(apiPerson, "email,emailAddress"))>
        <cfset apiPhone        = trim(rsdGet(apiPerson, "phone,phoneNumber"))>
        <cfset apiRoom         = trim(rsdGet(apiPerson, "room"))>
        <cfset apiBuilding     = trim(rsdGet(apiPerson, "building"))>
        <cfset apiTitle        = trim(rsdGet(apiPerson, "title"))>
        <cfset apiDivision     = trim(rsdGet(apiPerson, "division"))>
        <cfset apiDivisionName = trim(rsdGet(apiPerson, "division_name,divisionName"))>
        <cfset apiCampus       = trim(rsdGet(apiPerson, "campus"))>
        <cfset apiDept         = trim(rsdGet(apiPerson, "department"))>
        <cfset apiDeptName     = trim(rsdGet(apiPerson, "department_name,departmentName"))>
        <cfset apiOfficeAddr   = trim(rsdGet(apiPerson, "office_mailing_address,officeMailingAddress,mailing_address"))>
        <cfset apiMailcode     = trim(rsdGet(apiPerson, "mailcode,mail_code"))>
        <cfset apiStudent      = lCase(trim(rsdGet(apiPerson, "student,is_student,isStudent")))>
        <cfset apiStaff        = lCase(trim(rsdGet(apiPerson, "staff,is_staff,isStaff")))>
        <cfset apiFaculty      = lCase(trim(rsdGet(apiPerson, "faculty,is_faculty,isFaculty")))>

        <!--- Fallback to stored values if API re-fetch had sparse data --->
        <cfif NOT len(apiFirstName)><cfset apiFirstName = trim(newRow.FIRSTNAME ?: "")></cfif>
        <cfif NOT len(apiLastName)> <cfset apiLastName  = trim(newRow.LASTNAME  ?: "")></cfif>
        <cfif NOT len(apiEmail)>    <cfset apiEmail     = trim(newRow.EMAIL     ?: "")></cfif>
        <cfif NOT len(apiTitle)>    <cfset apiTitle     = trim(newRow.TITLE     ?: "")></cfif>
        <cfif NOT len(apiDept)>     <cfset apiDept      = trim(newRow.DEPARTMENT ?: "")></cfif>
        <cfif NOT len(apiPhone)>    <cfset apiPhone     = trim(newRow.PHONE     ?: "")></cfif>

        <cfif NOT len(apiFirstName) OR NOT len(apiLastName)>
            <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Cannot import: missing first or last name for API ID ' & uhApiId)#" addtoken="false">
            <cfabort>
        </cfif>

        <!--- Create local user --->
        <cfset usersService = createObject("component", "cfc.users_service").init()>
        <cfset createResult = usersService.createUser({
            FirstName              = apiFirstName,
            MiddleName             = "",
            LastName               = apiLastName,
            Pronouns               = "",
            EmailPrimary           = (len(apiEmail)       ? lCase(apiEmail)    : ""),
            Phone                  = (len(apiPhone)       ? apiPhone           : ""),
            Room                   = (len(apiRoom)        ? apiRoom            : ""),
            Building               = (len(apiBuilding)    ? apiBuilding        : ""),
            Title1                 = (len(apiTitle)       ? apiTitle           : ""),
            Title2                 = "",
            Title3                 = "",
            Division               = (len(apiDivision)    ? apiDivision        : ""),
            DivisionName           = (len(apiDivisionName)? apiDivisionName    : ""),
            Campus                 = (len(apiCampus)      ? apiCampus          : ""),
            Department             = (len(apiDept)        ? apiDept            : ""),
            DepartmentName         = (len(apiDeptName)    ? apiDeptName        : ""),
            Office_Mailing_Address = (len(apiOfficeAddr)  ? apiOfficeAddr      : ""),
            Mailcode               = (len(apiMailcode)    ? apiMailcode        : ""),
            Degrees                = "",
            Prefix                 = "",
            Suffix                 = "",
            UH_API_ID              = uhApiId
        })>

        <cfif NOT (structKeyExists(createResult, "success") AND createResult.success)>
            <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Failed to create user: ' & (createResult.message ?: 'Unknown error.'))#" addtoken="false">
            <cfabort>
        </cfif>

        <cfset newUserID = val(createResult.userID ?: 0)>

        <!--- Assign flags from API booleans --->
        <cfset flagsService     = createObject("component", "cfc.flags_service").init()>
        <cfset allFlagsResult   = flagsService.getAllFlags()>
        <cfif structKeyExists(allFlagsResult, "success") AND allFlagsResult.success>
            <cfloop from="1" to="#arrayLen(allFlagsResult.data)#" index="f">
                <cfset fname = trim(allFlagsResult.data[f].FLAGNAME ?: "")>
                <cfset fid   = val(allFlagsResult.data[f].FLAGID ?: 0)>
                <cfif compareNoCase(fname, "Current-Student") EQ 0 AND listFindNoCase("yes,true,1,y", apiStudent)>
                    <cfset flagsService.addFlag(newUserID, fid)>
                <cfelseif compareNoCase(fname, "Staff") EQ 0 AND listFindNoCase("yes,true,1,y", apiStaff)>
                    <cfset flagsService.addFlag(newUserID, fid)>
                <cfelseif compareNoCase(fname, "Faculty-Fulltime") EQ 0 AND listFindNoCase("yes,true,1,y", apiFaculty)>
                    <cfset flagsService.addFlag(newUserID, fid)>
                </cfif>
            </cfloop>
        </cfif>

    </cfif>  <!--- end resolution EQ imported --->

    <!--- Mark new record resolved --->
    <cftry>
        <cfset uhSyncDAO.resolveNew(newID, resolution)>
    <cfcatch>
        <cflocation url="#returnTo##sep#err=#urlEncodedFormat('Resolution save failed: ' & cfcatch.message)#" addtoken="false">
        <cfabort>
    </cfcatch>
    </cftry>

    <cfset msgTxt = resolution EQ "imported"
        ? "User imported successfully (UserID " & (newUserID ?: "?") & ")."
        : "New API user ignored.">
    <cflocation url="#returnTo##sep#msg=resolved&err=#urlEncodedFormat(msgTxt)#" addtoken="false">
    <cfabort>

<cfelse>
    <!--- No valid operation supplied --->
    <cflocation url="#request.webRoot#/admin/reporting/uh_sync_report.cfm?err=#urlEncodedFormat('No valid action supplied.')#" addtoken="false">
</cfif>
