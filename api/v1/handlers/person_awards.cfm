<!--- GET /dir/api/v1/people/{id}/awards --->
<cfset auth.requireAuth("read")>
<cfset studentProfileSvc = createObject("component", "cfc.studentProfile_service").init()>
<cfset result = studentProfileSvc.getAwards(val(resourceID))>
<cfset auth.sendResponse({ userID: val(resourceID), data: result.data })>
<cfabort>
