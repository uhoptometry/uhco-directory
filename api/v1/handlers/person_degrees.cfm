<!--- GET /dir/api/v1/people/{id}/degrees --->
<cfset auth.requireAuth("read")>
<cfset degreesService = createObject("component", "cfc.degrees_service").init()>
<cfset result = degreesService.getDegrees(val(resourceID))>
<cfset auth.sendResponse({ userID: val(resourceID), data: result.data })>
<cfabort>
