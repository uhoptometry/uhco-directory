# Database Migrations

This repo now includes a first-pass schema migration workflow.

The goal is to replace ad hoc, hard-to-track SQL changes with ordered migration files and a repeatable runner.

## Current Scope

This implementation covers:

- ordered schema migrations under [sql/migrations](sql/migrations)
- a migration ledger table: `dbo.SchemaVersions`
- a PowerShell runner for planning and applying pending migrations
- VS Code tasks for reviewing and applying schema changes

It does not yet cover:

- masked production-to-development data refreshes
- admin UI for schema deployment
- rollback orchestration

It now also includes:

- a user-data schema drift report between development and production-style databases
- a guarded local-to-production user-data sync plan/apply workflow
- a guarded production-to-local user-data refresh plan/apply workflow

## Migration Ledger

The runner creates this table if needed:

- `dbo.SchemaVersions`

Each applied script records:

- `ScriptName`
- `ScriptChecksum`
- `AppliedAt`
- `AppliedBy`
- `DurationMs`
- `Notes`

If a previously applied migration file is modified later, the runner stops with a checksum mismatch.

## Runner Script

Runner path:

- [.vscode/scripts/invoke-db-migrations.ps1](.vscode/scripts/invoke-db-migrations.ps1)

Supported modes:

- `Plan` - list pending migrations only
- `Apply` - execute pending migrations and record them in `SchemaVersions`

Supported connection styles:

- Windows integrated security when no username is supplied
- SQL login when username and password are supplied

## VS Code Tasks

Tasks added in [.vscode/tasks.json](.vscode/tasks.json):

- `Plan DB Migrations`
- `Apply DB Migrations`
- `Compare User Data DB Schema`
- `Plan User Data Sync Local to Prod`
- `Apply User Data Sync Local to Prod`
- `Plan User Data Refresh Prod to Local`
- `Apply User Data Refresh Prod to Local`
- `Review Local Dev Refresh From Prod`

These prompt for:

- SQL Server instance or host
- database name

The schema compare task also prompts for:

- development SQL Server and database
- production SQL Server and database
- the user-data table list to compare
- the Markdown report output path

The local-to-prod sync tasks also prompt for:

- the user-data table list to sync
- the Markdown report output path
- an explicit confirmation phrase for apply mode

The prod-to-local refresh tasks also prompt for:

- the user-data table list to refresh
- the Markdown report output path
- an explicit confirmation phrase for apply mode

The review wrapper task runs these in sequence:

- `Compare User Data DB Schema`
- `Plan User Data Refresh Prod to Local`

If username is left blank, the runner uses integrated security.

## Recommended Workflow

1. Add a new migration file to [sql/migrations](sql/migrations).
2. Run `Plan DB Migrations` against your development database.
3. Run `Apply DB Migrations` against development.
4. Validate application behavior.
5. Promote the same migration file to higher environments.
6. Run `Plan DB Migrations` and then `Apply DB Migrations` in production.

## Existing Databases

If an environment already has the current UHCO Identity schema, start by applying the baseline migration:

- [20260420_001_baseline_existing_schema.sql](sql/migrations/20260420_001_baseline_existing_schema.sql)

That migration is intentionally non-destructive and exists to mark the adoption point for the migration framework.

## Notes

- Do not use this as a substitute for full backups before risky schema changes.
- Do not edit migration files after they are applied outside your local machine.
- Keep reference-data seeding separate unless it is tightly coupled to the schema change.

## User Data Schema Compare

Schema compare runner path:

- [.vscode/scripts/compare-db-schema.ps1](.vscode/scripts/compare-db-schema.ps1)

Default report path:

- [.vscode/reports/db-schema-compare.md](.vscode/reports/db-schema-compare.md)

The compare task is intentionally scoped to core user-data tables such as `Users`, `UserStudentProfile`, `UserPhone`, `UserOrganizations`, `UserImageVariants`, `UserImageSources`, `UserImages`, `UserFlags`, `UserFlagAssignments`, `UserExternalIDs`, `UserEmails`, `UserDegrees`, `UserAliases`, `UserAddresses`, and `UserAcademicInfo`. It does not target operational run-history tables by default.

For convenience, the schema compare runner also normalizes a couple of common name mismatches:

- `UserDegreess` -> `UserDegrees`
- `UserAcademicProfile` -> `UserAcademicInfo`

## User Data Sync: Local to Prod

Sync runner path:

- [.vscode/scripts/sync-user-data-local-to-prod.ps1](.vscode/scripts/sync-user-data-local-to-prod.ps1)

Default report path:

- [.vscode/reports/user-data-sync-plan.md](.vscode/reports/user-data-sync-plan.md)

This workflow is intended as a temporary active-development bridge where local is still the source of truth for user-data tables.

Safeguards:

- `Plan` mode produces a report without writing to production
- `Apply` mode requires the exact confirmation phrase `SYNC LOCAL TO PROD`
- deletes run in dependency-safe reverse order
- inserts run in dependency-safe forward order
- identity values are preserved during bulk copy

This workflow is intentionally scoped to user-data tables and supporting dependency tables like `Organizations` and `ExternalSystems`. Media/image tables are excluded from the default sync scope. It is not intended for operational run-history tables.

## User Data Refresh: Prod to Local

Refresh runner path:

- [.vscode/scripts/sync-user-data-prod-to-local.ps1](.vscode/scripts/sync-user-data-prod-to-local.ps1)

Default report path:

- [.vscode/reports/user-data-refresh-plan.md](.vscode/reports/user-data-refresh-plan.md)

This workflow is intended for post-launch local refreshes where production becomes the better source of truth for user-data tables.

Safeguards:

- `Plan` mode produces a report without writing to local
- `Apply` mode requires the exact confirmation phrase `SYNC PROD TO LOCAL`
- matching rows are updated in local
- missing local rows are inserted
- production-only rows can be deleted from local only for leaf tables with no child foreign keys in the local database
- identity values are preserved during bulk copy

This workflow uses the same default user-data scope as the local-to-prod sync and excludes media/image tables by default.

## Recommended Cadence

Use `Review Local Dev Refresh From Prod` as the normal checkpoint task.

Suggested operating cadence:

1. Daily or before starting a debugging session: run `Review Local Dev Refresh From Prod`.
2. After any production hotfix or direct production data correction: run `Review Local Dev Refresh From Prod`, then run `Apply User Data Refresh Prod to Local` if the refresh report shows meaningful differences.
3. Before reproducing a production-only bug locally: run `Review Local Dev Refresh From Prod`, confirm the schema report is clean, then apply the refresh.
4. Weekly during active launch support: take a local backup, then run `Apply User Data Refresh Prod to Local` even if only a small number of rows changed.

Decision rule:

1. If the schema compare report shows drift, fix schema first.
2. If schema is aligned and the refresh plan shows user-data differences that matter for the issue you are working, apply the prod-to-local refresh.
3. If you are only doing routine development and the plan shows no meaningful differences, stop at the review wrapper task.