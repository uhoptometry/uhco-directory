-- ============================================================
-- Student Profile tables
-- Run against UHCO_Identity
-- ============================================================

-- One row per student: hometown + externships
CREATE TABLE UserStudentProfile (
    ProfileID         INT            NOT NULL IDENTITY(1,1) PRIMARY KEY,
    UserID            INT            NOT NULL UNIQUE REFERENCES Users(UserID),
    Hometown          NVARCHAR(255)  NULL,
    FirstExternship   NVARCHAR(255)  NULL,
    SecondExternship  NVARCHAR(255)  NULL,
    UpdatedAt         DATETIME       NOT NULL DEFAULT GETDATE()
);

-- Many awards per student
CREATE TABLE UserAwards (
    AwardID    INT            NOT NULL IDENTITY(1,1) PRIMARY KEY,
    UserID     INT            NOT NULL REFERENCES Users(UserID),
    AwardName  NVARCHAR(255)  NOT NULL,
    AwardType  NVARCHAR(100)  NULL,
    CreatedAt  DATETIME       NOT NULL DEFAULT GETDATE()
);

CREATE INDEX IX_UserAwards_UserID ON UserAwards (UserID);
