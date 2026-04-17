<cfparam name="form.username" default="">
<cfparam name="form.password" default="">

<cfif !len(form.username) OR !len(form.password)>
  <cflocation url="login.cfm?error=missing" addtoken="false">
</cfif>

<cfset authResult = application.authService.authenticate(
  username = form.username,
  password = form.password
)>

<cfif authResult.success>
  <cfset application.authService.createSession(authResult.user)>
  <cflocation url="#request.webRoot#/admin/dashboard.cfm" addtoken="false">
<cfelse>
  <cflocation url="login.cfm?error=#urlEncodedFormat(authResult.message)#" addtoken="false">
</cfif>