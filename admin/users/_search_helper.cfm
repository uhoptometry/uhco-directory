<!---
    _search_helper.cfm
    Defines userMatchesSearch(u, searchTerm) for user-list pages.

    Supported syntax:
      Plain text          → contains match on firstname, lastname, or either email
      "value"             → exact match on any field  (e.g. "Ha")
      field:value         → contains match on a specific field  (e.g. lastname:Ha)
      field:"value"       → exact match on a specific field     (e.g. lastname:"Ha")
      field:(value)       → exact match on a specific field     (e.g. lastname:(Ha))
      term1 && term2      → both conditions must match (AND)
      term1 || term2      → either condition must match (OR)

    Supported field names (case-insensitive):
      firstname, lastname, email, primaryemail / emailprimary,
      secondaryemail / emailsecondary, title
--->
<cffunction name="userMatchesSearch" returntype="boolean" output="false">
    <cfargument name="u"          type="struct" required="true">
    <cfargument name="searchTerm" type="string" required="true">

    <cfset var st = trim(arguments.searchTerm)>
    <cfif NOT len(st)><cfreturn true></cfif>

    <!--- Split on || → OR groups (use chr(30) as safe interim delimiter) --->
    <cfset var orParts = listToArray(replace(st, "||", chr(30), "all"), chr(30))>

    <cfset var oi          = 0>
    <cfset var ai          = 0>
    <cfset var orPart      = "">
    <cfset var andParts    = []>
    <cfset var cond        = "">
    <cfset var colonPos    = 0>
    <cfset var fieldName   = "">
    <cfset var fieldVal    = "">
    <cfset var exactMatch  = false>
    <cfset var andMatch    = false>
    <cfset var condMatches = false>

    <cfloop from="1" to="#arrayLen(orParts)#" index="oi">
        <cfset orPart = trim(orParts[oi])>
        <cfif NOT len(orPart)><cfcontinue></cfif>

        <!--- Split on && → AND conditions --->
        <cfset andParts = listToArray(replace(orPart, "&&", chr(31), "all"), chr(31))>
        <cfset andMatch = true>

        <cfloop from="1" to="#arrayLen(andParts)#" index="ai">
            <cfset cond = trim(andParts[ai])>
            <cfif NOT len(cond)><cfcontinue></cfif>

            <cfset colonPos = find(":", cond)>

            <cfif colonPos GT 1>
                <!--- field:value operator --->
                <cfset fieldName  = lCase(trim(left(cond, colonPos - 1)))>
                <cfset fieldVal   = trim(mid(cond, colonPos + 1, len(cond)))>

                <!--- Detect exact-match wrappers: "value" or (value) --->
                <cfset exactMatch = false>
                <cfif (left(fieldVal,1) EQ '"'  AND right(fieldVal,1) EQ '"')  OR
                      (left(fieldVal,1) EQ "("  AND right(fieldVal,1) EQ ")")>
                    <cfset exactMatch = true>
                    <cfset fieldVal   = trim(mid(fieldVal, 2, len(fieldVal) - 2))>
                </cfif>

                <cfset condMatches = false>
                <cfif fieldName EQ "firstname">
                    <cfset condMatches = exactMatch
                        ? (lCase(arguments.u.FIRSTNAME ?: "") EQ lCase(fieldVal))
                        : findNoCase(fieldVal, arguments.u.FIRSTNAME ?: "")>
                <cfelseif fieldName EQ "lastname">
                    <cfset condMatches = exactMatch
                        ? (lCase(arguments.u.LASTNAME ?: "") EQ lCase(fieldVal))
                        : findNoCase(fieldVal, arguments.u.LASTNAME ?: "")>
                <cfelseif fieldName EQ "emailprimary" OR fieldName EQ "primaryemail">
                    <cfset condMatches = exactMatch
                        ? (lCase(arguments.u.EMAILPRIMARY ?: "") EQ lCase(fieldVal))
                        : findNoCase(fieldVal, arguments.u.EMAILPRIMARY ?: "")>
                <cfelseif fieldName EQ "emailsecondary" OR fieldName EQ "secondaryemail">
                    <cfset condMatches = exactMatch
                        ? (lCase(arguments.u.EMAILSECONDARY ?: "") EQ lCase(fieldVal))
                        : findNoCase(fieldVal, arguments.u.EMAILSECONDARY ?: "")>
                <cfelseif fieldName EQ "email">
                    <cfif exactMatch>
                        <cfset condMatches = (lCase(arguments.u.EMAILPRIMARY ?: "") EQ lCase(fieldVal)) OR
                                             (lCase(arguments.u.EMAILSECONDARY ?: "") EQ lCase(fieldVal))>
                    <cfelse>
                        <cfset condMatches = findNoCase(fieldVal, arguments.u.EMAILPRIMARY ?: "") OR
                                             findNoCase(fieldVal, arguments.u.EMAILSECONDARY ?: "")>
                    </cfif>
                <cfelseif fieldName EQ "title">
                    <cfset condMatches = exactMatch
                        ? (lCase(arguments.u.TITLE1 ?: "") EQ lCase(fieldVal))
                        : findNoCase(fieldVal, arguments.u.TITLE1 ?: "")>
                <cfelse>
                    <!--- Unknown field: fall back to any-field match on the full original token --->
                    <cfset condMatches = findNoCase(cond, arguments.u.FIRSTNAME ?: "") OR
                                         findNoCase(cond, arguments.u.LASTNAME  ?: "") OR
                                         findNoCase(cond, arguments.u.EMAILPRIMARY ?: "") OR
                                         findNoCase(cond, arguments.u.EMAILSECONDARY ?: "")>
                </cfif>

            <cfelse>
                <!--- Plain text: detect exact-match wrappers --->
                <cfset exactMatch = false>
                <cfif (left(cond,1) EQ '"'  AND right(cond,1) EQ '"')  OR
                      (left(cond,1) EQ "("  AND right(cond,1) EQ ")")>
                    <cfset exactMatch = true>
                    <cfset cond = trim(mid(cond, 2, len(cond) - 2))>
                </cfif>

                <cfif exactMatch>
                    <cfset condMatches = (lCase(arguments.u.FIRSTNAME ?: "") EQ lCase(cond)) OR
                                         (lCase(arguments.u.LASTNAME  ?: "") EQ lCase(cond)) OR
                                         (lCase(arguments.u.EMAILPRIMARY ?: "") EQ lCase(cond)) OR
                                         (lCase(arguments.u.EMAILSECONDARY ?: "") EQ lCase(cond))>
                <cfelse>
                    <cfset condMatches = findNoCase(cond, arguments.u.FIRSTNAME ?: "") OR
                                         findNoCase(cond, arguments.u.LASTNAME  ?: "") OR
                                         findNoCase(cond, arguments.u.EMAILPRIMARY ?: "") OR
                                         findNoCase(cond, arguments.u.EMAILSECONDARY ?: "")>
                </cfif>
            </cfif>

            <cfif NOT condMatches>
                <cfset andMatch = false>
                <cfbreak>
            </cfif>
        </cfloop>

        <cfif andMatch>
            <cfreturn true>
        </cfif>
    </cfloop>

    <cfreturn false>
