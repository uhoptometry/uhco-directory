# Step 3: Core Functional Test Matrix (Phase 1 Happy Paths)

## Overview

This document contains the main test matrix organized by workflow. Each test case includes:
- **ID**: Unique identifier (e.g., UE-001)
- **Workflow**: Which functional area
- **Scenario**: What is being tested
- **Role**: Which test account to use
- **Preconditions**: What state must exist before starting
- **Steps**: Exact sequence to execute
- **Expected Result**: What should happen
- **Severity if Failed**: Impact level if this test fails

---

## WORKFLOW 1: User Editing

### UE-001: Search & Open User Profile

| Field | Value |
|-------|-------|
| **ID** | UE-001 |
| **Workflow** | User Editing |
| **Scenario** | Admin searches for user by name and opens profile |
| **Role** | testadmin.user@uhco.local (UserAdmin) |
| **Preconditions** | TestFaculty_Current user exists in database |
| **Steps** | 1. Navigate to [admin/users/index.cfm](admin/users/index.cfm) 2. In search box, type "TestFaculty" 3. Click Search 4. Click user row for TestFaculty_Current 5. Observe edit.cfm loads |
| **Expected Result** | User profile opens on General tab; first name "TestFaculty", last name "Current" visible; all tabs present (General, Contact, Degrees, etc.) |
| **Severity if Fail** | Critical (cannot proceed to edit) |
| **Notes** | Verify no 404/500 errors; page fully loads |

---

### UE-002: Edit General Info (Name) & Save

| Field | Value |
|-------|-------|
| **ID** | UE-002 |
| **Workflow** | User Editing |
| **Scenario** | Edit first name, trigger AJAX save, verify persistence |
| **Role** | testadmin.user@uhco.local (UserAdmin) |
| **Preconditions** | TestFaculty_Current user open in edit.cfm; currently on General tab |
| **Steps** | 1. In "First Name" field, clear current text 2. Type "TestFacultyUpdated" 3. Tab out of field or click elsewhere (triggers AJAX save) 4. Observe success message or save indicator 5. Refresh page (F5 or navigate away and back) 6. Re-open user edit page |
| **Expected Result** | After refresh, first name displays as "TestFacultyUpdated"; no data loss; user fully opens without error |
| **Severity if Fail** | Critical (data not persisting = data loss risk) |
| **Notes** | Success message may be toast notification or inline indicator; must verify with refresh, not just page state |

---

### UE-003: Add Email Address

| Field | Value |
|-------|-------|
| **ID** | UE-003 |
| **Workflow** | User Editing |
| **Scenario** | Add second email address to Contact tab |
| **Role** | testadmin.user@uhco.local (UserAdmin) |
| **Preconditions** | TestFaculty_Current open on Contact tab; currently 1 email (testfaculty.current@uh.edu) |
| **Steps** | 1. On Contact tab, scroll to "Email Addresses" section 2. Click "Add Email" or "+" button 3. In new row, enter "testfaculty.secondary@uh.edu" 4. Optionally select email type (e.g., "Personal") 5. Tab or click Save 6. Refresh page |
| **Expected Result** | After save and refresh, both emails listed; original primary email and new secondary both present in database; no data loss |
| **Severity if Fail** | High (repeatable field not persisting) |
| **Notes** | Repeatable fields are critical; test boundary case later (5+ emails) in Phase 2 |

---

### UE-004: Remove Phone Number

| Field | Value |
|-------|-------|
| **ID** | UE-004 |
| **Workflow** | User Editing |
| **Scenario** | Remove a phone number from repeatable field |
| **Role** | testadmin.user@uhco.local (UserAdmin) |
| **Preconditions** | TestFaculty_Current has 2 phone numbers; open on Contact tab |
| **Steps** | 1. In Phone Numbers section, locate second phone row 2. Click "Remove" or X button 3. Observe row disappears from form 4. Tab or click Save 5. Refresh page |
| **Expected Result** | After save and refresh, only first phone remains; second phone is gone; no orphaned records left in DB |
| **Severity if Fail** | High (data not deleting = potential data integrity issue) |
| **Notes** | Verify deletion is permanent, not hidden by UI |

---

