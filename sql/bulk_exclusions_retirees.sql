-- ============================================================
-- bulk_exclusions_retirees.sql
-- Inserts DataQualityExclusions for users who meet ALL of:
--   1. Has ANY of the following flags assigned:
--        'active retiree', 'professor emeritus'
--
-- Excluded issue codes:
--   missing_email_primary, missing_email_secondary, missing_title1,
--   missing_room, missing_building, missing_cougarnet,
--   missing_peoplesoft, missing_legacy_id, missing_phone, missing_degrees
--
-- Safe to run multiple times: INSERT ... WHERE NOT EXISTS skips
-- any (UserID, IssueCode) pair that already exists.
-- ============================================================

-- Preview affected users first (comment out before running INSERT)
/*
SELECT  DISTINCT u.UserID, u.FirstName, u.LastName, u.Title1, uf.FlagName
FROM    Users u
INNER JOIN UserFlagAssignments ufa ON ufa.UserID = u.UserID
INNER JOIN UserFlags           uf  ON uf.FlagID  = ufa.FlagID
                                  AND LOWER(TRIM(uf.FlagName)) IN (
                                          'active retiree',
                                          'professor emeritus'
                                      )
ORDER BY u.LastName, u.FirstName;
*/

-- ── Bulk insert exclusions ────────────────────────────────────────────────────
INSERT INTO DataQualityExclusions (UserID, IssueCode, CreatedAt)
SELECT  q.UserID,
        codes.IssueCode,
        GETDATE()
FROM (
    -- Qualifying retirees
    SELECT DISTINCT u.UserID
    FROM   Users u
    INNER JOIN UserFlagAssignments ufa ON ufa.UserID = u.UserID
    INNER JOIN UserFlags           uf  ON uf.FlagID  = ufa.FlagID
                                      AND LOWER(TRIM(uf.FlagName)) IN (
                                              'active retiree',
                                              'professor emeritus'
                                          )
) q
CROSS JOIN (
    -- Issue codes to exclude these users from
    VALUES
        ('missing_email_primary'),
        ('missing_email_secondary'),
        ('missing_title1'),
        ('missing_room'),
        ('missing_building'),
        ('missing_cougarnet'),
        ('missing_peoplesoft'),
        ('missing_legacy_id'),
        ('missing_phone'),
        ('missing_degrees')
) AS codes(IssueCode)
-- Skip pairs that already exist (unique constraint: UserID + IssueCode)
WHERE NOT EXISTS (
    SELECT 1
    FROM   DataQualityExclusions x
    WHERE  x.UserID    = q.UserID
      AND  x.IssueCode = codes.IssueCode
);

SELECT  @@ROWCOUNT AS RowsInserted;
