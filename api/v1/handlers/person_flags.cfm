<!--- GET /dir/api/v1/people/{id}/flags --->
<cfset auth.requireAuth("read")>
<cfset flagsService = createObject("component", "cfc.flags_service").init()>
<cfset result = flagsService.getUserFlags(val(resourceID))>
<cfset auth.sendResponse({ userID: val(resourceID), data: result.data })>
<cfabort>
