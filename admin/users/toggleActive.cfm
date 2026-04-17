<!---
    toggleActive.cfm

    Accepts POST:
        userID  — required numeric
        active  — required, 0 or 1

    Returns JSON:
        { "success": true/false, "active": 0|1, "message": "..." }
--->
<cfsetting showdebugoutput="false">
<cfheader name="Content-Type" value="application/json; charset=utf-8">

<!--- Only allow POST --->
<cfif cgi.REQUEST_METHOD NEQ "POST">
    <cfoutput>{"success":false,"message":"Method not allowed."}</cfoutput>
    <cfabort>
</cfif>

<cfparam name="form.userID" default="0">
<cfparam name="form.active" default="">

<!--- Validate userID --->
<cfif NOT (isNumeric(form.userID) AND val(form.userID) GT 0)>
    <cfoutput>{"success":false,"message":"Invalid user ID."}</cfoutput>
    <cfabort>
</cfif>

<!--- Validate active value: must be 0 or 1 --->
<cfif NOT (isNumeric(form.active) AND listFind("0,1", val(form.active)))>
    <cfoutput>{"success":false,"message":"Invalid active value."}</cfoutput>
    <cfabort>
</cfif>

<cfset targetUserID = val(form.userID)>
<cfset newActive    = val(form.active)>

<cftry>
    <cfset usersDAO = createObject("component", "dao.users_DAO").init()>

    <!--- Verify the user exists --->
    <cfset existingUser = usersDAO.getUserByID(targetUserID)>
    <cfif structIsEmpty(existingUser)>
        <cfoutput>{"success":false,"message":"User not found."}</cfoutput>
        <cfabort>
    </cfif>

    <!--- Update only the Active field --->
    <cfquery datasource="#request.datasource#">
        UPDATE Users
        SET    Active    = <cfqueryparam value="#newActive#" cfsqltype="cf_sql_integer">,
               UpdatedAt = GETDATE()
        WHERE  UserID   = <cfqueryparam value="#targetUserID#" cfsqltype="cf_sql_integer">
    </cfquery>

    <cfoutput>{"success":true,"active":#newActive#,"message":"Status updated."}</cfoutput>

<cfcatch>
    <cfoutput>{"success":false,"message":"An error occurred: #jsStringFormat(cfcatch.message)#"}</cfoutput>
</cfcatch>
</cftry>
