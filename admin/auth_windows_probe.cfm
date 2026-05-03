<cfsilent>
<cfsetting showdebugoutput="false">
<!---
  auth_windows_probe.cfm
  Windows Authentication capability probe — user-initiated only (called via JS fetch).
  This endpoint must be scoped to Windows Authentication in IIS so that IIS provides
  the caller's Windows identity when available (Negotiate/NTLM).
  Returns JSON {"available":true} or {"available":false}.
  No session writes. No redirects. No passwords.
--->

<cfset windowsSSOEnabled = structKeyExists(application, "flags")
  AND structKeyExists(application.flags, "windowsSSOEnabled")
  AND application.flags.windowsSSOEnabled>

<cfif NOT windowsSSOEnabled>
  <cfset available = false>
  <cfcontent type="application/json; charset=utf-8"><cfoutput>{"available":false}</cfoutput><cfabort>
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

<cfset available = (len(remoteUser) GT 0)>
</cfsilent>
<cfcontent type="application/json; charset=utf-8"><cfoutput>{"available":#(available ? "true" : "false")#}</cfoutput>
