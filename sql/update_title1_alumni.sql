-- ============================================================
-- update_title1_alumni.sql
-- Sets Title1 = 'Alumni' for users where ALL of:
--   1. Title1 IS NULL or empty
--   2. Has the 'Alumni' flag assigned
--   3. CurrentGradYear BETWEEN 1955 AND 2025
-- ============================================================

-- Preview affected users first (comment out before running UPDATE)
/*
SELECT  u.UserID, u.FirstName, u.LastName, u.Title1, uai.CurrentGradYear
FROM    Users u
INNER JOIN UserFlagAssignments ufa ON ufa.UserID = u.UserID
INNER JOIN UserFlags           uf  ON uf.FlagID  = ufa.FlagID
                                  AND LOWER(TRIM(uf.FlagName)) = 'alumni'
INNER JOIN UserAcademicInfo    uai ON uai.UserID = u.UserID
WHERE  ISNULL(TRIM(u.Title1), '') = ''
  AND  uai.CurrentGradYear BETWEEN 1955 AND 2025
ORDER BY uai.CurrentGradYear, u.LastName, u.FirstName;
*/

UPDATE u
SET    u.Title1 = 'Alumni'
FROM   Users u
INNER JOIN UserFlagAssignments ufa ON ufa.UserID = u.UserID
INNER JOIN UserFlags           uf  ON uf.FlagID  = ufa.FlagID
                                  AND LOWER(TRIM(uf.FlagName)) = 'alumni'
INNER JOIN UserAcademicInfo    uai ON uai.UserID = u.UserID
WHERE  ISNULL(TRIM(u.Title1), '') = ''
  AND  uai.CurrentGradYear BETWEEN 1955 AND 2025;

SELECT @@ROWCOUNT AS RowsUpdated;