### UE-005: Assign Flag & Verify Tab Visibility Toggle

| Field | Value |
|-------|-------|
| **ID** | UE-005 |
| **Workflow** | User Editing |
| **Scenario** | Assign/remove flag and verify dependent UI tabs appear/disappear |
| **Role** | testadmin.user@uhco.local (UserAdmin) |
| **Preconditions** | TestIneligible_NoFlags user (no flags currently); open in edit.cfm |
| **Steps** | 1. On General tab, in Flags section, check "current-student" checkbox 2. Save 3. Observe whether Academic Info or Student Profile tabs appear 4. Uncheck "current-student" 5. Save 6. Observe tabs disappear or become unavailable |
| **Expected Result** | When "current-student" flag assigned, relevant tabs visible/enabled; when removed, tabs hidden/disabled; no errors |
| **Severity if Fail** | High (flag-driven logic broken; UI inconsistent with data) |
| **Notes** | Different flags may show/hide different tabs; verify mapping aligns with app behavior |

---

### UE-006: Assign Organization with Role & Order

| Field | Value |
|-------|-------|
| **ID** | UE-006 |
| **Workflow** | User Editing |
| **Scenario** | Assign user to organization with role title and display order |
| **Role** | testadmin.user@uhco.local (UserAdmin) |
| **Preconditions** | TestMedia_Ready user (no org assignments); organizations seeded; open in edit.cfm |
| **Steps** | 1. On General tab, scroll to Organizations section 2. Click "Add Organization" 3. Select "Nursing Program" from dropdown 4. Enter RoleTitle "Student" 5. Set RoleOrder "1" 6. Save 7. Refresh page |
| **Expected Result** | After save and refresh, user displays "Nursing Program" with role "Student"; appears in org hierarchy correctly |
| **Severity if Fail** | High (org assignments not persisting; hierarchy may not work) |
| **Notes** | Multiple orgs per user allowed; test order value in Phase 2 |

---

### UE-007: Edit Academic Year (Grad Year)

| Field | Value |
|-------|-------|
| **ID** | UE-007 |
| **Workflow** | User Editing |
| **Scenario** | Edit CurrentGradYear and verify validation/persistence |
| **Role** | testadmin.user@uhco.local (UserAdmin) |
| **Preconditions** | TestFaculty_Current open on Academic Info tab |
| **Steps** | 1. Locate CurrentGradYear field 2. Clear and enter "2027" (next year) 3. Save 4. Refresh page 5. Verify value persisted |
| **Expected Result** | Grad year updated to 2027; flag status may change; no error message |
| **Severity if Fail** | High (academic year not persisting; impacts class-based filtering) |
| **Notes** | Boundary test edge values (1900, future year) in Phase 2 |

---

### UE-007A: Multi-Degree Grad Year Filter Coverage

| Field | Value |
|-------|-------|
| **ID** | UE-007A |
| **Workflow** | User Editing |
| **Scenario** | Verify Users list grad-year filter matches all UHCO degree years for a multi-degree user and displays the combined year/program format |
| **Role** | testadmin.user@uhco.local (UserAdmin) |
| **Preconditions** | A test user exists with two UHCO degrees/years (example: OD 2020 and PhD 2026); user is active and visible on [admin/users/index.cfm](admin/users/index.cfm) in an academic list view |
| **Steps** | 1. Navigate to [admin/users/index.cfm](admin/users/index.cfm?list=all) 2. Set Grad Year filter to 2020 and apply 3. Confirm test user appears in results 4. Set Grad Year filter to 2026 and apply 5. Confirm same user appears in results 6. Verify Grad Year column for that user shows combined format `(2020 : OD | 2026 : PHD)` 7. Verify grad-year dropdown contains both 2020 and 2026 |
| **Expected Result** | User appears under both filter years (2020 and 2026); Grad Year display shows combined pair format for multi-degree users; no regression to legacy single-year-only filtering |
| **Severity if Fail** | Critical (core user-list filtering is incomplete for multi-degree records) |
| **Notes** | This is a regression guard for degree-table-based grad year logic with legacy fallback |

---

### UE-008: Edit Bio (Rich Text)

