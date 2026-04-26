# Step 5: Non-Developer Execution Guide & Daily Test Flow

## Purpose

This guide helps non-technical testers execute the test scenarios (Steps 3 & 4) without requiring code knowledge or database access. It includes:

1. **Before You Start** — Environment checks and account verification
2. **Daily Test Flow** — What to do each testing day
3. **Scenario Execution Instructions** — Plain-language "how-tos" for common actions
4. **Defect Logging** — How to record issues you find
5. **Retest Instructions** — How to verify fixes
6. **Daily Standup Summary** — Tracking and reporting template

---

## Before You Start

### Day 1 Preparation (1-2 hours)

#### 1. Verify You Have Access
- [ ] You can log into CougarNet / your work email
- [ ] You have received a test account (e.g., testadmin.media@uhco.local or similar)
- [ ] You know your test account password (ask Test Lead if unsure)
- [ ] You can navigate to `https://uhco.uh.edu/admin/users/index.cfm` (or internal app URL)

#### 2. Verify Test Environment Is Ready
Ask Test Lead to confirm:
- [ ] Application loads without 500 errors
- [ ] All test user accounts are created (TestFaculty_Current, TestMedia_Ready, etc.)
- [ ] Test images are in the [_temp_source/test_images/](../../_temp_source/test_images/) folder
- [ ] Database is in clean state (no previous test data lingering)

#### 3. Read the Test Charter (Step 1)
- [ ] You understand what "Critical" vs "High" vs "Medium" vs "Low" severity means
- [ ] You understand that FUNCTIONAL testing comes first, UI/UX feedback comes later
- [ ] You know to STOP and escalate if you find a Critical-severity defect

#### 4. Read This Execution Guide
- [ ] You understand the daily test flow
- [ ] You know how to log a defect
- [ ] You know who to contact if something breaks

---

## Daily Test Flow

### Start of Day (10 minutes)

1. **Check-In with Test Lead**
   - Ask: "Is the app stable? Any blockers I should know about?"
   - If Critical defects from yesterday are not fixed, pause and wait

2. **Do a Smoke Test** (5 minutes)
   - [ ] Log in to app as your test account
   - [ ] Navigate to [admin/users/index.cfm](admin/users/index.cfm) — should load without error
   - [ ] Search for a user — should return results
   - [ ] If any of these fail, report to Test Lead immediately

3. **Grab Your Scenario List**
   - [ ] Take [step3-functional-test-matrix.md](step3-functional-test-matrix.md) or [step4-edge-case-matrix.md](step4-edge-case-matrix.md) as needed
   - [ ] Mark off where you left off yesterday
   - [ ] Note any defects from yesterday that are being retested

### During the Day (3-5 hours)

For each scenario (e.g., UE-001, UE-002, etc.):

1. **Read the Scenario Header**
   - Example: `ID: UE-001 | Workflow: User Editing | Scenario: Search & Open User Profile`
   - Look at the **Role** column — make sure you're logged in as the right account
   - Example: If scenario says "Role: testadmin.user@uhco.local", but you're logged in as testadmin.media@uhco.local, **STOP** and log out, then log in as the correct role

2. **Check Preconditions**
   - Example: "TestFaculty_Current user exists in database"
   - If you're not sure the precondition is met, ask Test Lead (don't guess)
   - Example: Ask "Can you confirm TestFaculty_Current is in the system?"

3. **Execute Steps Exactly as Written**
   - Follow each numbered step precisely
   - Don't skip or reorder steps
   - Don't try to "optimize" the workflow
   - Example: If step says "Click Search", do exactly that; don't click anything else first

4. **Compare to Expected Result**
   - After completing all steps, check if the actual outcome matches the **Expected Result** in the table
   - Example: Expected says "User profile opens on General tab; first name visible". Do you see all those things? If yes, PASS. If no, FAIL.
   - Example: Expected says "Pronouns field changes to They/Them after refresh". Did you refresh? Did pronouns actually change? If yes to both, PASS.

5. **Record Result**
   - [ ] PASS — Move to next scenario
   - [ ] FAIL — See "Defect Logging" below

6. **Mark Result on Your Tracking Sheet**
   - Use the daily tracking template (see "Daily Standup Summary" section below)

### End of Day (20 minutes)

