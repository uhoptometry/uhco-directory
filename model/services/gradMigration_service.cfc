component output="false" singleton {

    public any function init() {
        variables.migrationDAO  = createObject("component", "dao.gradMigration_DAO").init();
        variables.flagsService  = createObject("component", "cfc.flags_service").init();
        variables.usersService  = createObject("component", "cfc.users_service").init();
        variables.helpers       = createObject("component", "cfc.helpers").init();
        return this;
    }

    // ══════════════════════════════════════════════════════════════════════════
    // HELPERS — Memorial Day & grad-year logic (delegates to helpers.cfc)
    // ══════════════════════════════════════════════════════════════════════════

    /** Memorial Day date for a given year. */
    public date function getMemorialDayDate( required numeric year ) {
        return variables.helpers.getMemorialDayDate( arguments.year );
    }

    /** Full grad-year window struct { memorialDay, startYear, endYear, graduatingYear }. */
    public struct function getGradYearWindow() {
        return variables.helpers.getGradYearWindow();
    }

    // ══════════════════════════════════════════════════════════════════════════
    // CONFIG
    // ══════════════════════════════════════════════════════════════════════════

    public boolean function isAutoExecuteEnabled() {
        return variables.migrationDAO.getAutoExecuteEnabled();
    }

    public void function setAutoExecute( required boolean enabled ) {
        variables.migrationDAO.setAutoExecuteEnabled( arguments.enabled );
    }

    public string function getNotifyEmail() {
        return variables.migrationDAO.getNotifyEmail();
    }

    public void function setNotifyEmail( required string email ) {
        variables.migrationDAO.setNotifyEmail( arguments.email );
    }

    // ══════════════════════════════════════════════════════════════════════════
    // RUN QUERIES
    // ══════════════════════════════════════════════════════════════════════════

    public struct function getLatestRun() {
        return variables.migrationDAO.getLatestRun();
    }

    public array function getRecentRuns( numeric maxRuns=10 ) {
        return variables.migrationDAO.getRecentRuns( arguments.maxRuns );
    }

    public struct function getRunByID( required numeric runID ) {
        return variables.migrationDAO.getRunByID( arguments.runID );
    }

    public array function getDetailsByRun( required numeric runID ) {
        return variables.migrationDAO.getDetailsByRun( arguments.runID );
    }

    // ══════════════════════════════════════════════════════════════════════════
    // PREVIEW — read-only, no side effects
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * Preview which students would be migrated for a given grad year.
     * Returns { success, gradYear, memorialDay, totalStudents, students[] }.
     */
    public struct function preview( required numeric gradYear ) {
        var students   = variables.migrationDAO.getGraduatingStudents( arguments.gradYear );
        var memDay     = getMemorialDayDate( year(now()) );
        var flagLookup = resolveFlagIDs();

        return {
            success       = true,
            gradYear      = arguments.gradYear,
            memorialDay   = memDay,
            totalStudents = arrayLen(students),
            students      = students,
            alumniFlagID  = flagLookup.alumniFlagID,
            studentFlagID = flagLookup.studentFlagID
        };
    }

    // ══════════════════════════════════════════════════════════════════════════
    // EXECUTE — full migration
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * Execute the graduation migration for a given grad year.
     * @gradYear     The graduating class year to migrate
     * @triggeredBy  Username or "scheduled"
     * @returns      Struct with run summary
     */
    public struct function execute( required numeric gradYear, required string triggeredBy ) {
        var mode = ( arguments.triggeredBy == "scheduled" ) ? "scheduled" : "manual";
        var runID = 0;

        try {
            // Duplicate guard: skip if a completed run already exists for this year
            var existing = variables.migrationDAO.getCompletedRunForYear( arguments.gradYear );
            if ( !structIsEmpty(existing) ) {
                return {
                    success = false,
                    message = "A completed migration already exists for #arguments.gradYear# (Run ###existing.RUNID#). Rollback that run first or choose a different year."
                };
            }

            // Resolve flag IDs
            var flagLookup = resolveFlagIDs();
            if ( !flagLookup.success ) {
                return { success=false, message=flagLookup.message };
            }

            // Get target students
            var students = variables.migrationDAO.getGraduatingStudents( arguments.gradYear );
            if ( arrayLen(students) == 0 ) {
                return {
                    success = false,
                    message = "No active current-student users found with grad year #arguments.gradYear#."
                };
            }

            // Create run record
            runID = variables.migrationDAO.createRun( arguments.gradYear, mode, arguments.triggeredBy );

            var totalMigrated = 0;
            var totalErrors   = 0;

            // Process each student
            for ( var student in students ) {
                var detailID = 0;
                try {
                    // Insert detail as pending
                    detailID = variables.migrationDAO.insertDetail(
                        runID,
                        student.USERID,
                        flagLookup.studentFlagID,
                        flagLookup.alumniFlagID,
                        student.TITLE1,
                        "Alumni"
                    );

                    // Step 1: Remove current-student flag
                    variables.flagsService.removeFlag( student.USERID, flagLookup.studentFlagID );

                    // Step 2: Add alumni flag
                    variables.flagsService.addFlag( student.USERID, flagLookup.alumniFlagID );

                    // Step 3: Update Title1 to "Alumni"
                    variables.usersService.updateUser( student.USERID, { Title1="Alumni" } );

                    // Step 4: Remove student-specific exclusions
                    var removedCount = variables.migrationDAO.removeStudentExclusions( student.USERID );

                    // Step 5: Add alumni exclusions
                    var addedCount = variables.migrationDAO.addAlumniExclusions( student.USERID );

                    // Mark success
                    variables.migrationDAO.updateDetailStatus(
                        detailID, "migrated", addedCount, removedCount
                    );
                    totalMigrated++;

                } catch ( any e ) {
                    totalErrors++;
                    if ( detailID > 0 ) {
                        variables.migrationDAO.updateDetailStatus(
                            detailID, "error", 0, 0, left(e.message, 500)
                        );
                    }
                }
            }

            // Finalize run
            var finalStatus = ( totalMigrated > 0 ) ? "completed" : "failed";
            variables.migrationDAO.updateRunTotals( runID, arrayLen(students), totalMigrated, totalErrors );
            variables.migrationDAO.updateRunStatus( runID, finalStatus );

            // Send notification
            try {
                sendNotification( runID );
            } catch ( any e ) {
                // Notification failure should not fail the migration
            }

            return {
                success       = true,
                runID         = runID,
                status        = finalStatus,
                gradYear      = arguments.gradYear,
                totalTargeted = arrayLen(students),
                totalMigrated = totalMigrated,
                totalErrors   = totalErrors
            };

        } catch ( any e ) {
            // If run was created, mark it failed
            if ( runID > 0 ) {
                try {
                    variables.migrationDAO.updateRunStatus( runID, "failed" );
                } catch ( any e2 ) { /* swallow */ }
            }
            return {
                success = false,
                message = "Migration failed: " & e.message,
                runID   = runID
            };
        }
    }

    // ══════════════════════════════════════════════════════════════════════════
    // ROLLBACK
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * Rollback a completed migration run.
     * @runID         The run to roll back
     * @rolledBackBy  Username performing the rollback
     */
    public struct function rollback( required numeric runID, required string rolledBackBy ) {
        var run = variables.migrationDAO.getRunByID( arguments.runID );
        if ( structIsEmpty(run) ) {
            return { success=false, message="Run not found." };
        }
        if ( run.STATUS != "completed" ) {
            return { success=false, message="Only completed runs can be rolled back. Current status: #run.STATUS#" };
        }

        var flagLookup = resolveFlagIDs();
        if ( !flagLookup.success ) {
            return { success=false, message=flagLookup.message };
        }

        var details       = variables.migrationDAO.getDetailsByRun( arguments.runID );
        var rolledBack    = 0;
        var rollbackErrors = 0;

        for ( var detail in details ) {
            if ( detail.STATUS != "migrated" ) continue;

            try {
                // Reverse flag: remove alumni, re-add current-student
                variables.flagsService.removeFlag( detail.USERID, flagLookup.alumniFlagID );
                variables.flagsService.addFlag( detail.USERID, flagLookup.studentFlagID );

                // Restore Title1
                variables.usersService.updateUser( detail.USERID, { Title1=detail.PREVIOUSTITLE1 } );

                // Remove alumni exclusions and re-add student exclusions
                variables.migrationDAO.removeAlumniExclusions( detail.USERID );
                variables.migrationDAO.addStudentExclusions( detail.USERID );

                rolledBack++;
            } catch ( any e ) {
                rollbackErrors++;
            }
        }

        // Mark run and details as rolled back
        variables.migrationDAO.markDetailsRolledBack( arguments.runID );
        variables.migrationDAO.markRunRolledBack( arguments.runID, arguments.rolledBackBy );

        return {
            success        = true,
            runID          = arguments.runID,
            totalRolledBack = rolledBack,
            totalErrors    = rollbackErrors
        };
    }

    // ══════════════════════════════════════════════════════════════════════════
    // NOTIFICATION
    // ══════════════════════════════════════════════════════════════════════════

    /** Send email notification for a completed run. */
    public void function sendNotification( required numeric runID ) {
        var notifyEmail = getNotifyEmail();
        if ( !len(notifyEmail) || !isValid("email", notifyEmail) ) return;

        var run = variables.migrationDAO.getRunByID( arguments.runID );
        if ( structIsEmpty(run) ) return;

        var subject = "UHCO Graduation Migration — Class of #run.GRADYEAR# — #uCase(run.STATUS)#";
        var body = "
            Graduation Migration Run ###run.RUNID#

            Grad Year:     #run.GRADYEAR#
            Status:        #run.STATUS#
            Mode:          #run.MODE#
            Triggered By:  #run.TRIGGEREDBY#
            Executed At:   #dateTimeFormat(run.EXECUTEDAT, 'MM/dd/yyyy hh:nn tt')#

            Total Targeted: #run.TOTALTARGETED#
            Total Migrated: #run.TOTALMIGRATED#
            Total Errors:   #run.TOTALERRORS#

            View details at: /admin/reporting/grad_migration_detail.cfm?runID=#run.RUNID#
        ";

        cfmail(
            to      = notifyEmail,
            from    = "noreply@uh.edu",
            subject = subject,
            type    = "text"
        ) {
            writeOutput( trim(body) );
        }

        variables.migrationDAO.markNotificationSent( arguments.runID );
    }

    // ══════════════════════════════════════════════════════════════════════════
    // PRIVATE HELPERS
    // ══════════════════════════════════════════════════════════════════════════

    /**
     * Look up the FlagIDs for "current-student" and "alumni".
     * Returns { success, studentFlagID, alumniFlagID, message }.
     */
    private struct function resolveFlagIDs() {
        var flagResult = variables.flagsService.getAllFlags();
        var studentFlagID = 0;
        var alumniFlagID  = 0;

        for ( var f in flagResult.data ) {
            if ( lCase(trim(f.FLAGNAME)) == "current-student" ) studentFlagID = f.FLAGID;
            if ( lCase(trim(f.FLAGNAME)) == "alumni" )          alumniFlagID  = f.FLAGID;
        }

        if ( studentFlagID == 0 || alumniFlagID == 0 ) {
            return {
                success       = false,
                studentFlagID = studentFlagID,
                alumniFlagID  = alumniFlagID,
                message       = "Could not find required flags. current-student=#studentFlagID#, alumni=#alumniFlagID#"
            };
        }

        return {
            success       = true,
            studentFlagID = studentFlagID,
            alumniFlagID  = alumniFlagID,
            message       = ""
        };
    }

}