| Field | Value |
|-------|-------|
| **ID** | UE-008 |
| **Workflow** | User Editing |
| **Scenario** | Edit user bio with rich text editor and verify HTML saved correctly |
| **Role** | testadmin.user@uhco.local (UserAdmin) |
| **Preconditions** | TestFaculty_Current open on Bio tab; bio editor (Quill or similar) visible |
| **Steps** | 1. Click in bio editor 2. Type or paste text: "Research interests include **medical education** and **anatomy simulation**" 3. Format "medical education" as bold 4. Save 5. Refresh page |
| **Expected Result** | Bio displays with bold formatting preserved; no HTML escaping errors; text readable |
| **Severity if Fail** | Medium (rich text corruption could lose formatting or expose raw HTML) |
| **Notes** | Test HTML escaping (XSS prevention) in Phase 2 with malicious input |

---

## WORKFLOW 2: User Media - Source Management

### UM-001: Add Local Image Source

| Field | Value |
|-------|-------|
| **ID** | UM-001 |
| **Workflow** | User Media - Sources |
| **Scenario** | Upload/add local image as new source |
| **Role** | testadmin.media@uhco.local (MediaAdmin) |
| **Preconditions** | TestMedia_Ready user exists; no existing sources; test image file ready in [_temp_source/test_images/](../../_temp_source/test_images/) |
| **Steps** | 1. Navigate to [admin/user-media/index.cfm](admin/user-media/index.cfm) 2. Search for "TestMedia_Ready" 3. Click user row 4. On [sources.cfm](admin/user-media/sources.cfm), click "Add Source" or "Upload" 5. Select "Local Folder" as source type 6. Browse to [_temp_source/test_images/](../../_temp_source/test_images/), select "testmedia_ready.jpg" 7. Click "Confirm" or "Add" 8. Observe source added to list |
| **Expected Result** | Source appears in user's source list with status "active"; file is associated; ready for variant assignment |
| **Severity if Fail** | Critical (media workflow blocked) |
| **Notes** | Verify source ID generated and stored correctly |

---

### UM-002: Load Source Files & Verify List

| Field | Value |
|-------|-------|
| **ID** | UM-002 |
| **Workflow** | User Media - Sources |
| **Scenario** | Load/browse files for a source and verify file list displayed |
| **Role** | testadmin.media@uhco.local (MediaAdmin) |
| **Preconditions** | TestMedia_Ready has one source (from UM-001) |
| **Steps** | 1. On [sources.cfm](admin/user-media/sources.cfm) for TestMedia_Ready, click on added source row 2. Click "Load Source Images" or similar button 3. Wait for file list to load (may be AJAX) 4. Observe file list displayed with thumbnails/filenames |
| **Expected Result** | File list appears showing "testmedia_ready.jpg"; filename and/or thumbnail visible; no errors |
| **Severity if Fail** | High (cannot see files; variants cannot be assigned) |
| **Notes** | Loading may be async; check for loading spinner and wait if needed |

---

### UM-003: Deactivate Source

| Field | Value |
|-------|-------|
| **ID** | UM-003 |
| **Workflow** | User Media - Sources |
| **Scenario** | Deactivate an existing source (mark inactive, not delete) |
| **Role** | testadmin.media@uhco.local (MediaAdmin) |
| **Preconditions** | TestMedia_Ready has one active source |
| **Steps** | 1. On [sources.cfm](admin/user-media/sources.cfm), locate source in list 2. Click "Deactivate" or toggle switch 3. Observe source status changes to "inactive" 4. Refresh page |
| **Expected Result** | Source status shows "inactive"; no longer available for new variant assignment; existing variants remain (but marked stale) |
| **Severity if Fail** | High (active/inactive state not persisting) |
| **Notes** | Deactivation should not delete; verify in DB that source still exists |

---

### UM-004: Delete Source

