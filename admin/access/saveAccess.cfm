<cfquery datasource="#request.datasource#">
    INSERT INTO AccessAreas (AccessName)
    VALUES (<cfqueryparam value="#form.AccessName#" cfsqltype="cf_sql_varchar">)
</cfquery>

<cflocation url="#request.webRoot#/admin/access/index.cfm" addtoken="false">