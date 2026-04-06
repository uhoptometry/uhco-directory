-- ── Data Quality Report Tables ──────────────────────────────────────────────
-- Run this once against the UHCO_Identity database.

IF OBJECT_ID('dbo.DataQualityRuns', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DataQualityRuns (
        RunID       INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        RunAt       DATETIME2(0)  NOT NULL CONSTRAINT DF_DQRuns_RunAt       DEFAULT SYSUTCDATETIME(),
        TriggeredBy NVARCHAR(50)  NOT NULL CONSTRAINT DF_DQRuns_Triggered   DEFAULT 'manual',
        TotalUsers  INT           NOT NULL CONSTRAINT DF_DQRuns_TotalUsers  DEFAULT 0,
        TotalIssues INT           NOT NULL CONSTRAINT DF_DQRuns_TotalIssues DEFAULT 0
    );
END;
GO

IF OBJECT_ID('dbo.DataQualityIssues', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.DataQualityIssues (
        IssueID   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        RunID     INT           NOT NULL,
        UserID    INT           NOT NULL,
        IssueCode NVARCHAR(100) NOT NULL,
        CONSTRAINT FK_DQIssues_RunID FOREIGN KEY (RunID)
            REFERENCES DataQualityRuns(RunID) ON DELETE CASCADE
    );

    CREATE INDEX IX_DQIssues_RunID  ON dbo.DataQualityIssues (RunID);
    CREATE INDEX IX_DQIssues_UserID ON dbo.DataQualityIssues (UserID);
    CREATE INDEX IX_DQIssues_Code   ON dbo.DataQualityIssues (IssueCode);
END;
GO

IF OBJECT_ID('dbo.DataQualityExclusions', 'U') IS NULL
BEGIN
    -- One row per user per issue code = excluded from that check.
    CREATE TABLE dbo.DataQualityExclusions (
        ExclusionID INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
        UserID      INT           NOT NULL,
        IssueCode   NVARCHAR(100) NOT NULL,
        CreatedAt   DATETIME2(0)  NOT NULL CONSTRAINT DF_DQEx_CreatedAt DEFAULT SYSUTCDATETIME(),
        CONSTRAINT UQ_DQExclusions UNIQUE (UserID, IssueCode)
    );

    CREATE INDEX IX_DQExclusions_UserID ON dbo.DataQualityExclusions (UserID);
END;
GO
