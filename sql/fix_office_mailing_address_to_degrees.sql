/*
    fix_office_mailing_address_to_degrees.sql

    Finds rows in Users where Office_Mailing_Address does not resemble a
    proper mailing address and moves that value into the Degrees field.

    Expected address format (3 lines):
        4401 Martin Luther King Blvd
        J. Davis Armistead RM 2195
        Houston, TX 77204-2020

    A value is considered a valid address when ALL of these are true:
        1. Contains at least one newline (is multi-line)
        2. Starts with a digit (street number)
        3. Contains a US ZIP code pattern (#####  or  #####-####)
        4. Contains a state abbreviation pattern (, XX  e.g. ", TX")

    Anything that fails any one of those tests is treated as mis-filed data
    and moved to Degrees.

    Conflict rule:
        - If Degrees is currently empty  → replace it with the moved value.
        - If Degrees already has a value → prepend the moved value with " | "
          so no existing degree data is lost.

    Run the SELECT block first to review what will change.
    The UPDATE is wrapped in a transaction — verify the row count, then
    COMMIT or ROLLBACK as appropriate.
*/

-- ============================================================
-- STEP 1  Preview affected rows
-- ============================================================
SELECT
    UserID,
    FirstName,
    LastName,
    Office_Mailing_Address                          AS [Current Office_Mailing_Address],
    Degrees                                         AS [Current Degrees],
    CASE
        WHEN ISNULL(Degrees, '') = ''
            THEN Office_Mailing_Address
        ELSE Office_Mailing_Address + ' | ' + Degrees
    END                                             AS [Proposed Degrees]
FROM Users
WHERE ISNULL(Office_Mailing_Address, '') <> ''
  AND (
        -- Fails: not multi-line (no newline character)
        CHARINDEX(CHAR(10), Office_Mailing_Address) = 0

        -- Fails: does not start with a digit (no street number)
     OR LEFT(LTRIM(Office_Mailing_Address), 1) NOT LIKE '[0-9]'

        -- Fails: no 5-digit ZIP code anywhere in the value
     OR PATINDEX('%[0-9][0-9][0-9][0-9][0-9]%', Office_Mailing_Address) = 0

        -- Fails: no ", XX" state-abbreviation pattern (two capital letters after a comma+space)
     OR PATINDEX('%, [A-Z][A-Z]%', Office_Mailing_Address) = 0
      )
ORDER BY LastName, FirstName;


-- ============================================================
-- STEP 2  Apply the fix  (review row count before committing)
-- ============================================================
BEGIN TRANSACTION;

UPDATE Users
SET
    Degrees = CASE
                  WHEN ISNULL(Degrees, '') = ''
                      THEN Office_Mailing_Address
                  ELSE Office_Mailing_Address + ' | ' + Degrees
              END,
    Office_Mailing_Address = ''
WHERE ISNULL(Office_Mailing_Address, '') <> ''
  AND (
        CHARINDEX(CHAR(10), Office_Mailing_Address) = 0
     OR LEFT(LTRIM(Office_Mailing_Address), 1) NOT LIKE '[0-9]'
     OR PATINDEX('%[0-9][0-9][0-9][0-9][0-9]%', Office_Mailing_Address) = 0
     OR PATINDEX('%, [A-Z][A-Z]%', Office_Mailing_Address) = 0
      );

-- @@ROWCOUNT shows how many rows were updated.
SELECT @@ROWCOUNT AS RowsUpdated;

-- Verify a sample of the results before committing.
-- ROLLBACK;   -- uncomment to undo everything
COMMIT;
