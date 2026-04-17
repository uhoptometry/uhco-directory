<!--- GET /dir/api/v1/people/{id}/bio --->
<cfset auth.requireAuth("read")>
<cfset bioService = createObject("component", "cfc.bio_service").init()>
<cfset result = bioService.getBio(val(resourceID))>
<cfset auth.sendResponse({ userID: val(resourceID), data: result.data })>
<cfabort>
