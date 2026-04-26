<cfsetting showdebugoutput="false">
<cfcontent type="application/json; charset=utf-8" reset="true">

<cfset response = { success = false, message = "Unhandled request." }>
<cfset requestData = {}>
<cfset requestBody = "">
<cfset payload = {}>
<cfset mode = "">
<cfset token = "">
<cfset sessionDir = expandPath("./_form_sessions")>
<cfset reportDir = expandPath("./reports")>
<cfset filePath = "">
<cfset state = {}>
<cfset reportText = "">
<cfset testerName = "">
<cfset reportFileName = "">
<cfset safeTesterName = "">

<cffunction name="jsonOut" access="private" returntype="void" output="false">
    <cfargument name="data" type="struct" required="true">
    <cfoutput>#serializeJSON(arguments.data)#</cfoutput>
    <cfabort>
</cffunction>

<cffunction name="extractMode" access="private" returntype="string" output="false">
    <cfargument name="payload" type="struct" required="true">

    <cfif structKeyExists(url, "mode")>
        <cfreturn lCase(trim(url.mode))>
    </cfif>
    <cfif structKeyExists(form, "mode")>
        <cfreturn lCase(trim(form.mode))>
    </cfif>
    <cfif structKeyExists(arguments.payload, "mode")>
        <cfreturn lCase(trim(arguments.payload.mode))>
    </cfif>

    <cfreturn "">
</cffunction>

<cffunction name="extractToken" access="private" returntype="string" output="false">
    <cfargument name="payload" type="struct" required="true">

    <cfif structKeyExists(url, "token")>
        <cfreturn trim(url.token)>
    </cfif>
    <cfif structKeyExists(form, "token")>
        <cfreturn trim(form.token)>
    </cfif>
    <cfif structKeyExists(arguments.payload, "token")>
        <cfreturn trim(arguments.payload.token)>
    </cfif>

    <cfreturn "">
</cffunction>

<cffunction name="isValidToken" access="private" returntype="boolean" output="false">
    <cfargument name="token" type="string" required="true">
    <cfset var cleanToken = trim(arguments.token)>

    <!--- Allow UUID and simple URL-safe tokens. --->
    <cfreturn reFindNoCase("^[A-Za-z0-9_-]{12,80}$", cleanToken) GT 0>
</cffunction>

<cftry>
    <cfif cgi.request_method EQ "POST">
        <cfset requestData = getHttpRequestData()>
        <cfset requestBody = toString(requestData.content ?: "")>

        <cfif len(trim(requestBody))>
            <cfset payload = deserializeJSON(requestBody)>
            <cfif NOT isStruct(payload)>
                <cfset payload = {}>
            </cfif>
        </cfif>
    </cfif>

    <cfset mode = extractMode(payload)>
    <cfset token = extractToken(payload)>

    <cfif NOT len(mode)>
        <cfset jsonOut({ success = false, message = "Missing mode." })>
    </cfif>

    <cfif NOT isValidToken(token)>
        <cfset jsonOut({ success = false, message = "Invalid token." })>
    </cfif>

    <cfif NOT directoryExists(sessionDir)>
        <cfdirectory action="create" directory="#sessionDir#">
    </cfif>

    <cfif NOT directoryExists(reportDir)>
        <cfdirectory action="create" directory="#reportDir#">
    </cfif>

    <cfset filePath = sessionDir & "/" & token & ".json">

    <cfswitch expression="#mode#">
        <cfcase value="save">
            <cfif NOT structKeyExists(payload, "state") OR NOT isStruct(payload.state)>
                <cfset jsonOut({ success = false, message = "Missing state payload." })>
            </cfif>

            <cfset state = duplicate(payload.state)>
            <cfset state.token = token>
            <cfset state.savedAt = dateTimeFormat(now(), "yyyy-mm-dd'T'HH:nn:ss")>

            <cflock type="exclusive" name="user_admin_test_form_#token#" timeout="5">
                <cffile action="write" file="#filePath#" output="#serializeJSON(state)#" charset="utf-8">
            </cflock>

            <cfset jsonOut({ success = true, message = "Saved.", token = token })>
        </cfcase>

        <cfcase value="load">
            <cfif NOT fileExists(filePath)>
                <cfset jsonOut({ success = true, message = "No saved state.", state = javacast("null", "") })>
            </cfif>

            <cflock type="readonly" name="user_admin_test_form_#token#" timeout="5">
                <cffile action="read" file="#filePath#" variable="requestBody" charset="utf-8">
            </cflock>

            <cfset state = deserializeJSON(requestBody)>
            <cfif NOT isStruct(state)>
                <cfset state = {}>
            </cfif>

            <cfset jsonOut({ success = true, token = token, state = state })>
        </cfcase>

        <cfcase value="savereport">
            <cfif NOT structKeyExists(payload, "reportText")>
                <cfset jsonOut({ success = false, message = "Missing report text." })>
            </cfif>

            <cfset reportText = trim(payload.reportText ?: "")>
            <cfif NOT len(reportText)>
                <cfset jsonOut({ success = false, message = "Report text is empty." })>
            </cfif>

            <cfset testerName = trim(payload.testerName ?: "")>
            <cfif NOT len(testerName)>
                <cfset testerName = "tester">
            </cfif>
            <cfset safeTesterName = lCase(reReplace(testerName, "[^A-Za-z0-9_-]+", "-", "all"))>
            <cfset safeTesterName = reReplace(safeTesterName, "(^-+|-+$)", "", "all")>
            <cfif NOT len(safeTesterName)>
                <cfset safeTesterName = "tester">
            </cfif>

            <cfset reportFileName = "user-admin-summary-" & safeTesterName & "-" & dateFormat(now(), "yyyymmdd") & "-" & timeFormat(now(), "HHmmss") & ".txt">
            <cfset filePath = reportDir & "/" & reportFileName>

            <cflock type="exclusive" name="user_admin_test_form_report_#token#" timeout="5">
                <cffile action="write" file="#filePath#" output="#reportText#" charset="utf-8">
            </cflock>

            <cfset jsonOut({ success = true, message = "Report saved.", fileName = reportFileName })>
        </cfcase>

        <cfdefaultcase>
            <cfset jsonOut({ success = false, message = "Unsupported mode." })>
        </cfdefaultcase>
    </cfswitch>

    <cfcatch type="any">
        <cfset response = {
            success = false,
            message = "Request failed.",
            detail = (cfcatch.message ?: "")
        }>
        <cfoutput>#serializeJSON(response)#</cfoutput>
    </cfcatch>
</cftry>
