component output="false" singleton {

    public any function init() {
        variables.duplicateUsersDAO = createObject("component", "dao.duplicateUsers_DAO").init();
        variables.appConfigService = createObject("component", "cfc.appConfig_service").init();
        variables.usersService = createObject("component", "cfc.users_service").init();
        variables.externalSystemLabelMap = {};
        variables.externalSystemLabelMapLoaded = false;

        variables.signalWeights = {
            users_uh_api_id = 75,
            external_ids = 70,
            users_email_primary = 50,
            emails_address = 50,
            users_name = 35,
            aliases_name = 30,
            phones_number = 25,
            flags_shared = 14,
            aliases_display_name = 20,
            academic_multi_grad_year = 18,
            flags_faculty_alumni_split = 18,
            addresses_location = 15,
            organizations_shared = 8,
            degrees_shared = 10,
            awards_shared = 10,
            images_shared_url = 15,
            bio_shared_content = 12,
            student_profile_shared = 10
        };

        return this;
    }

    public struct function runScan(
        string triggeredBy = "manual",
        boolean includeDeepSignals = false,
        string ruleMode = "",
        string scanStage = ""
    ) {
        var runID = 0;
        var persistedCount = 0;
        var totalUsers = 0;
        var pairSignals = {};
        var rawSignals = [];
        var minConfidence = getMinConfidence();
        var normalizedStage = lCase(trim(arguments.scanStage ?: ""));
        var scanMode = len(normalizedStage) ? "staged:" & normalizedStage : (arguments.includeDeepSignals ? "full" : "quick");
        var resolvedRuleMode = resolveRuleMode(
            triggeredBy = arguments.triggeredBy,
            requestedRuleMode = arguments.ruleMode
        );
        var flagMap = {};

        try {
            runID = variables.duplicateUsersDAO.createRun( trim(arguments.triggeredBy ?: "manual") );
            totalUsers = variables.duplicateUsersDAO.getTotalUserCount();
            if (normalizedStage EQ "all") {
                rawSignals = variables.duplicateUsersDAO.findDuplicateSignalsQuick();
                arrayAppend(rawSignals, variables.duplicateUsersDAO.findDuplicateSignalsForStage("emails"), true);
                arrayAppend(rawSignals, variables.duplicateUsersDAO.findDuplicateSignalsForStage("phones"), true);
                arrayAppend(rawSignals, variables.duplicateUsersDAO.findDuplicateSignalsForStage("flags"), true);
                arrayAppend(rawSignals, variables.duplicateUsersDAO.findDuplicateSignalsForStage("organizations"), true);
            } else if (listFindNoCase("emails,phones,flags,organizations", normalizedStage)) {
                rawSignals = variables.duplicateUsersDAO.findDuplicateSignalsForStage(normalizedStage);
            } else if (arguments.includeDeepSignals) {
                rawSignals = variables.duplicateUsersDAO.findDuplicateSignals();
            } else {
                rawSignals = variables.duplicateUsersDAO.findDuplicateSignalsQuick();
            }

            pairSignals = aggregateSignals( rawSignals );
            flagMap = variables.duplicateUsersDAO.getUserFlagModeMap();

            for (var pairKey in pairSignals) {
                var pairData = pairSignals[pairKey];
                var confidenceScore = buildConfidenceScore(pairData.signalTypes);
                var userAFlags = getUserModeFlags(flagMap, pairData.userID_A);
                var userBFlags = getUserModeFlags(flagMap, pairData.userID_B);

                if (!pairMatchesRuleMode(userAFlags, userBFlags, resolvedRuleMode)) {
                    continue;
                }

                if (confidenceScore LT minConfidence) {
                    continue;
                }

                variables.duplicateUsersDAO.upsertPair(
                    runID = runID,
                    userID_A = pairData.userID_A,
                    userID_B = pairData.userID_B,
                    confidenceScore = confidenceScore,
                    matchSignalsJSON = serializeJSON(pairData.details)
                );
                persistedCount++;
            }

            variables.duplicateUsersDAO.completeRun(
                runID = runID,
                totalUsers = totalUsers,
                totalPairs = persistedCount,
                status = "completed",
                errorMessage = ""
            );

            return {
                success = true,
                runID = runID,
                totalUsers = totalUsers,
                totalPairs = persistedCount,
                minConfidence = minConfidence,
                scanMode = scanMode,
                ruleMode = resolvedRuleMode,
                message = "Duplicate-user scan completed."
            };
        } catch (any e) {
            if (runID GT 0) {
                variables.duplicateUsersDAO.completeRun(
                    runID = runID,
                    totalUsers = totalUsers,
                    totalPairs = persistedCount,
                    status = "failed",
                    errorMessage = buildErrorMessage(e)
                );
            }

            return {
                success = false,
                runID = runID,
                totalUsers = totalUsers,
                totalPairs = persistedCount,
                minConfidence = minConfidence,
                scanMode = scanMode,
                ruleMode = resolvedRuleMode,
                message = buildErrorMessage(e)
            };
        }
    }

    public string function resolveRuleMode(
        string triggeredBy = "manual",
        string requestedRuleMode = ""
    ) {
        var normalizedMode = normalizeRuleMode(arguments.requestedRuleMode);

        if (len(normalizedMode)) {
            return normalizedMode;
        }

        if (lCase(trim(arguments.triggeredBy ?: "manual")) EQ "scheduled") {
            return normalizeRuleMode(
                variables.appConfigService.getValue(
                    "scheduled_tasks.uhco_duplicateusersreport.scan_mode",
                    "alumni_vs_faculty"
                )
            );
        }

        return "all";
    }

    public string function normalizeRuleMode( string value = "" ) {
        var normalized = lCase(trim(arguments.value ?: ""));

        if (!listFindNoCase("alumni_vs_alumni,alumni_vs_faculty,alumni_vs_other,staff_only,all", normalized)) {
            return "all";
        }

        return normalized;
    }

    public numeric function getMinConfidence() {
        var configured = val(variables.appConfigService.getValue("duplicate_users.min_confidence", "35"));
        if (configured LT 1) {
            configured = 35;
        }
        if (configured GT 100) {
            configured = 100;
        }
        return configured;
    }

    public array function getRecentRuns( numeric limit = 10 ) {
        return variables.duplicateUsersDAO.getRecentRuns(arguments.limit);
    }

    public struct function getLatestRun() {
        return variables.duplicateUsersDAO.getLatestRun();
    }

    public struct function getRunByID( required numeric runID ) {
        return variables.duplicateUsersDAO.getRunByID(arguments.runID);
    }

    public array function getPairsByRun( required numeric runID, string statusFilter = "" ) {
        return variables.duplicateUsersDAO.getPairsByRun(arguments.runID, arguments.statusFilter);
    }

    public struct function getPairByID( required numeric pairID ) {
        return variables.duplicateUsersDAO.getPairByID(arguments.pairID);
    }

    public struct function getLatestMergeByPairID( required numeric pairID ) {
        return variables.duplicateUsersDAO.getLatestMergeByPairID(arguments.pairID);
    }

    public struct function getLatestMergeBySecondaryUserID( required numeric secondaryUserID ) {
        return variables.duplicateUsersDAO.getLatestMergeBySecondaryUserID(arguments.secondaryUserID);
    }

    public struct function getPairDeepScan(
        required numeric pairID,
        string scanType = "profile"
    ) {
        var pair = getPairByID(arguments.pairID);
        if (structIsEmpty(pair)) {
            return {
                success = false,
                message = "Pair not found.",
                data = {}
            };
        }

        var normalizedType = lCase(trim(arguments.scanType ?: "profile"));

        return {
            success = true,
            message = "",
            data = {
                scanType = normalizedType,
                userA = {
                    userID = val(pair.USERID_A ?: 0),
                    rows = variables.duplicateUsersDAO.getUserDeepScanData(val(pair.USERID_A ?: 0), normalizedType)
                },
                userB = {
                    userID = val(pair.USERID_B ?: 0),
                    rows = variables.duplicateUsersDAO.getUserDeepScanData(val(pair.USERID_B ?: 0), normalizedType)
                }
            }
        };
    }

    public struct function mergePair(
        required numeric pairID,
        required numeric primaryUserID,
        numeric mergedByAdminUserID = 0,
        string notes = "",
        struct mergeChoices = {}
    ) {
        var pair = getPairByID(arguments.pairID);
        if (structIsEmpty(pair)) {
            return { success = false, message = "Pair not found." };
        }

        var primaryUser = val(arguments.primaryUserID);
        var userA = val(pair.USERID_A ?: 0);
        var userB = val(pair.USERID_B ?: 0);
        if (primaryUser NEQ userA AND primaryUser NEQ userB) {
            return { success = false, message = "Primary user must be one of the pair users." };
        }

        var secondaryUser = (primaryUser EQ userA) ? userB : userA;
        var migrationSummary = {};
        var warnings = [];

        if (lCase(trim(pair.STATUS ?: "")) EQ "merged") {
            return { success = false, message = "Pair is already marked as merged." };
        }

        try {
            migrationSummary = variables.duplicateUsersDAO.consolidateUsers(
                primaryUserID = primaryUser,
                secondaryUserID = secondaryUser,
                deactivateSecondary = true
            );

            var mergeChoicePayload = structIsEmpty(arguments.mergeChoices)
                ? {
                    selectedPrimaryUserID = primaryUser,
                    selectedSecondaryUserID = secondaryUser,
                    mode = "phase3_transactional_consolidation",
                    dataMigrationSummary = migrationSummary,
                    secondaryUserDeactivated = true,
                    warnings = warnings
                }
                : arguments.mergeChoices;

            var mergeID = variables.duplicateUsersDAO.createMergeRecord(
                pairID = arguments.pairID,
                primaryUserID = primaryUser,
                secondaryUserID = secondaryUser,
                mergedByAdminUserID = val(arguments.mergedByAdminUserID),
                mergeChoicesJSON = serializeJSON(mergeChoicePayload),
                notes = left(trim(arguments.notes ?: ""), 500)
            );

            variables.duplicateUsersDAO.updatePairStatus(arguments.pairID, "merged", "");

            try {
                // Always enforce secondary inactivity after merge to avoid drift when downstream logic or triggers interfere.
                variables.usersService.setUserActive(
                    userID = secondaryUser,
                    active = false
                );

                var secondaryUserResult = variables.usersService.getUser(secondaryUser);
                if (secondaryUserResult.success AND val(secondaryUserResult.data.ACTIVE ?: 1) EQ 0) {
                    migrationSummary.SECONDARYDEACTIVATED = 1;
                } else {
                    arrayAppend(warnings, "Secondary account merge completed, but inactive verification did not confirm Active=0 for user ##" & secondaryUser & ".");
                }
            } catch (any inactiveError) {
                arrayAppend(warnings, "Secondary account merge completed, but inactive enforcement failed: " & buildErrorMessage(inactiveError));
            }

            return {
                success = true,
                message = "Pair marked as merged.",
                mergeID = mergeID,
                primaryUserID = primaryUser,
                secondaryUserID = secondaryUser,
                warnings = warnings,
                migrationSummary = migrationSummary
            };
        } catch (any e) {
            return {
                success = false,
                message = buildErrorMessage(e)
            };
        }
    }

    public struct function getStatusSummaryByRun( required numeric runID ) {
        return variables.duplicateUsersDAO.getStatusSummaryByRun(arguments.runID);
    }

    public array function getInactiveMergedAccounts( numeric limit = 100 ) {
        return variables.duplicateUsersDAO.getInactiveMergedAccounts(arguments.limit);
    }

    public numeric function getLatestPendingPairCount() {
        return variables.duplicateUsersDAO.getLatestPendingPairCount();
    }

    public void function ignorePair( required numeric pairID, string reason = "" ) {
        variables.duplicateUsersDAO.updatePairStatus(arguments.pairID, "ignored", arguments.reason);
    }

    public void function unignorePair( required numeric pairID ) {
        variables.duplicateUsersDAO.updatePairStatus(arguments.pairID, "pending", "");
    }

    public array function parseSignalsJSON( required string rawSignals ) {
        var payload = trim(arguments.rawSignals ?: "");
        if (!len(payload) || !isJSON(payload)) {
            return [];
        }

        var parsed = deserializeJSON(payload);
        return isArray(parsed) ? parsed : [];
    }

    public string function signalLabel( required string signalType, string signalValue = "" ) {
        var normalizedType = lCase(trim(arguments.signalType ?: ""));

        if (normalizedType EQ "external_ids") {
            return externalIDSignalLabel(arguments.signalValue);
        }

        var labels = {
            users_uh_api_id = "Shared UH API ID",
            external_ids = "Shared External ID",
            external_ids_cougarnet = "Shared External ID",
            users_email_primary = "Primary Email Match",
            emails_address = "Secondary Email Match",
            users_name = "Users Name Match",
            aliases_name = "Alias Name Match",
            phones_number = "Phone Number Match",
            aliases_display_name = "Alias Display Name Match",
            academic_multi_grad_year = "Same Name, Different Grad Year",
            flags_faculty_alumni_split = "Faculty/Alumni Split Pattern",
            addresses_location = "Address Match",
            organizations_shared = "Shared Organization",
            degrees_shared = "Shared Degree",
            awards_shared = "Shared Award",
            images_shared_url = "Shared Image URL",
            bio_shared_content = "Shared Bio Content",
            student_profile_shared = "Shared Student Profile"
        };

        if (structKeyExists(labels, normalizedType)) {
            return labels[normalizedType];
        }

        return normalizedType;
    }

    public string function scoreBadgeClass( required numeric score ) {
        if (arguments.score GTE 80) {
            return "bg-danger";
        }
        if (arguments.score GTE 60) {
            return "bg-warning text-dark";
        }
        if (arguments.score GTE 40) {
            return "bg-info text-dark";
        }
        return "bg-secondary";
    }

    private struct function aggregateSignals( required array rawSignals ) {
        var pairs = {};

        for (var row in arguments.rawSignals) {
            var userA = val(row.USERID_A ?: 0);
            var userB = val(row.USERID_B ?: 0);
            var signalType = lCase(trim(row.SIGNALTYPE ?: ""));
            var signalValue = trim(row.SIGNALVALUE ?: "");

            if (userA LTE 0 || userB LTE 0 || userA EQ userB || !len(signalType)) {
                continue;
            }

            var pairKey = userA & "|" & userB;
            if (!structKeyExists(pairs, pairKey)) {
                pairs[pairKey] = {
                    userID_A = userA,
                    userID_B = userB,
                    signalTypes = {},
                    detailIndex = {},
                    details = []
                };
            }

            pairs[pairKey].signalTypes[signalType] = true;

            var detailKey = signalType & "|" & lCase(signalValue);
            if (!structKeyExists(pairs[pairKey].detailIndex, detailKey)) {
                pairs[pairKey].detailIndex[detailKey] = true;
                arrayAppend(pairs[pairKey].details, {
                    type = signalType,
                    value = signalValue,
                    weight = getSignalWeight(signalType)
                });
            }
        }

        return pairs;
    }

    private numeric function buildConfidenceScore( required struct signalTypes ) {
        var score = 0;
        var typeCount = 0;

        for (var signalType in arguments.signalTypes) {
            score += getSignalWeight(signalType);
            typeCount++;
        }

        // Small bonus for multi-signal pairs to prioritize richer matches.
        if (typeCount GTE 3) {
            score += 10;
        }

        if (score GT 100) {
            score = 100;
        }

        if (score LT 0) {
            score = 0;
        }

        return score;
    }

    private numeric function getSignalWeight( required string signalType ) {
        var key = lCase(trim(arguments.signalType ?: ""));
        if (!len(key) || !structKeyExists(variables.signalWeights, key)) {
            return 5;
        }
        return val(variables.signalWeights[key]);
    }

    private string function externalIDSignalLabel( string signalValue = "" ) {
        var rawValue = trim(arguments.signalValue ?: "");
        var systemIDToken = listFirst(rawValue, "|");

        if (!len(systemIDToken) || !isNumeric(systemIDToken) || val(systemIDToken) LTE 0) {
            return "Shared External ID";
        }

        var systemMap = getExternalSystemLabelMap();
        var mapKey = toString(val(systemIDToken));

        if (structKeyExists(systemMap, mapKey) && len(trim(systemMap[mapKey] ?: ""))) {
            return trim(systemMap[mapKey]) & " ID Match";
        }

        return "Shared External ID";
    }

    private struct function getExternalSystemLabelMap() {
        if (!variables.externalSystemLabelMapLoaded) {
            variables.externalSystemLabelMap = variables.duplicateUsersDAO.getExternalSystemLabelMap();
            variables.externalSystemLabelMapLoaded = true;
        }

        return variables.externalSystemLabelMap;
    }

    private string function buildErrorMessage( required any err ) {
        var message = trim(arguments.err.message ?: "Unknown error");
        var detail = trim(arguments.err.detail ?: "");
        if (len(detail)) {
            message &= " -- " & detail;
        }
        return left(message, 1000);
    }

    private struct function getUserModeFlags( required struct flagMap, required numeric userID ) {
        var key = toString(arguments.userID);
        if (structKeyExists(arguments.flagMap, key)) {
            return arguments.flagMap[key];
        }

        return {
            isAlumni = false,
            isFaculty = false,
            isStaff = false,
            hasOther = false
        };
    }

    private boolean function pairMatchesRuleMode(
        required struct userAFlags,
        required struct userBFlags,
        required string ruleMode
    ) {
        switch (arguments.ruleMode) {
            case "alumni_vs_alumni":
                return arguments.userAFlags.isAlumni AND arguments.userBFlags.isAlumni;

            case "alumni_vs_faculty":
                return (
                    (arguments.userAFlags.isAlumni AND arguments.userBFlags.isFaculty)
                    OR
                    (arguments.userBFlags.isAlumni AND arguments.userAFlags.isFaculty)
                );

            case "alumni_vs_other":
                return (
                    (arguments.userAFlags.isAlumni AND isOtherOnly(arguments.userBFlags))
                    OR
                    (arguments.userBFlags.isAlumni AND isOtherOnly(arguments.userAFlags))
                );

            case "staff_only":
                return arguments.userAFlags.isStaff AND arguments.userBFlags.isStaff;

            case "all":
            default:
                return true;
        }
    }

    private boolean function isOtherOnly( required struct flags ) {
        return arguments.flags.hasOther AND NOT arguments.flags.isAlumni AND NOT arguments.flags.isFaculty;
    }

}