1. **Compile Your Results**
   - [ ] Count: How many tests did you run?
   - [ ] Count: How many passed?
   - [ ] Count: How many failed? (By severity: Critical, High, Medium, Low)

2. **Fill in Daily Summary** (see template below)

3. **Report to Test Lead**
   - Show your summary
   - If any Critical defects, flag them immediately (don't wait until tomorrow)

---

## Scenario Execution Instructions

### Common Action: Searching for a User

**Goal:** Find a specific user in the system

**Steps:**
1. Navigate to `https://uhco.uh.edu/admin/users/index.cfm` (or ask Test Lead for the URL)
2. You should see a search box labeled "Search Users" or "Name/Email"
3. Type the first or last name (e.g., "TestFaculty" or "Current")
4. Click the "Search" button (should be blue)
5. Wait 2-3 seconds for results to load
6. You should see a list of matching users below the search box
7. Click the row for the user you want (usually clicking on the name)

**Troubleshooting:**
- If search returns 0 results, ask Test Lead: "Is this user in the system?"
- If search box doesn't work, try refreshing the page (F5)
- If you see a 500 error, screenshot it and report to Test Lead

---

### Common Action: Editing a Field & Saving

**Goal:** Change a field (name, email, etc.) and save it

**Steps:**
1. Open the user's edit page (see "Searching for a User" above)
2. Find the field you want to edit (e.g., "First Name")
3. Click in the field to activate it (cursor should appear in field)
4. Delete the old value (Ctrl+A to select all, then Delete)
5. Type the new value
6. Either:
   - **Option A:** Press Tab (move to next field) — this should trigger an auto-save
   - **Option B:** Look for a "Save" button and click it
7. Watch for a success message (green toast/popup that says "Saved" or similar)
8. **IMPORTANT:** Refresh the page (F5) or navigate away and back. This confirms the data actually persisted in the database.
9. If the value is still the same after refresh, it PASSED. If it reverted to the old value, it FAILED.

**Troubleshooting:**
- If no success message appears, the save may have failed silently. Refresh to check.
- If you see a red error message, screenshot it and note the exact message in your defect log.

---

### Common Action: Adding a Repeatable Field (Email, Phone, Address)

**Goal:** Add a second email or phone number to a user

**Steps:**
1. Open user's edit page on the "Contact" tab
2. Find "Email Addresses" section (or "Phones", "Addresses")
3. Look for a button labeled "Add Email", "Add Phone", "+", or "New"
4. Click that button
5. A new empty row should appear below existing items
6. Click in the empty field and type the new value (e.g., "newemail@uh.edu")
7. Click outside the field or press Tab to trigger save
8. Look for a success message
9. **IMPORTANT:** Refresh the page. If the new item is still there after refresh, it PASSED.

**Troubleshooting:**
- If adding the new row doesn't work, the button may be in a different location. Look for any "+" or "Add" icon.
- If the new item disappears after refresh, the save failed.

---

### Common Action: Removing a Repeatable Field

**Goal:** Delete a phone number or email address

**Steps:**
1. Open user's edit page on the "Contact" tab
2. Find the item you want to delete
3. Look for a "Delete", "Remove", "X", or trash icon next to the item
4. Click that button
5. The item row should disappear from the form
6. Look for a success message or auto-save indicator
7. **IMPORTANT:** Refresh the page. If the item is gone after refresh, it PASSED.

---

### Common Action: Adding a User Image Source

**Goal:** Upload or select an image file for a user

**Steps:**
1. Navigate to `https://uhco.uh.edu/admin/user-media/index.cfm`
2. Search for the user (see "Searching for a User")
3. You should see a button "Add Media", "Browse Images", or similar
4. Click that button
5. You may see a dialog or new page asking where the image comes from:
   - If it says "Local Folder" or "Upload", select that
   - If it says "Dropbox", select that (if testing Dropbox; otherwise skip)
6. If local folder:
   - Click "Browse" or "Choose File"
   - Navigate to `C:\inetpub\wwwroot\uhco_ident\_temp_source\test_images\`
   - Select a test image (e.g., `testmedia_ready.jpg`)
   - Click "Open" or "Select"
7. Back in the form, click "Confirm" or "Add" or "Upload"
8. Wait 3-5 seconds for upload to complete
9. You should see a success message and the image should appear in the source list
10. **IMPORTANT:** Refresh the page. If the source is still listed after refresh, it PASSED.

---

### Common Action: Assigning a Variant Type

**Goal:** Assign a "Headshot" or other variant type to an image

**Steps:**
1. From the user media page, click the source you just added
2. You should be taken to a variants page (or see a variant section on the same page)
3. Look for checkboxes or buttons labeled with variant types (e.g., "Headshot", "Directory Listing")
4. Check the "Headshot" checkbox or click an "Assign" button
5. Click "Save" or "Assign"
6. You should see a message that the variant is assigned with status "stale" or "pending"
7. **IMPORTANT:** Refresh the page. Variant assignment should persist.

---

### Common Action: Generating a Variant

**Goal:** Create a cropped/resized version of the image

**Steps:**
1. On the variants page, find the "Headshot" variant you just assigned
2. You should see a "Generate" button or similar
3. Click "Generate"
4. If a crop/resize tool appears, accept the default (or adjust if you want)
5. Click "Generate" or "Apply" to confirm
6. Wait 5-10 seconds for generation
7. You should see a progress indicator and then a success message
8. The variant status should change from "stale" to "current" or "ready"
9. **IMPORTANT:** Refresh the page. Status should remain "current"/"ready".

---

### Common Action: Publishing a Variant

**Goal:** Make the generated image available publicly

**Steps:**
1. On the variants page, find the generated "Headshot" variant (status should be "current"/"ready")
2. Click the "Publish" button
3. You may see a confirmation dialog asking "Are you sure?" — click "Yes" or "Confirm"
4. Wait 3-5 seconds
5. You should see a success message
6. The variant status should change to "published" or "active"
7. **Verification:** Open File Explorer and navigate to `C:\inetpub\wwwroot\uhco_ident\_published_images\`
   - You should see a new file named something like `testmediaready_headshot.jpg` or similar
   - Open the file to verify it's a valid image (not corrupted)

---

### Common Action: User Review Submission (End User)

**Goal:** Submit profile updates as a regular user

**Steps:**
1. Log out of admin account
2. Navigate to `https://uhco.uh.edu/userreview/index.cfm` (or ask Test Lead for URL)
3. Log in as a regular user (e.g., testfaculty.current@uh.edu)
4. You should see a "Profile Review" form with sections (General, Contact, Bio, etc.)
5. Edit one or more fields (e.g., change "He/Him" to "They/Them")
6. Click "Submit" button
7. You should see a confirmation message like "Thank you, your review has been submitted"
8. **IMPORTANT:** Log out and back in. Your submission should now appear in the admin queue.

---

### Common Action: User Review Approval (Admin)

**Goal:** Review and approve a user's submission

**Steps:**
1. Log in as admin with reviewer permissions (e.g., testadmin.reviewer@uhco.local)
2. Navigate to `https://uhco.uh.edu/admin/settings/user-review/index.cfm`
3. You should see a list of "Pending Submissions"
4. Find the user whose submission you want to review (e.g., TestFaculty_Current)
5. Click on their submission row or a "Review" link
6. You should see a diff display showing what changed (old value → new value)
7. You have options:
   - **Approve All:** Click "Approve All" to accept all changes
   - **Reject All:** Click "Reject All" to reject all changes (may prompt for a reason)
   - **Partial:** Click "Approve" on some fields and "Reject" on others individually
8. After choosing, click "Submit" or "Confirm"
9. You should see a success message
10. The submission status should change from "pending" to "approved" or "rejected"

---

## Defect Logging

### When to Log a Defect

Log a defect if:
- The actual result does NOT match the expected result
- You see an error message you didn't expect
- An action fails silently (appears to work but doesn't persist)
- An action you should NOT be allowed to do is allowed (permission issue)
- The app crashes or shows a 500 error

### How to Log a Defect

1. **Take a Screenshot**
   - Press Ctrl+Shift+S (or Shift+Print Screen)
   - OR use Snip Tool / Screenshot tool
   - Capture the exact state when the defect occurred
   - Save with a descriptive name (e.g., `defect-UE-002-name-not-saved.png`)

2. **Fill Out the Defect Form** (use template below)

3. **Be Specific**
   - Don't just say "it didn't work"
   - Tell us EXACTLY what you did
   - Tell us what you expected
   - Tell us what actually happened

### Defect Logging Template

Copy this template and fill it in:

```
**Scenario ID:** [e.g., UE-002]
**Severity:** [Critical / High / Medium / Low]
**Title:** [One-line summary, e.g., "First Name Not Saved"]

**Steps to Reproduce:**
1. [Exact step 1]
2. [Exact step 2]
3. [Exact step 3]

**Expected Result:**
[What should happen]

**Actual Result:**
[What actually happened]

**Screenshot:** [Attach or link screenshot]

**Additional Notes:**
[Any other details: error message, URL, browser, etc.]

**Logged by:** [Your name]
**Date & Time:** [When you found it]
**Status:** [New]
```

### Where to Send Defect Logs

- [ ] Save to a shared folder: `\\uhco-share\testing\defects\` (ask Test Lead for location)
- [ ] OR send via email to Test Lead with subject: `[DEFECT] Scenario ID - Title`
- [ ] OR fill directly into a tracking spreadsheet (Test Lead will provide)

---

## Retest Instructions

### When to Retest

After a defect is logged and fixed, you will be asked to retest that scenario.

### How to Retest

1. **Check with Test Lead**
   - Confirm the fix is deployed to test environment
   - Ask: "Is fix for defect UE-002 ready for retest?"

2. **Execute the Same Scenario Again**
   - Follow the exact steps from the original test
   - Use the same test account and test data
   - Note: Database may have been reset, so test data might be fresh

3. **Compare to Expected Result**
   - Does it match now?
   - If yes → **PASS (Retest)**. Done!
   - If no → May be a different issue. Log as new defect or note variation.

4. **Update Your Tracking Sheet**
   - Mark original scenario as "Retest Passed" or "Retest Failed"
   - Add comment: "Fix verified on [date]" or "Still failing, variant: [details]"

---

## Daily Standup Summary Template

Fill this out at the end of each testing day. Share with Test Lead.

```
**TEST DAY SUMMARY**
**Date:** [Today's date]
**Tester Name:** [Your name]

**Scenarios Executed Today:**
- Total scenarios run: [e.g., 8]
- Passed: [e.g., 7]
- Failed: [e.g., 1]

**Defects Found (by Severity):**
- Critical: [e.g., 0]
- High: [e.g., 1]
- Medium: [e.g., 0]
- Low: [e.g., 0]

**Critical Defects (Blocking):**
[If any, list them here with IDs]

**High-Priority Defects:**
- [Scenario ID]: [Brief description]
- [Scenario ID]: [Brief description]

**Blockers for Tomorrow:**
- [Any environment issues, missing test data, etc.]

**Next Scenarios to Test:**
- [Which scenarios are you starting with tomorrow?]

**Notes:**
- [Any observations, confusing UI, or suggestions for test guide updates]
```

---

## Example Test Session Walk-Through

### Scenario UE-001: Search & Open User Profile

**Your Actions:**

1. Open browser, navigate to app
2. Search box appears; type "TestFaculty"
3. Click Search button
4. Result: User "TestFaculty Current" appears in list
5. Click on the user row
6. Edit page loads; I see General tab open with fields:
   - First Name: "TestFaculty"
   - Last Name: "Current"
   - Title: "Associate Professor"
   - Sidebar shows tabs: General, Contact, Degrees, Academic Info, Student Profile

**Compare to Expected Result:**

Expected says: "User profile opens on General tab; first name 'TestFaculty', last name 'Current' visible; all tabs present"

**Your Observation:**
- ✅ Opened on General tab
- ✅ First name visible: "TestFaculty"
- ✅ Last name visible: "Current"
- ✅ Tabs present (General, Contact, Degrees, Academic Info, Student Profile)

**Conclusion:** **PASS** — Scenario matches expected result

---

### Scenario UE-E03: Repeatable Field Stress (10 Emails)

**Your Actions:**

1. Open user TestFaculty on Contact tab
2. Click "Add Email" button 9 times to create 10 email rows
3. Fill in: test1@uh.edu, test2@uh.edu, ..., test10@uh.edu
4. Click Save
5. Refresh page (F5)
6. Count emails: I see only 5 emails displayed (not 10)

**Compare to Expected Result:**

Expected says: "All 10 emails saved and displayed; no truncation or loss; order preserved"

**Your Observation:**
- ❌ Only 5 emails visible (not 10)
- ❌ Lost 5 emails during save or refresh

**Conclusion:** **FAIL** — Defect found!

**Defect Logging:**

```
**Scenario ID:** UE-E03
**Severity:** High
**Title:** Repeatable Field Stress Test - 10 Emails Not Persisting

**Steps to Reproduce:**
1. Open TestFaculty user on Contact tab
2. Click "Add Email" 9 times (create 10 total email rows)
3. Fill in emails: test1@uh.edu through test10@uh.edu
4. Click Save
5. Refresh page (F5)

**Expected Result:**
All 10 emails displayed and saved

**Actual Result:**
Only 5 emails displayed after refresh; 5 lost

**Screenshot:** [attached: retest-UE-E03-only5emails.png]

**Additional Notes:**
- No error message shown
- Save appeared to complete successfully
- Emails 6-10 disappeared after refresh
- Suggests array size limit or truncation in save logic

**Logged by:** Jane Tester
**Date & Time:** 2026-04-21 14:30
**Status:** New
```

---

## Quick Reference Checklist

### Before Each Test Day
- [ ] App is stable (no 500 errors)
- [ ] I'm logged in with the correct test account role
- [ ] I have my scenario list and tracking sheet
- [ ] Test data is in place (users, images, etc.)

### During Each Scenario
- [ ] I read the scenario ID and title
- [ ] I check the Role — am I logged in as the right account?
- [ ] I check Preconditions — is the test data ready?
- [ ] I execute steps EXACTLY as written
- [ ] I compare Actual to Expected
- [ ] I record Pass/Fail on tracking sheet

### When I Find a Defect
- [ ] I take a screenshot
- [ ] I fill out the defect form completely
- [ ] I send it to Test Lead immediately if Critical
- [ ] I continue testing if High/Medium/Low (don't pause)

### End of Each Day
- [ ] I fill in Daily Summary
- [ ] I count passed/failed by severity
- [ ] I report blockers and next scenarios
- [ ] I share summary with Test Lead

---

## FAQ for Non-Developer Testers

**Q: I see an error message I don't understand. Should I log it as a defect?**
A: Yes! Any error message you didn't expect is a defect. Screenshot it and note the exact message.

**Q: Should I try to fix or workaround an issue?**
A: No. If something doesn't work as expected, log it and move on. Don't try to be clever or find alternative paths.

**Q: What if I'm confused about what a field is?**
A: Ask Test Lead. It's better to ask than to guess and run the wrong test.

**Q: Can I skip a scenario if I've already tested something similar?**
A: No. Run every scenario in order, even if they seem similar. Different scenarios test different edge cases.

**Q: How long should each scenario take?**
A: 3-10 minutes usually. If you're stuck on a scenario for > 15 minutes, ask Test Lead for help.

**Q: What if the app crashes or shows a 500 error?**
A: Screenshot it. Note the URL. Report to Test Lead immediately. Don't continue testing until environment is stable.

**Q: Do I need to understand how the app works?**
A: No. Your job is to execute scenarios exactly as written and report what you observe. Understanding the "why" is the developer's job.

**Q: Should I test UI/UX (like button colors or layout)?**
A: No, not in Phase 1-2. Functional testing (does it work?) comes first. UI/UX feedback is Phase 3, only after core features work reliably.

---

## Support & Escalation

### If You Get Stuck:
1. Check this guide for the common action
2. Ask Test Lead in person or via Slack/email
3. If blocker, report immediately (don't wait until end of day)

### If You Find a Critical Defect:
1. Screenshot it
2. Log it
3. **Report to Test Lead immediately** (same hour, not end of day)
4. Stop testing that workflow until fix confirmed

### If App Is Down or Unstable:
1. Don't continue testing
2. Report to Test Lead right away
3. Test Lead will coordinate with dev/infrastructure

---

## Wrap-Up

You're now ready to execute the test matrix! Remember:

- **Follow steps exactly**
- **Compare to expected results**
- **Log defects clearly**
- **Report blockers early**
- **Focus on functionality first, UI/UX later**

Good luck! 🎯