| Field | Value |
|-------|-------|
| **ID** | UM-004 |
| **Workflow** | User Media - Sources |
| **Scenario** | Delete an inactive source and verify it is removed |
| **Role** | testadmin.media@uhco.local (MediaAdmin) |
| **Preconditions** | TestMedia_Ready has one inactive source (from UM-003) |
| **Steps** | 1. On [sources.cfm](admin/user-media/sources.cfm), locate inactive source 2. Click "Delete" button 3. Confirm deletion in modal/dialog 4. Observe source removed from list 5. Refresh page |
| **Expected Result** | Source deleted and no longer appears in list; associated variants also deleted or orphaned (verify cleanup); no errors |
| **Severity if Fail** | High (orphaned records; data integrity risk) |
| **Notes** | Verify cascade delete on variants; no orphaned records left |

---

## WORKFLOW 3: User Media - Variants & Publishing

### UV-001: Assign Variant Type to Source

| Field | Value |
|-------|-------|
| **ID** | UV-001 |
| **Workflow** | User Media - Variants |
| **Scenario** | Assign a variant type (e.g., "Headshot") to a source |
| **Role** | testadmin.media@uhco.local (MediaAdmin) |
| **Preconditions** | TestMedia_Ready has one active source with files loaded; variant types seeded (e.g., "Headshot", "Directory Listing") |
| **Steps** | 1. From [sources.cfm](admin/user-media/sources.cfm), click on source or "Manage Variants" button 2. Navigate to [variants.cfm](admin/user-media/variants.cfm) for this source 3. Click "Assign Variant Type" or checkboxes 4. Select "Headshot" variant type 5. Click "Assign" or Save 6. Refresh page |
| **Expected Result** | Variant type "Headshot" assigned to source; variant status shows "stale" or "pending generation"; no errors |
| **Severity if Fail** | Critical (variant workflow blocked) |
| **Notes** | Variant status should be "stale" until generated |

---

### UV-002: Generate Variant

| Field | Value |
|-------|-------|
| **ID** | UV-002 |
| **Workflow** | User Media - Variants |
| **Scenario** | Generate a variant from source image (crop/resize as applicable) |
| **Role** | testadmin.media@uhco.local (MediaAdmin) |
| **Preconditions** | TestMedia_Ready has Headshot variant assigned (from UV-001); variant status is "stale" |
| **Steps** | 1. On [variants.cfm](admin/user-media/variants.cfm), locate Headshot variant 2. Click "Generate" button 3. If crop UI appears, accept default crop 4. Wait for generation to complete (may show progress) 5. Observe variant status changes to "current" or "ready" |
| **Expected Result** | Variant generated; status changes to "current"/"ready"; temp file created in [_temp_source/](../../_temp_source/) or similar; no errors |
| **Severity if Fail** | Critical (cannot publish if generation fails) |
| **Notes** | May take 5-10 seconds; look for loading indicator |

---

### UV-003: Publish Variant

| Field | Value |
|-------|-------|
| **ID** | UV-003 |
| **Workflow** | User Media - Variants |
| **Scenario** | Publish generated variant to public folder |
| **Role** | testadmin.media@uhco.local (MediaAdmin) |
| **Preconditions** | TestMedia_Ready has Headshot variant with status "current"/"ready" |
| **Steps** | 1. On [variants.cfm](admin/user-media/variants.cfm), locate generated Headshot variant 2. Click "Publish" button 3. Confirm publication if modal appears 4. Wait for completion 5. Verify file appears in [_published_images/](../../_published_images/) folder |
| **Expected Result** | Variant published to [_published_images/](../../_published_images/); file is readable/accessible; variant status shows "published" or "active"; database records URL |
| **Severity if Fail** | Critical (published image not accessible) |
| **Notes** | File should follow naming convention from app config (e.g., userid_varianttype.jpg) |

---

### UV-004: Verify Published File Exists & Is Accessible

| Field | Value |
|-------|-------|
| **ID** | UV-004 |
| **Workflow** | User Media - Variants |
| **Scenario** | Verify published image is accessible and named correctly |
| **Role** | testadmin.media@uhco.local (MediaAdmin) |
| **Preconditions** | Headshot variant published (from UV-003) |
| **Steps** | 1. Open file browser/Windows Explorer 2. Navigate to [_published_images/](../../_published_images/) 3. Look for file matching TestMedia_Ready's published output 4. Expected filename pattern: e.g., "testmediaready_headshot.jpg" or similar per app config 5. Open file in image viewer to confirm readable |
| **Expected Result** | Published file exists in correct folder; filename follows convention; image is valid and displayable; no corruption |
| **Severity if Fail** | Critical (published content not accessible) |
| **Notes** | Filename should be predictable per app config media.image_naming convention |

