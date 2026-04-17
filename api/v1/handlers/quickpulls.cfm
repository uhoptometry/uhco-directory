<!---
    GET /api/v1/quickpulls/{type}

    Quick-pull endpoints return curated subsets of user data
    filtered by flag, without the overhead of full profiles.

    Types:
        attending  — Clinical-Attending users (token only)
        gradclass  — Alumni by grad year   (token + secret, ?year= required)
        graduate   — Single Alumni by UserID   (token + secret, ?id= required)
        deans      — Deans with kiosk image (token only)
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

        <cfset data = qpService.getGradClass(gradYear)>
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

    <!--- ── Unknown type ──────────────────────────────────────────── --->
    <cfdefaultcase>
        <cfset auth.sendError(404, "Unknown quickpull type: #EncodeForHTML(qpType)#")>
    </cfdefaultcase>

</cfswitch>
