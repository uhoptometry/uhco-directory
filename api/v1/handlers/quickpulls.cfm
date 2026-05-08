<!---
    GET /api/v1/quickpulls/{type}

    Quick-pull endpoints return curated subsets of user data
    filtered by flag, without the overhead of full profiles.

    Types:
        attending       — Clinical-Attending users (token only)
        gradclass       — Alumni by grad year   (token + secret, ?year= required)
        graduate        — Single Alumni by UserID   (token + secret, ?id= required)
        deans           — Deans with kiosk image (token only)
        myuhco          — MyUHCO profile by external ID (token + optional secret)
        myuhco-rosters  — MyUHCO roster PDF metadata catalog (token + secret)
--->
<cfset auth.requireAuth("read")>

<cfset qpService = createObject("component", "cfc.quickpull_service").init()>
<cfset qpType    = lCase(trim(resourceID))>

<cfswitch expression="#qpType#">

    <!--- ── Attending ─────────────────────────────────────────────── --->
    <cfcase value="attending">
        <cfset data = qpService.getAttending()>
        <cfset auth.sendResponse({ total: arrayLen(data), data: data })>
        <cfabort>
    </cfcase>

    <!--- ── Grad Class ────────────────────────────────────────────── --->
    <cfcase value="gradclass">
        <cfset allowedPrograms = ["OD Program", "PhD Program", "MS Program", "All"]>
        <cfset allowedLastNameFilters = ["A-C", "D-G", "H-K", "L-M", "N-P", "Q-S", "T-Z"]>

        <!--- Require secret that unlocks Alumni --->
        <cfset unlockedFlags = auth.checkSecret()>
        <cfif NOT arrayFindNoCase(unlockedFlags, "Alumni")>
            <cfset auth.sendError(401, "A valid secret with Alumni access is required")>
        </cfif>

        <!--- Require ?year= parameter --->
        <cfif NOT len(trim(url.year ?: "")) OR NOT isNumeric(url.year ?: "")>
            <cfset auth.sendError(400, "Missing or invalid required parameter: year")>
        </cfif>
        <cfset gradYear = int(val(url.year))>

        <!--- Require ?program= parameter --->
        <cfset programName = trim(url.program ?: "")>
        <cfif NOT len(programName)>
            <cfset auth.sendError(400, "Missing required parameter: program")>
        </cfif>
        <cfif NOT arrayFindNoCase(allowedPrograms, programName)>
            <cfset auth.sendError(400, "Invalid program. Allowed values: OD Program, PhD Program, MS Program, All")>
        </cfif>
        <cfif compareNoCase(programName, "all") EQ 0>
            <cfset programName = "All">
        </cfif>

        <!--- Optional ?filter= parameter for last name initial range --->
        <cfset lastNameFilter = uCase(trim(url.filter ?: ""))>
        <cfif len(lastNameFilter) AND NOT arrayFindNoCase(allowedLastNameFilters, lastNameFilter)>
            <cfset auth.sendError(400, "Invalid filter. Allowed values: A-C, D-G, H-K, L-M, N-P, Q-S, T-Z")>
        </cfif>

        <cfset data = qpService.getGradClass(gradYear, programName, lastNameFilter)>
        <cfset auth.sendResponse({ total: arrayLen(data), data: data })>
        <cfabort>
    </cfcase>

    <!--- ── Graduate ──────────────────────────────────────────────── --->
    <cfcase value="graduate">
        <!--- Require secret that unlocks Alumni --->
        <cfset unlockedFlags = auth.checkSecret()>
        <cfif NOT arrayFindNoCase(unlockedFlags, "Alumni")>
            <cfset auth.sendError(401, "A valid secret with Alumni access is required")>
        </cfif>

        <!--- Require ?id= parameter (UserID) --->
        <cfif NOT len(trim(url.id ?: "")) OR NOT isNumeric(url.id ?: "")>
            <cfset auth.sendError(400, "Missing or invalid required parameter: id")>
        </cfif>
        <cfset userID = int(val(url.id))>

        <cfset data = qpService.getGraduate(userID)>
        <cfset auth.sendResponse({ userID: userID, data: data })>
        <cfabort>
    </cfcase>

    <!--- ── Deans ─────────────────────────────────────────────────── --->
    <cfcase value="deans">
        <cfset data = qpService.getDeans()>
        <cfset auth.sendResponse({ total: arrayLen(data), data: data })>
        <cfabort>
    </cfcase>

    <!--- ── MyUHCO ────────────────────────────────────────────────── --->
    <cfcase value="myuhco">
        <!--- Require secret that unlocks Alumni/Current-Student --->
        <cfset unlockedFlags = auth.checkSecret()>
        <cfset hasAlumniAccess = arrayFindNoCase(unlockedFlags, "Alumni") GT 0>
        <cfset hasStudentAccess = arrayFindNoCase(unlockedFlags, "Current-Student") GT 0>
        <cfset isAuthorized = hasAlumniAccess OR hasStudentAccess>

        <!--- Require ?id= parameter (external ID value) --->
        <cfif NOT len(trim(url.id ?: "")) OR NOT len(url.id)>
            <cfset auth.sendError(400, "Missing required parameter: id (external ID value)")>
        </cfif>
        <cfset externalID = trim(url.id)>

        <cfset data = qpService.getMyUHCO(externalID, isAuthorized)>

        <cfif structIsEmpty(data)>
            <cfset auth.sendError(404, "User not found or not authorized")>
        </cfif>

        <cfset auth.sendResponse(data)>
        <cfabort>
    </cfcase>

    <!--- ── MyUHCO Roster Catalog ─────────────────────────────────── --->
    <cfcase value="myuhco-rosters,myuhcorosters">
        <cfset unlockedFlags = auth.checkSecret()>
        <cfset hasAlumniAccess = arrayFindNoCase(unlockedFlags, "Alumni") GT 0>
        <cfset hasStudentAccess = arrayFindNoCase(unlockedFlags, "Current-Student") GT 0>

        <cfif NOT (hasAlumniAccess OR hasStudentAccess)>
            <cfset auth.sendError(401, "A valid secret with Alumni or Current-Student access is required")>
        </cfif>

        <cfset publishedOnly = listFindNoCase("1,true,yes,on", trim(url.publishedOnly ?: "")) GT 0>
        <cfset data = qpService.getMyUHCORosterCatalog(publishedOnly)>

        <cfset auth.sendResponse({
            total: arrayLen(data),
            publishedOnly: publishedOnly,
            data: data
        })>
        <cfabort>
    </cfcase>

    <!--- ── Unknown type ──────────────────────────────────────────── --->
    <cfdefaultcase>
        <cfset auth.sendError(404, "Unknown quickpull type: #EncodeForHTML(qpType)#")>
    </cfdefaultcase>

</cfswitch>
