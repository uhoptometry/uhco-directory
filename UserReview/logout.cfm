<cfset userReviewAuth = structKeyExists(request, "userReviewAuth") ? request.userReviewAuth : createObject("component", "cfc.UserReviewAuthService").init()>
<cfset userReviewAuth.logout()>
<cflocation url="/UserReview/login.cfm?msg=#urlEncodedFormat('You have been signed out.')#" addtoken="false">