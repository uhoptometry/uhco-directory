<cfsilent>
<!---
  auth_windows_start.cfm
  User-initiated Windows SSO entry point (Anonymous access — no IIS Windows Auth required here).
  Only reached when the user explicitly clicks "Login via Windows".
  If already logged in, sends directly to dashboard.
  Otherwise routes to the Windows-auth scoped callback.
--->
</cfsilent>
<cfset windowsSSOEnabled = structKeyExists(application, "flags")
  AND structKeyExists(application.flags, "windowsSSOEnabled")
  AND application.flags.windowsSSOEnabled>

<cfif NOT windowsSSOEnabled>
  <cflocation url="#request.webRoot#/admin/login.cfm?error=windows_unavailable" addtoken="false">
</cfif>

<cfif application.authService.isLoggedIn()>
  <cflocation url="#request.webRoot#/admin/dashboard.cfm" addtoken="false">
</cfif>

<cflocation url="#request.webRoot#/admin/auth_windows_callback.cfm" addtoken="false">
