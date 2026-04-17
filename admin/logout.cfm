<cfset application.authService.logout()>
<cflocation url="#request.webRoot#/admin/login.cfm" addtoken="false">