<!--- DEPRECATED: All user saves now go through saveSection.cfm via per-tab AJAX.
     This file is kept as a redirect stub to avoid 404s from bookmarks/history. --->
<cfset redirectTo = (structKeyExists(form, "returnTo") AND len(trim(form.returnTo))) ? trim(form.returnTo) : "/admin/users/index.cfm">
<cflocation url="#redirectTo#" addtoken="false">

<!--- Proper-case helper: "JANE DOE" / "jane doe" → "Jane Doe", handles McX / O'X / hyphens --->
<cffunction name="toProperName" access="private" returntype="string" output="false">
    <cfargument name="input" type="string" required="true">
    <cfset var raw = trim(arguments.input)>
    <cfif NOT len(raw)><cfreturn ""></cfif>
    <cfset var words = listToArray(raw, " ")>
    <cfset var result = []>
    <cfloop array="#words#" index="local.w">
        <!--- Handle hyphenated parts separately --->
        <cfset var hParts = listToArray(local.w, "-")>
        <cfset var hResult = []>
        <cfloop array="#hParts#" index="local.h">
            <cfset var part = lCase(local.h)>
            <!--- Mc prefix: McDonald --->
            <cfif len(part) GT 2 AND left(part, 2) EQ "mc">
                <cfset part = "Mc" & uCase(mid(part, 3, 1)) & mid(part, 4, len(part) - 3)>
            <!--- O' prefix: O'Brien --->
            <cfelseif len(part) GT 2 AND left(part, 2) EQ "o'">
                <cfset part = "O'" & uCase(mid(part, 3, 1)) & mid(part, 4, len(part) - 3)>
            <cfelse>
                <cfset part = uCase(left(part, 1)) & mid(part, 2, len(part) - 1)>
            </cfif>
            <cfset arrayAppend(hResult, part)>
        </cfloop>
        <cfset arrayAppend(result, arrayToList(hResult, "-"))>
    </cfloop>
    <cfreturn arrayToList(result, " ")>
</cffunction>

<!--- Map form data to userData with correct CamelCase naming for DAO SQL parameters --->
<cfset userData = {}>
<cfset userData.FirstName = toProperName(form.FIRSTNAME)>
<cfset userData.MiddleName = structKeyExists(form, "MIDDLENAME") ? toProperName(form.MIDDLENAME) : "">
<cfif len(trim(userData.MiddleName)) EQ 1 AND reFind("^[A-Za-z]$", trim(userData.MiddleName))>
    <cfset userData.MiddleName = trim(userData.MiddleName) & ".">
</cfif>
<cfset userData.LastName = toProperName(form.LASTNAME)>
<cfset userData.Pronouns = structKeyExists(form, "PRONOUNS") ? form.PRONOUNS : "">
<cfset userData.EmailPrimary = structKeyExists(form, "EMAILPRIMARY") ? trim(form.EMAILPRIMARY) : "">
<cfset userData.Phone = structKeyExists(form, "PHONE") ? form.PHONE : "">
<cfset userData.Room = structKeyExists(form, "ROOM") ? form.ROOM : "">
<cfset userData.Building = structKeyExists(form, "BUILDING") ? form.BUILDING : "">
<cfset userData.Title1 = structKeyExists(form, "TITLE1") ? form.TITLE1 : "">
<cfset userData.Title2 = structKeyExists(form, "TITLE2") ? form.TITLE2 : "">
<cfset userData.Title3 = structKeyExists(form, "TITLE3") ? form.TITLE3 : "">
<cfset userData.UH_API_ID = structKeyExists(form, "UH_API_ID") ? form.UH_API_ID : "">
<cfset userData.Prefix = structKeyExists(form, "PREFIX") ? form.PREFIX : "">
<cfset userData.Suffix = structKeyExists(form, "SUFFIX") ? form.SUFFIX : "">
<cfset userData.Degrees = structKeyExists(form, "DEGREES") ? form.DEGREES : "">
<cfset userData.Campus = structKeyExists(form, "CAMPUS") ? form.CAMPUS : "">
<cfset userData.Division = structKeyExists(form, "DIVISION") ? form.DIVISION : "">
<cfset userData.DivisionName = structKeyExists(form, "DIVISIONNAME") ? form.DIVISIONNAME : "">
<cfset userData.Department = structKeyExists(form, "DEPARTMENT") ? form.DEPARTMENT : "">
<cfset userData.DepartmentName = structKeyExists(form, "DEPARTMENTNAME") ? form.DEPARTMENTNAME : "">
<cfset userData.Office_Mailing_Address = structKeyExists(form, "OFFICE_MAILING_ADDRESS") ? form.OFFICE_MAILING_ADDRESS : "">
<cfset userData.Mailcode = structKeyExists(form, "MAILCODE") ? form.MAILCODE : "">
<cfset userData.Active = structKeyExists(form, "ACTIVE") AND isNumeric(form.ACTIVE) AND listFind("0,1", form.ACTIVE) ? val(form.ACTIVE) : 1>
<cfset userData.DOB = { value=(structKeyExists(form, "DOB") AND len(trim(form.DOB)) ? trim(form.DOB) : ""), cfsqltype="cf_sql_date", null=(NOT structKeyExists(form, "DOB") OR NOT len(trim(form.DOB))) }>
<cfset userData.Gender = { value=(structKeyExists(form, "GENDER") AND len(trim(form.GENDER)) ? trim(form.GENDER) : ""), cfsqltype="cf_sql_nvarchar", null=(NOT structKeyExists(form, "GENDER") OR NOT len(trim(form.GENDER))) }>

