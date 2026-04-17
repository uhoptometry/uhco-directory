<!--- GET /dir/api/v1/people/{id}/emails --->
<cfset auth.requireAuth("read")>
<cfset emailsService = createObject("component", "cfc.emails_service").init()>
<cfset result = emailsService.getEmails(val(resourceID))>
<cfset auth.sendResponse({ userID: val(resourceID), data: result.data })>
<cfabort>
