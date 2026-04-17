-- ============================================================
-- bulk_exclusions_alumni.sql
-- Inserts DataQualityExclusions for users who meet ALL of:
--   1. Title1 = 'Alumni'
--   2. Has the 'Alumni' flag assigned
--   3. CurrentGradYear BETWEEN 1955 AND 2025
--
-- Excluded issue codes:
--   missing_uh_api_id, missing_email_primary, missing_email_secondary,
--   missing_room, missing_building, missing_phone, missing_degrees,
--   missing_cougarnet, missing_peoplesoft
--
-- Safe to run multiple times: INSERT ... WHERE NOT EXISTS skips
-- any (UserID, IssueCode) pair that already exists.
-- ============================================================

-- Preview affected users first (comment out before running INSERT)
/*
SELECT  u.UserID, u.FirstName, u.LastName, u.Title1, uai.CurrentGradYear
FROM    Users u
INNER JOIN UserFlagAssignments ufa ON ufa.UserID = u.UserID
INNER JOIN UserFlags           uf  ON uf.FlagID  = ufa.FlagID
                                  AND LOWER(TRIM(uf.FlagName)) = 'alumni'
INNER JOIN UserAcademicInfo    uai ON uai.UserID = u.UserID
WHERE   LOWER(TRIM(u.Title1)) = 'alumni'
  AND   uai.CurrentGradYear BETWEEN 1955 AND 2025
ORDER BY uai.CurrentGradYear, u.LastName, u.FirstName;
*/

-- ── Bulk insert exclusions ────────────────────────────────────────────────────
INSERT INTO DataQualityExclusions (UserID, IssueCode, CreatedAt)
SELECT  q.UserID,
        codes.IssueCode,
        GETDATE()
FROM (
    -- Qualifying alumni
    SELECT DISTINCT u.UserID
    FROM   Users u
    INNER JOIN UserFlagAssignments ufa ON ufa.UserID = u.UserID
    INNER JOIN UserFlags           uf  ON uf.FlagID  = ufa.FlagID
                                      AND LOWER(TRIM(uf.FlagName)) = 'alumni'
    INNER JOIN UserAcademicInfo    uai ON uai.UserID = u.UserID
    WHERE  LOWER(TRIM(u.Title1)) = 'alumni'
      AND  uai.CurrentGradYear BETWEEN 1955 AND 2025
) q
CROSS JOIN (
    -- Issue codes to exclude these users from
    VALUES
        ('missing_uh_api_id'),
        ('missing_email_primary'),
        ('missing_room'),
        ('missing_building'),
        ('missing_phone'),
        ('missing_degrees'),
        ('missing_cougarnet'),
        ('missing_peoplesoft'),
        ('missing_legacy_id')
) AS codes(IssueCode)
-- Skip pairs that already exist (unique constraint: UserID + IssueCode)
WHERE NOT EXISTS (
    SELECT 1
    FROM   DataQualityExclusions x
    WHERE  x.UserID    = q.UserID
      AND  x.IssueCode = codes.IssueCode
);

SELECT  @@ROWCOUNT AS RowsInserted;
