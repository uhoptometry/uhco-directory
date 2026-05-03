<cfsilent>
<cfsetting showdebugoutput="false">
<!---
  auth_windows_callback.cfm
  Windows Authentication callback handler — scoped to Windows Auth in IIS.
  Reads IIS-provided identity, authenticates via AuthService, and creates session.
  On failure redirects back to login with a Windows-specific error code.
  Never collects or stores passwords.
--->

<cfset windowsSSOEnabled = structKeyExists(application, "flags")
  AND structKeyExists(application.flags, "windowsSSOEnabled")
  AND application.flags.windowsSSOEnabled>

<cfif NOT windowsSSOEnabled>
  <cflocation url="#request.webRoot#/admin/login.cfm?error=windows_unavailable" addtoken="false">
</cfif>

<cfset remoteUser = "">

<!--- Primary: IIS/CGI header --->
<cfif len(trim(CGI.REMOTE_USER))>
  <cfset remoteUser = trim(CGI.REMOTE_USER)>
<cfelse>
  <!--- Fallback: Java servlet identity --->
  <cftry>
    <cfset remoteUser = trim(getPageContext().getRequest().getRemoteUser() & "")>
    <cfcatch type="any">
      <cfset remoteUser = "">
    </cfcatch>
  </cftry>
</cfif>

<!--- No identity supplied by IIS --->
<cfif NOT len(remoteUser)>
  <cflocation url="#request.webRoot#/admin/login.cfm?error=windows_unavailable" addtoken="false">
</cfif>

<!--- Already authenticated — skip re-auth --->
<cfif application.authService.isLoggedIn()>
  <cflocation url="#request.webRoot#/admin/dashboard.cfm" addtoken="false">
</cfif>

<cfset authResult = application.authService.authenticateWindowsIntegrated(remoteUser)>
</cfsilent>

<cfif authResult.success>
  <cflocation url="#request.webRoot#/admin/dashboard.cfm" addtoken="false">
<cfelse>
  <cflocation url="#request.webRoot#/admin/login.cfm?error=windows_failed" addtoken="false">
</cfif>