---

### UV-005: Re-Publish Updates Old Published File

| Field | Value |
|-------|-------|
| **ID** | UV-005 |
| **Workflow** | User Media - Variants |
| **Scenario** | Publish new version of same variant; old file replaced without creating duplicate |
| **Role** | testadmin.media@uhco.local (MediaAdmin) |
| **Preconditions** | Headshot already published (from UV-003); new source file ready |
| **Steps** | 1. Note the current published file timestamp/size 2. Deactivate current source 3. Add new source with different image 4. Assign Headshot variant to new source 5. Generate and Publish 6. Verify file in [_published_images/](../../_published_images/) has updated timestamp/size |
| **Expected Result** | Published file replaced; old version overwritten (no duplicate files); timestamp/size changes; URL remains same |
| **Severity if Fail** | High (orphaned/duplicate files accumulate; disk usage grows) |
| **Notes** | Ensures cleanup of old published files is working |

---

## WORKFLOW 4: User Review Submission

### UR-001: Eligible User Logs In & Sees Review Form

| Field | Value |
|-------|-------|
| **ID** | UR-001 |
| **Workflow** | User Review - Submission |
| **Scenario** | Eligible user (with flag) logs into UserReview and sees submission form |
| **Role** | testfaculty.current@uh.edu (TestFaculty_Current, faculty-fulltime + current-student flags) |
| **Preconditions** | UserReview feature enabled; TestFaculty_Current flagged as "current-student" or "faculty-fulltime"; user can authenticate |
| **Steps** | 1. Navigate to [userreview/index.cfm](userreview/index.cfm) 2. Log in as testfaculty.current@uh.edu 3. Observe page loads and shows "Your Profile Review" or similar header 4. Verify form sections visible (General, Contact, Bio per configuration) |
| **Expected Result** | User review form loads; sections editable; user can see current profile data as read-only reference; submission form ready |
| **Severity if Fail** | Critical (user cannot submit) |
| **Notes** | Verify eligible users can access; ineligible users blocked on next test |

---

### UR-002: Ineligible User Sees "Not Eligible" Message

| Field | Value |
|-------|-------|
| **ID** | UR-002 |
| **Workflow** | User Review - Submission |
| **Scenario** | Ineligible user (no flag) attempts review; sees error or message |
| **Role** | testineligible.noflags@uh.edu (TestIneligible_NoFlags, no flags) |
| **Preconditions** | TestIneligible_NoFlags has no flags (not current-student, alumni, faculty, staff) |
| **Steps** | 1. Navigate to [userreview/index.cfm](userreview/index.cfm) 2. Log in as testineligible.noflags@uh.edu 3. Observe behavior: either redirected to error page or shown message |
| **Expected Result** | Ineligible user cannot access form; shown message like "You are not eligible for profile review" or redirected to unavailable page; no form displayed |
| **Severity if Fail** | High (ineligible users could submit; review control broken) |
| **Notes** | Verify eligibility check works correctly |

---

### UR-003: Edit Eligible Section & Submit Review

| Field | Value |
|-------|-------|
| **ID** | UR-003 |
| **Workflow** | User Review - Submission |
| **Scenario** | Eligible user edits allowed section and submits review |
| **Role** | testfaculty.current@uh.edu (TestFaculty_Current) |
| **Preconditions** | Logged into UserReview form; General tab shows current pronouns "He/Him" |
| **Steps** | 1. In form, locate editable Pronouns field 2. Change to "They/Them" 3. Add note in Contact section if applicable (e.g., new email) 4. Click "Submit" button 5. Observe confirmation or redirect |
| **Expected Result** | Submission succeeds; user redirected to confirmation page or sees "submitted" message; submission is now in admin queue |
| **Severity if Fail** | Critical (user cannot submit; form blocked) |
| **Notes** | Verify submission creates record in UserReviewSubmissions table |

---

### UR-004: Submitted Review Appears in Admin Queue

