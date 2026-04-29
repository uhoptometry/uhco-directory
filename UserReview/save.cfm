<cfif cgi.request_method NEQ "POST">
    <cflocation url="/UserReview/index.cfm" addtoken="false">
    <cfabort>
</cfif>

<cfset userReviewAuth = structKeyExists(request, "userReviewAuth") ? request.userReviewAuth : createObject("component", "cfc.UserReviewAuthService").init()>

<cfif NOT userReviewAuth.isLoggedIn()>
    <cflocation url="/UserReview/login.cfm" addtoken="false">
    <cfabort>
</cfif>

<cfset userReviewService = createObject("component", "cfc.userReview_service").init()>
<cfset result = userReviewService.saveSubmission(
    actor = userReviewAuth.getSessionUser(),
    formScope = form
)>

<cfif result.success>
    <cflocation url="/UserReview/index.cfm?msg=#urlEncodedFormat(result.message)#" addtoken="false">
<cfelse>
    <cflocation url="/UserReview/index.cfm?error=#urlEncodedFormat(result.message)#" addtoken="false">
</cfif>