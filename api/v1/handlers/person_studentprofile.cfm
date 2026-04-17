<!--- GET /dir/api/v1/people/{id}/studentprofile --->
<cfset auth.requireAuth("read")>
<cfset studentProfileSvc = createObject("component", "cfc.studentProfile_service").init()>
<cfset profile = studentProfileSvc.getProfile(val(resourceID))>
<cfset awards  = studentProfileSvc.getAwards(val(resourceID))>
<cfset auth.sendResponse({ userID: val(resourceID), profile: profile.data, awards: awards.data })>
<cfabort>