</cffunction>

<!--- ── Search help modal (rendered once per page via cfinclude) ── --->
<div class="modal fade" id="searchHelpModal" tabindex="-1" aria-labelledby="searchHelpModalLabel" aria-hidden="true">
  <div class="modal-dialog modal-lg">
    <div class="modal-content">
      <div class="modal-header">
        <h5 class="modal-title" id="searchHelpModalLabel"><i class="bi bi-search me-2"></i>Search Syntax Reference</h5>
        <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
      </div>
      <div class="modal-body">

        <h6 class="fw-bold">Basic Search</h6>
        <p class="text-muted small mb-2">Type any text to search across first name, last name, and both email fields.</p>
        <table class="table table-sm table-bordered mb-4">
          <thead class="table-light"><tr><th>Query</th><th>Matches</th></tr></thead>
          <tbody>
            <tr><td><code>Jane</code></td><td>Any record containing "Jane" in name or email</td></tr>
          </tbody>
        </table>

        <h6 class="fw-bold">Field Operators</h6>
        <p class="text-muted small mb-2">Target a specific field with <code>field:value</code>. Performs a <em>contains</em> search.</p>
        <table class="table table-sm table-bordered mb-4">
          <thead class="table-light"><tr><th>Query</th><th>Matches</th></tr></thead>
          <tbody>
            <tr><td><code>lastname:Doe</code></td><td>Last name contains "Doe"</td></tr>
            <tr><td><code>firstname:Jane</code></td><td>First name contains "Jane"</td></tr>
            <tr><td><code>email:uh.edu</code></td><td>Either email contains "uh.edu"</td></tr>
            <tr><td><code>primaryemail:jdoe@uh.edu</code></td><td>Primary email contains that value</td></tr>
            <tr><td><code>secondaryemail:jdoe@gmail.com</code></td><td>Secondary email contains that value</td></tr>
            <tr><td><code>title:Professor</code></td><td>Title contains "Professor"</td></tr>
          </tbody>
        </table>

        <h6 class="fw-bold">Exact Match</h6>
        <p class="text-muted small mb-2">Wrap the value in <code>"quotes"</code> or <code>(parentheses)</code> to require an exact match (case-insensitive).</p>
        <table class="table table-sm table-bordered mb-4">
          <thead class="table-light"><tr><th>Query</th><th>Matches</th></tr></thead>
          <tbody>
            <tr><td><code>lastname:"Ha"</code></td><td>Last name is exactly "Ha" — not "Ham", "Shah", etc.</td></tr>
            <tr><td><code>lastname:(Ha)</code></td><td>Same as above</td></tr>
            <tr><td><code>"Ha"</code></td><td>Any field is exactly "Ha"</td></tr>
          </tbody>
        </table>

        <h6 class="fw-bold">AND / OR Operators</h6>
        <p class="text-muted small mb-2">Combine conditions with <code>&amp;&amp;</code> (AND) or <code>||</code> (OR).</p>
        <table class="table table-sm table-bordered mb-0">
          <thead class="table-light"><tr><th>Query</th><th>Matches</th></tr></thead>
          <tbody>
            <tr><td><code>firstname:Jane &amp;&amp; lastname:Doe</code></td><td>First name contains "Jane" AND last name contains "Doe"</td></tr>
            <tr><td><code>firstname:"Jane" &amp;&amp; lastname:"Doe"</code></td><td>First name is exactly "Jane" AND last name is exactly "Doe"</td></tr>
            <tr><td><code>firstname:Jane || firstname:John</code></td><td>First name contains "Jane" OR "John"</td></tr>
            <tr><td><code>lastname:"Ha" || lastname:"Ho"</code></td><td>Last name is exactly "Ha" OR exactly "Ho"</td></tr>
          </tbody>
        </table>

      </div>
      <div class="modal-footer">
        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
      </div>
    </div>
  </div>
</div>
