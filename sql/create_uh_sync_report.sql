-- ── UH Sync Report Tables ────────────────────────────────────────────────────
-- Run this once against the UHCO_Directory database.
-- Stores runs, per-field differences, departed users, and new API users.

-- ── 1. Run tracking ──────────────────────────────────────────────────────────
IF OBJECT_ID('dbo.UHSyncRuns', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.UHSyncRuns (
        RunID         INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        RunAt         DATETIME2(0)  NOT NULL CONSTRAINT DF_UHSyncRuns_RunAt    DEFAULT SYSUTCDATETIME(),
        TriggeredBy   NVARCHAR(50)  NOT NULL CONSTRAINT DF_UHSyncRuns_Trigger  DEFAULT 'manual',
        TotalCompared INT           NOT NULL CONSTRAINT DF_UHSyncRuns_Compared DEFAULT 0,
        TotalDiffs    INT           NOT NULL CONSTRAINT DF_UHSyncRuns_Diffs    DEFAULT 0,
        TotalGone     INT           NOT NULL CONSTRAINT DF_UHSyncRuns_Gone     DEFAULT 0,
        TotalNew      INT           NOT NULL CONSTRAINT DF_UHSyncRuns_New      DEFAULT 0
    );
END;
GO

-- ── 2. Field-level differences for matched users ─────────────────────────────
IF OBJECT_ID('dbo.UHSyncDiffs', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.UHSyncDiffs (
        DiffID     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        RunID      INT               NOT NULL,
        UserID     INT               NOT NULL,
        FieldName  NVARCHAR(100)     NOT NULL,
        LocalValue NVARCHAR(MAX)     NOT NULL CONSTRAINT DF_UHSyncDiffs_Local DEFAULT '',
        ApiValue   NVARCHAR(MAX)     NOT NULL CONSTRAINT DF_UHSyncDiffs_Api   DEFAULT '',
        ResolvedAt DATETIME2(0)      NULL,
        Resolution NVARCHAR(20)      NULL,   -- 'synced' | 'discarded'
        CONSTRAINT FK_UHSyncDiffs_RunID FOREIGN KEY (RunID)
            REFERENCES dbo.UHSyncRuns(RunID) ON DELETE CASCADE
    );

    CREATE INDEX IX_UHSyncDiffs_RunID  ON dbo.UHSyncDiffs (RunID);
    CREATE INDEX IX_UHSyncDiffs_UserID ON dbo.UHSyncDiffs (UserID);
    CREATE INDEX IX_UHSyncDiffs_Field  ON dbo.UHSyncDiffs (FieldName);
    CREATE INDEX IX_UHSyncDiffs_Res    ON dbo.UHSyncDiffs (Resolution) WHERE Resolution IS NULL;
END;
GO

-- ── 3. Local users not found in the API (possible departures) ────────────────
IF OBJECT_ID('dbo.UHSyncGone', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.UHSyncGone (
        GoneID     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        RunID      INT               NOT NULL,
        UserID     INT               NOT NULL,
        ResolvedAt DATETIME2(0)      NULL,
        Resolution NVARCHAR(20)      NULL,   -- 'deleted' | 'kept'
        CONSTRAINT FK_UHSyncGone_RunID FOREIGN KEY (RunID)
            REFERENCES dbo.UHSyncRuns(RunID) ON DELETE CASCADE
    );

    CREATE INDEX IX_UHSyncGone_RunID  ON dbo.UHSyncGone (RunID);
    CREATE INDEX IX_UHSyncGone_UserID ON dbo.UHSyncGone (UserID);
    CREATE INDEX IX_UHSyncGone_Res    ON dbo.UHSyncGone (Resolution) WHERE Resolution IS NULL;
END;
GO

-- ── 4. API users not in the local database (new people) ──────────────────────
IF OBJECT_ID('dbo.UHSyncNew', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.UHSyncNew (
        NewID      INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        RunID      INT               NOT NULL,
        UHApiID    NVARCHAR(255)     NOT NULL,
        FirstName  NVARCHAR(150)     NOT NULL CONSTRAINT DF_UHSyncNew_First DEFAULT '',
        LastName   NVARCHAR(150)     NOT NULL CONSTRAINT DF_UHSyncNew_Last  DEFAULT '',
        Email      NVARCHAR(255)     NOT NULL CONSTRAINT DF_UHSyncNew_Email DEFAULT '',
        Title      NVARCHAR(255)     NOT NULL CONSTRAINT DF_UHSyncNew_Title DEFAULT '',
        Department NVARCHAR(255)     NOT NULL CONSTRAINT DF_UHSyncNew_Dept  DEFAULT '',
        Phone      NVARCHAR(100)     NOT NULL CONSTRAINT DF_UHSyncNew_Phone DEFAULT '',
        RawJson    NVARCHAR(MAX)     NOT NULL CONSTRAINT DF_UHSyncNew_Raw   DEFAULT '',
        ResolvedAt DATETIME2(0)      NULL,
        Resolution NVARCHAR(20)      NULL,   -- 'imported' | 'ignored'
        CONSTRAINT FK_UHSyncNew_RunID FOREIGN KEY (RunID)
            REFERENCES dbo.UHSyncRuns(RunID) ON DELETE CASCADE
    );

    CREATE INDEX IX_UHSyncNew_RunID ON dbo.UHSyncNew (RunID);
    CREATE INDEX IX_UHSyncNew_Res   ON dbo.UHSyncNew (Resolution) WHERE Resolution IS NULL;
END;
GO
