<!--- GET /dir/api/v1/people/{id}/academic --->
<cfset auth.requireAuth("read")>
<cfset acadService = createObject("component", "cfc.academic_service").init()>
<cfset degSvc = createObject("component", "cfc.degrees_service").init()>
<cfset result = acadService.getAcademicInfo(val(resourceID))>
<cfset effectiveGradYear = degSvc.getEffectiveGradYear(val(resourceID))>
<cfset responseData = structCopy(result.data)>
<cfset responseData["effectiveGradYear"] = effectiveGradYear>
<cfset auth.sendResponse({ userID: val(resourceID), data: responseData })>
<cfabort>
