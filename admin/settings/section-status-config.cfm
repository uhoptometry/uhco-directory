<cfscript>
settingsSectionStatuses = {
    "app-config" = "BETA",
    "admin-permissions" = "BETA",
    "admin-users" = "BETA",
    "admin-roles" = "BETA",
    "user-review" = "BETA",
    "media-config" = "BETA",
    "uhco-api" = "BETA",
    "migrations" = "BETA",
    "rosters" = "ALPHA",
    "scheduled-tasks" = "ALPHA",
    "import" = "ALPHA",
    "bulk-exclusions" = "ALPHA",
    "uh-sync" = "ALPHA",
    "query-builder" = "ALPHA",
    "workflows" = ""
};

function getSettingsSectionStatus(required string sectionKey) {
    var key = lCase(trim(arguments.sectionKey));
    var rawStatus = trim(settingsSectionStatuses[key] ?: "");
    var normalizedStatus = uCase(rawStatus);

    if (normalizedStatus EQ "ALPHA") {
        return "Alpha";
    }

    if (normalizedStatus EQ "BETA") {
        return "Beta";
    }

    return "";
}
</cfscript>