| Field | Value |
|-------|-------|
| **ID** | UR-004 |
| **Workflow** | User Review - Submission |
| **Scenario** | Admin logs in and sees submitted review in pending queue |
| **Role** | testadmin.reviewer@uhco.local (ReviewerAdmin) |
| **Preconditions** | User submitted review (from UR-003); review in "pending" status |
| **Steps** | 1. Log in as testadmin.reviewer@uhco.local 2. Navigate to [admin/settings/user-review/index.cfm](admin/settings/user-review/index.cfm) 3. Observe pending submissions list 4. Look for TestFaculty_Current's submission with timestamp |
| **Expected Result** | Submission appears in pending queue with user name, date submitted, and link to review |
| **Severity if Fail** | Critical (admin cannot see submissions) |
| **Notes** | Status should show "pending" not "approved" or "rejected" yet |

---

## WORKFLOW 5: User Review Approval

### UA-001: Admin Reviews Single Submission (Approve All)

| Field | Value |
|-------|-------|
| **ID** | UA-001 |
| **Workflow** | User Review - Approval |
| **Scenario** | Admin opens submission, reviews diffs, approves all fields |
| **Role** | testadmin.reviewer@uhco.local (ReviewerAdmin) |
| **Preconditions** | TestFaculty_Current has pending submission (Pronouns changed to "They/Them") |
| **Steps** | 1. On [admin/settings/user-review/index.cfm](admin/settings/user-review/index.cfm), click TestFaculty_Current's submission 2. On [review.cfm](admin/settings/user-review/review.cfm), review proposed changes displayed (Pronouns: "He/Him" → "They/Them") 3. Click "Approve All" button 4. Confirm in modal if shown 5. Observe redirect or status update |
| **Expected Result** | Submission approved; all fields applied; status changes to "approved"; user sees approval confirmation on next login |
| **Severity if Fail** | Critical (approval action fails; submission stuck) |
| **Notes** | Verify DB record updated with approval time and admin ID |

---

### UA-002: Admin Rejects Submission (Reject All)

| Field | Value |
|-------|-------|
| **ID** | UA-002 |
| **Workflow** | User Review - Approval |
| **Scenario** | Admin rejects entire submission with note |
| **Role** | testadmin.reviewer@uhco.local (ReviewerAdmin) |
| **Preconditions** | TestStaff_Alumni has pending submission with edits |
| **Steps** | 1. On review.cfm for TestStaff_Alumni, click "Reject All" 2. In dialog/modal, enter rejection reason: "Please resubmit with complete information" 3. Confirm rejection 4. Observe status changes to "rejected" |
| **Expected Result** | Submission rejected; review note stored; status shows "rejected"; user sees note on next login |
| **Severity if Fail** | Critical (rejection action fails) |
| **Notes** | Verify rejection note is visible to user in UserReview interface |

---

### UA-003: Admin Partially Approves (Mixed Accept/Reject)

| Field | Value |
|-------|-------|
| **ID** | UA-003 |
| **Workflow** | User Review - Approval |
| **Scenario** | Admin approves some fields, rejects others with reason |
| **Role** | testadmin.reviewer@uhco.local (ReviewerAdmin) |
| **Preconditions** | TestMedia_Ready has pending submission with 3 field changes (Pronouns, Email, Bio) |
| **Steps** | 1. On review.cfm, view 3 proposed changes 2. For Pronouns: click "Approve" 3. For Email: click "Reject" and add note "Email must be @uh.edu" 4. For Bio: click "Approve" 5. Click "Save" or "Submit All Decisions" 6. Observe final status |
| **Expected Result** | Submission status changes to "partially_approved"; Pronouns applied, Email rejected, Bio applied; user sees which fields rejected and why |
| **Severity if Fail** | High (partial approval logic broken; all/nothing applied instead) |
| **Notes** | Test field-level granularity |

---

### UA-004: User Sees Approval Result After Login

