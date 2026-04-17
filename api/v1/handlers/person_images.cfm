<!--- GET /api/v1/people/{id}/images --->
<cfset auth.requireAuth("read")>
<cfset imagesService = createObject("component", "cfc.images_service").init()>
<cfset result = imagesService.getImages(val(resourceID))>
<cfset auth.sendResponse({ userID: val(resourceID), data: result.data })>
<cfabort>
