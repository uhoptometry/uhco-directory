<cfset sortColumn = structKeyExists(url, "sortCol") ? url.sortCol : "LASTNAME">
<cfset sortDirection = structKeyExists(url, "sortDir") ? url.sortDir : "ASC">

<!--- Sort the users array --->
<cfif sortColumn == "FIRSTNAME">
    <cfset arraySort(filteredUsers, function(a, b) {
        return compare(a.FIRSTNAME, b.FIRSTNAME) * (sortDirection == "DESC" ? -1 : 1);
    })>
<cfelseif sortColumn == "LASTNAME">
    <cfset arraySort(filteredUsers, function(a, b) {
        return compare(a.LASTNAME, b.LASTNAME) * (sortDirection == "DESC" ? -1 : 1);
    })>

<cfelseif sortColumn == "EMAIL">
    <cfset arraySort(filteredUsers, function(a, b) {
        var emailA = len(a.EMAILPRIMARY) ? a.EMAILPRIMARY : '';
        var emailB = len(b.EMAILPRIMARY) ? b.EMAILPRIMARY : '';
        return compare(emailA, emailB) * (sortDirection == "DESC" ? -1 : 1);
    })>
</cfif>