| Field | Value |
|-------|-------|
| **ID** | UA-004 |
| **Workflow** | User Review - Approval |
| **Scenario** | User logs back in and sees approval status and applied changes |
| **Role** | testfaculty.current@uh.edu (TestFaculty_Current, submission approved from UA-001) |
| **Preconditions** | TestFaculty_Current's submission approved (Pronouns change applied); user logged out |
| **Steps** | 1. Log in as testfaculty.current@uh.edu 2. Navigate to UserReview or account profile 3. Observe approval status: "Approved" badge or message 4. Verify Pronouns field in profile now shows "They/Them" (applied change) |
| **Expected Result** | User sees "Approved" status; changes applied to profile; confirmation date shown |
| **Severity if Fail** | High (user doesn't know status; changes not applied) |
| **Notes** | Verify user-visible feedback |

---

## WORKFLOW 6: Permission Boundaries

### PB-001: MediaAdmin Denied Access to User Edit

| Field | Value |
|-------|-------|
| **ID** | PB-001 |
| **Workflow** | Permission Boundaries |
| **Scenario** | MediaAdmin cannot edit users (not in their role) |
| **Role** | testadmin.media@uhco.local (MediaAdmin) |
| **Preconditions** | MediaAdmin logged in; has media.* permissions but NOT users.edit |
| **Steps** | 1. Try to navigate to [admin/users/edit.cfm?userID=123](admin/users/edit.cfm?userID=123) directly 2. Or from [admin/users/index.cfm](admin/users/index.cfm), observe edit link is not available 3. If direct nav attempted, observe behavior |
| **Expected Result** | Access denied; redirected to [admin/unauthorized.cfm](admin/unauthorized.cfm) or error page; no edit form displayed |
| **Severity if Fail** | Critical (access control broken) |
| **Notes** | Verify 403 Forbidden response, not 500 error |

---

### PB-002: UserAdmin Cannot Publish Media

| Field | Value |
|-------|-------|
| **ID** | PB-002 |
| **Workflow** | Permission Boundaries |
| **Scenario** | UserAdmin cannot publish media (media.publish not granted) |
| **Role** | testadmin.user@uhco.local (UserAdmin) |
| **Preconditions** | UserAdmin logged in; has users.edit but NOT media.publish |
| **Steps** | 1. Navigate to [admin/user-media/variants.cfm](admin/user-media/variants.cfm) for a user 2. Try to click "Publish" button on generated variant 3. Observe if button is disabled or action fails |
| **Expected Result** | Either button is disabled/hidden or action fails with "permission denied" message |
| **Severity if Fail** | Critical (access control broken) |
| **Notes** | UI should reflect permission state proactively (disable button) |

---

### PB-003: ReviewerAdmin Cannot Edit Users

| Field | Value |
|-------|-------|
| **ID** | PB-003 |
| **Workflow** | Permission Boundaries |
| **Scenario** | ReviewerAdmin (approve-only role) cannot edit user profiles |
| **Role** | testadmin.reviewer@uhco.local (ReviewerAdmin) |
| **Preconditions** | ReviewerAdmin logged in; has users.approve_user_review but NOT users.edit |
| **Steps** | 1. Try to navigate to [admin/users/edit.cfm?userID=123](admin/users/edit.cfm?userID=123) 2. Or from user review queue, observe edit link is not present |
| **Expected Result** | Access denied; cannot edit user profiles; only review/approve submissions |
| **Severity if Fail** | Critical (ReviewerAdmin could bypass approval by editing directly) |
| **Notes** | Ensure separation of duties |

---

### PB-004: ViewerAdmin Cannot Save Changes

| Field | Value |
|-------|-------|
| **ID** | PB-004 |
| **Workflow** | Permission Boundaries |
| **Scenario** | ViewerAdmin (read-only) cannot modify data; save action blocked |
| **Role** | testadmin.viewer@uhco.local (ViewerAdmin) |
| **Preconditions** | ViewerAdmin logged in; has read-only permissions |
| **Steps** | 1. Navigate to [admin/users/edit.cfm](admin/users/edit.cfm) for a user 2. If form loads, try to edit a field 3. Click Save 4. Observe behavior: either form disabled or POST fails |
| **Expected Result** | Either form is read-only (fields disabled) or POST blocked with "permission denied"; no data changes |
| **Severity if Fail** | Critical (read-only role can modify data) |
| **Notes** | Form should be disabled at server-side AND client-side for best UX |

---

### PB-005: SuperAdmin Can Do All Actions

| Field | Value |
|-------|-------|
| **ID** | PB-005 |
| **Workflow** | Permission Boundaries |
| **Scenario** | SuperAdmin can access and modify users, media, settings, approvals |
| **Role** | testadmin.super@uhco.local (SuperAdmin) |
| **Preconditions** | SuperAdmin logged in; has all permissions (SUPER_ADMIN role) |
| **Steps** | 1. Navigate to [admin/users/edit.cfm](admin/users/edit.cfm) — should load ✅ 2. Navigate to [admin/user-media/variants.cfm](admin/user-media/variants.cfm) — should load ✅ 3. Navigate to [admin/settings/app-config/index.cfm](admin/settings/app-config/index.cfm) — should load ✅ 4. Navigate to [admin/settings/user-review/index.cfm](admin/settings/user-review/index.cfm) — should load ✅ |
| **Expected Result** | All pages load; all buttons/forms enabled; actions succeed |
| **Severity if Fail** | Critical (SuperAdmin role broken) |
| **Notes** | Baseline positive test for full access |

---

## WORKFLOW 7: API QuickPulls

### QP-001: GradClass Uses Degree-Based UHCO Grad Year

| Field | Value |
|-------|-------|
| **ID** | QP-001 |
| **Workflow** | API QuickPulls |
| **Scenario** | Verify `gradclass` quickpull filters by degree-table graduation year and does not emit legacy `CURRENTGRADYEAR` |
| **Role** | Valid API token + secret with Alumni access |
| **Preconditions** | A test alumni user exists with UHCO degrees OD 2020 and PhD 2026; user is active; API auth token and Alumni-enabled secret are available |
| **Steps** | 1. Call [api/v1/handlers/quickpulls.cfm](api/v1/handlers/quickpulls.cfm) via `GET /api/v1/quickpulls/gradclass?year=2020&program=All` 2. Confirm test user appears in response data 3. Call `GET /api/v1/quickpulls/gradclass?year=2026&program=All` 4. Confirm same user appears in response data 5. Inspect returned row payload for that user 6. Verify `CURRENTGRADYEAR` key is not present in the GradClass response |
| **Expected Result** | User appears in both 2020 and 2026 GradClass quickpull responses based on UserDegrees graduation years; GradClass output does not include `CURRENTGRADYEAR`; no fallback to legacy `UserAcademicInfo.CurrentGradYear` is required |
| **Severity if Fail** | Critical (public quickpull data is filtered from legacy/incomplete grad-year source) |
| **Notes** | Regression guard for GradClass parity with the Users list grad-year logic |

---

## Test Matrix Summary

| Workflow | Scenario ID | Scenario | Total |
|----------|-------------|----------|-------|
| User Editing | UE-001 to UE-008 | 8 scenarios | 8 |
| User Media - Sources | UM-001 to UM-004 | 4 scenarios | 4 |
| User Media - Variants | UV-001 to UV-005 | 5 scenarios | 5 |
| User Review - Submit | UR-001 to UR-004 | 4 scenarios | 4 |
| User Review - Approve | UA-001 to UA-004 | 4 scenarios | 4 |
| Permission Boundaries | PB-001 to PB-005 | 5 scenarios | 5 |
| API QuickPulls | QP-001 | 1 scenario | 1 |
| **TOTAL PHASE 1 SCENARIOS** | | | **31** |

---

## Execution Notes

- Execute scenarios in order (UE-001, UE-002, ..., down to PB-005)
- If a Critical-severity test fails, escalate and STOP executing that workflow until resolved
- High-severity failures: log and continue; retest after fix
- All other failures: log and continue
- Record test results in tracking sheet (see Step 5)
- Estimated time: 2-3 hours for all 30 scenarios (3-5 min per scenario average)

---

## Sign-Off & Approval

Before executing test matrix:

- [ ] All test prerequisites completed (Step 2)
- [ ] All test accounts and data seeded
- [ ] Test environment health checks passed
- [ ] Non-developer testers trained on checklist and defect logging
- [ ] Escalation path clear (who to contact if Critical defect found)

**Test Lead:** ___________________  **Date:** ___________

**Triage Owner:** ___________________  **Date:** ___________
