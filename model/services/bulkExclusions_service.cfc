component output="false" {

    /**
     * bulkExclusions_service — Orchestrates bulk exclusion runs
     * with audit logging per type and combined "run all" support.
     */

    public any function init() {
        variables.dao = createObject("component", "dao.bulkExclusions_DAO").init();
        return this;
    }

    /** Returns active types from BulkExclusionTypes table. */
    public array function getTypes() {
        return variables.dao.getAllTypes();
    }

    /** Returns a single type config struct (or empty struct). */
    public struct function getType(required string typeKey) {
        return variables.dao.getType(arguments.typeKey);
    }

    /** Save updated flags/codes for a type. */
    public void function saveType(
        required string typeKey,
        required string flags,
        required string codes,
        required string label,
        required string icon,
        string extraFilter = "",
        string updatedBy   = ""
    ) {
        variables.dao.updateType(argumentCollection = arguments);
    }

    /**
     * Run a single exclusion type via dynamic SQL. Returns struct {success, key, rows, message}.
     */
    public struct function runByType(required string typeKey, string triggeredBy = "manual") {
        var result = { success = false, key = arguments.typeKey, rows = 0, message = "" };

        var runID = variables.dao.createRun(arguments.typeKey, arguments.triggeredBy);

        try {
            result.rows = variables.dao.runDynamic(arguments.typeKey);

            variables.dao.updateRun(runID, result.rows);
            result.success = true;
            result.message = "Inserted #result.rows# exclusion(s).";
        } catch (any e) {
            result.message = e.message;
            variables.dao.updateRun(runID, 0, e.message);
        }

        return result;
    }

    /**
     * Run all active exclusion types in sequence.
     * Returns struct {success, totalRows, results[]}.
     */
    public struct function runAll(string triggeredBy = "manual") {
        var output = { success = true, totalRows = 0, results = [] };
        var types  = getTypes();

        for (var t in types) {
            var r = runByType(t.TYPE_KEY, arguments.triggeredBy);
            arrayAppend(output.results, r);
            output.totalRows += r.rows;
            if (!r.success) { output.success = false; }
        }

        return output;
    }

    public array function getRecentRuns(numeric maxRuns = 20) {
        return variables.dao.getRecentRuns(arguments.maxRuns);
    }

    public struct function getLatestRunByType(required string exclusionType) {
        return variables.dao.getLatestRunByType(arguments.exclusionType);
    }

}