<cfif structKeyExists(form, "UserID")>
    <!--- Update user --->
    <cfset result = usersService.updateUser( form.UserID, userData )>
    <cfset userID = form.UserID>
<cfelse>
    <!--- Create user --->
    <cfset result = usersService.createUser( userData )>
    <cfset userID = result.userID>
</cfif>

<cfif result.success>
    <!--- Handle flag assignments --->
    <cfif structKeyExists(form, "Flags")>
        <!--- Get current flags for user --->
        <cfset currentFlagsResult = flagsService.getUserFlags(userID)>
        <cfset currentFlags = currentFlagsResult.data>
        <cfset currentFlagIDs = []>
        <cfloop from="1" to="#arrayLen(currentFlags)#" index="i">
            <cfset arrayAppend(currentFlagIDs, val(currentFlags[i].FLAGID))>
        </cfloop>
        
        <!--- Parse the submitted flags (ColdFusion sends as comma-delimited list) --->
        <cfset submittedFlagIDs = []>
        <cfif isArray(form.Flags)>
            <!--- If it's already an array, process directly --->
            <cfloop from="1" to="#arrayLen(form.Flags)#" index="i">
                <cfset arrayAppend(submittedFlagIDs, val(form.Flags[i]))>
            </cfloop>
        <cfelse>
            <!--- If it's a list string, split by comma --->
            <cfset flagList = listToArray(form.Flags)>
            <cfloop from="1" to="#arrayLen(flagList)#" index="i">
                <cfset arrayAppend(submittedFlagIDs, val(trim(flagList[i])))>
            </cfloop>
        </cfif>
        
        <!--- Remove flags that were unchecked --->
        <cfloop from="1" to="#arrayLen(currentFlagIDs)#" index="i">
            <cfif arrayFindNoCase(submittedFlagIDs, currentFlagIDs[i]) == 0>
                <cfset flagsService.removeFlag(userID, val(currentFlagIDs[i]))>
            </cfif>
        </cfloop>
        
        <!--- Add flags that were checked --->
        <cfloop from="1" to="#arrayLen(submittedFlagIDs)#" index="i">
            <cfif arrayFindNoCase(currentFlagIDs, submittedFlagIDs[i]) == 0>
                <cfset flagsService.addFlag(userID, val(submittedFlagIDs[i]))>
            </cfif>
        </cfloop>
    <cfelse>
        <!--- No flags submitted, remove all existing flags --->
        <cfset currentFlagsResult = flagsService.getUserFlags(userID)>
        <cfset currentFlags = currentFlagsResult.data>
        <cfloop from="1" to="#arrayLen(currentFlags)#" index="i">
            <cfset flagsService.removeFlag(userID, val(currentFlags[i].FLAGID))>
        </cfloop>
    </cfif>

    <!--- Handle organization assignments when org controls are present on the form --->
    <cfif structKeyExists(form, "processOrganizations")>
        <cfset currentOrgsResult = organizationsService.getUserOrgs(userID)>
        <cfset currentOrgs = currentOrgsResult.data>
        <cfset currentOrgIDs = []>
        <cfset currentOrgMap  = {}>
        <cfloop from="1" to="#arrayLen(currentOrgs)#" index="i">
            <cfset arrayAppend(currentOrgIDs, val(currentOrgs[i].ORGID))>
            <cfset currentOrgMap[val(currentOrgs[i].ORGID)] = true>
        </cfloop>

        <cfset submittedOrgIDs = []>
        <cfset submittedOrgMap  = {}>
        <cfif structKeyExists(form, "Organizations")>
            <cfif isArray(form.Organizations)>
                <cfloop from="1" to="#arrayLen(form.Organizations)#" index="i">
                    <cfset arrayAppend(submittedOrgIDs, val(form.Organizations[i]))>
                    <cfset submittedOrgMap[val(form.Organizations[i])] = true>
                </cfloop>
            <cfelse>
                <cfset orgList = listToArray(form.Organizations)>
                <cfloop from="1" to="#arrayLen(orgList)#" index="i">
                    <cfset arrayAppend(submittedOrgIDs, val(trim(orgList[i])))>
                    <cfset submittedOrgMap[val(trim(orgList[i]))] = true>
                </cfloop>
            </cfif>
        </cfif>

        <cfloop from="1" to="#arrayLen(currentOrgIDs)#" index="i">
            <cfif NOT structKeyExists(submittedOrgMap, currentOrgIDs[i])>
                <cfset organizationsService.removeOrg(userID, val(currentOrgIDs[i]))>
            </cfif>
        </cfloop>

        <cfloop from="1" to="#arrayLen(submittedOrgIDs)#" index="i">
            <cfset orgID     = val(submittedOrgIDs[i])>
            <cfset roleTitle = structKeyExists(form, "roleTitle_" & orgID) ? trim(form["roleTitle_" & orgID]) : "">
            <cfset roleOrder = (structKeyExists(form, "roleOrder_" & orgID) AND isNumeric(form["roleOrder_" & orgID])) ? val(form["roleOrder_" & orgID]) : 0>
            <cfif NOT structKeyExists(currentOrgMap, orgID)>
                <cfset organizationsService.assignOrg(userID, orgID, roleTitle, roleOrder)>
            <cfelse>
                <cfset organizationsService.updateOrgAssignment(userID, orgID, roleTitle, roleOrder)>
            </cfif>
        </cfloop>
    </cfif>

    <!--- Handle external ID assignments --->
    <cfif structKeyExists(form, "processExternalIDs")>
        <cfset externalIDService = createObject("component", "cfc.externalID_service").init()>
        <cfset allSystemsResult = externalIDService.getSystems()>
        <cfset extSystems = allSystemsResult.data>
        <cfloop from="1" to="#arrayLen(extSystems)#" index="i">
            <cfset sys = extSystems[i]>
            <cfset fieldName = "extID_" & sys.SYSTEMID>
            <cfif structKeyExists(form, fieldName) AND len(trim(form[fieldName]))>
                <cfset externalIDService.setExternalID(userID, sys.SYSTEMID, trim(form[fieldName]))>
            </cfif>
        </cfloop>
    </cfif>

    <!--- Handle academic info --->
    <cfif structKeyExists(form, "processAcademicInfo")>
        <cfset academicService = createObject("component", "cfc.academic_service").init()>
        <cfset academicService.saveAcademicInfo(
            userID,
            structKeyExists(form, "CurrentGradYear")  ? trim(form.CurrentGradYear)  : "",
            structKeyExists(form, "OriginalGradYear") ? trim(form.OriginalGradYear) : ""
        )>
    </cfif>
    
    <!--- Handle student profile (current students) --->
    <cfif structKeyExists(form, "processStudentProfile")>
        <cfset studentProfileSvc = createObject("component", "cfc.studentProfile_service").init()>
        <cfset studentProfileSvc.saveProfile(
            userID,
            structKeyExists(form, "sp_first_externship")  ? trim(form.sp_first_externship)  : "",
            structKeyExists(form, "sp_second_externship") ? trim(form.sp_second_externship) : "",
            structKeyExists(form, "sp_commencement_age")  ? trim(form.sp_commencement_age)  : ""
        )>
    </cfif>

    <!--- Handle bio (public-facing users) --->
    <cfif structKeyExists(form, "processBio")>
        <cfset bioSvc = createObject("component", "cfc.bio_service").init()>
        <cfset bioSvc.saveBio(userID, structKeyExists(form, "bioContent") ? form.bioContent : "")>
    </cfif>

    <!--- Handle degrees (Faculty / Emeritus / Resident) --->
    <cfif structKeyExists(form, "processDegrees")>
        <cfset degreesSvc = createObject("component", "cfc.degrees_service").init()>
        <!--- Collect degree rows from whichever tab prefix is present (fac, emer, or res) --->
        <cfset degreesToSave = []>
        <cfloop list="bio,fac,emer,res,sp" index="pfx">
            <cfset pfxCount = (structKeyExists(form, "#pfx#_degree_count") AND isNumeric(form["#pfx#_degree_count"])) ? val(form["#pfx#_degree_count"]) : 0>
            <cfif pfxCount GT 0>
                <cfloop from="0" to="#pfxCount - 1#" index="di">
                    <cfset dName = structKeyExists(form, "#pfx#_deg_name_#di#") ? trim(form["#pfx#_deg_name_#di#"]) : "">
                    <cfset dUniv = structKeyExists(form, "#pfx#_deg_univ_#di#") ? trim(form["#pfx#_deg_univ_#di#"]) : "">
                    <cfset dYear = structKeyExists(form, "#pfx#_deg_year_#di#") ? trim(form["#pfx#_deg_year_#di#"]) : "">
                    <cfif len(dName)>
                        <cfset arrayAppend(degreesToSave, { name=dName, university=dUniv, year=dYear })>
                    </cfif>
                </cfloop>
                <cfbreak>
            </cfif>
        </cfloop>
        <cfset degreesSvc.replaceDegrees(userID, degreesToSave)>
        <!--- Auto-update the composite Degrees field on the Users table --->
        <cfset compositeStr = degreesSvc.buildDegreesString(userID)>
        <cfset usersService.updateDegreesField(userID, compositeStr)>
    </cfif>

    <!--- Emails, phones, addresses, aliases now saved via AJAX (saveSection.cfm) --->

    <cfset redirectTo = (structKeyExists(form, "returnTo") AND len(trim(form.returnTo))) ? trim(form.returnTo) : "/admin/users/index.cfm">
    <cflocation url="#redirectTo#" addtoken="false">
<cfelse>
    <cfoutput><h2>Error: #result.message#</h2></cfoutput>
</cfif>