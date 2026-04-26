# Step 2: Test Prerequisites & Environment Guardrails

## Overview

This document specifies:
- Test accounts and their roles/permissions
- Test user data to seed
- Image files/assets needed
- Database reset/cleanup process
- Environment health checks before each test cycle

---

## Test Accounts by Role

### Test Admin Accounts

All test admin accounts should be created in the admin system with appropriate permission grants. Use UHCO_Directory datasource standard.

#### 1. **SuperAdmin** (Full Access)
- **Username/Email:** `testadmin.super@uhco.local` (or CougarNet equivalent)
- **Purpose:** Unrestricted access for baseline testing
- **Role/Permissions:** SUPER_ADMIN role (all permissions)
- **Used for:** Permission boundary checks (positive case), all workflows
- **Creation SQL:** Create user, assign SUPER_ADMIN role

#### 2. **MediaAdmin** (Media-Only Access)
- **Username/Email:** `testadmin.media@uhco.local`
- **Purpose:** Test role-based access control; can manage media, NOT users or settings
- **Role/Permissions:** USER_MEDIA_ADMIN role
  - `media.view` ✅
  - `media.edit` ✅
  - `media.publish` ✅
  - `users.edit` ❌
  - `settings.*` ❌
- **Used for:** Permission boundary tests (negative case for settings/user edit)
- **Expected behavior:** Denied access to [admin/users/edit.cfm](admin/users/edit.cfm), [admin/settings/](admin/settings/)

#### 3. **UserAdmin** (User & Data Management)
- **Username/Email:** `testadmin.user@uhco.local`
- **Purpose:** Can manage users, flags, orgs; cannot manage media or settings
- **Role/Permissions:** USER_ADMIN role (custom)
  - `users.edit` ✅
  - `users.view` ✅
  - `settings.user_review.manage` ✅
  - `media.edit` ❌
  - `media.publish` ❌
- **Used for:** User editing workflows, user review configuration
- **Expected behavior:** Denied access to [admin/user-media/variants.cfm](admin/user-media/variants.cfm)

#### 4. **ReviewerAdmin** (User Review Approval Only)
- **Username/Email:** `testadmin.reviewer@uhco.local`
- **Purpose:** Can approve/reject user review submissions; cannot edit users or media
- **Role/Permissions:** REVIEWER_ADMIN role (custom)
  - `users.approve_user_review` ✅
  - `settings.user_review.manage` ✅
  - `users.edit` ❌
  - `media.edit` ❌
- **Used for:** User review approval scenarios
- **Expected behavior:** Can access [admin/settings/user-review/review.cfm](admin/settings/user-review/review.cfm), denied [admin/users/edit.cfm](admin/users/edit.cfm)

#### 5. **ViewerAdmin** (Read-Only)
- **Username/Email:** `testadmin.viewer@uhco.local`
- **Purpose:** Can view but not modify; tests permission denial on POST actions
- **Role/Permissions:** VIEWER_ADMIN role (custom)
  - `users.view` ✅
  - ALL `*.edit` ❌
  - ALL `*.publish` ❌
- **Used for:** Permission boundary tests (negative case for all mutations)
- **Expected behavior:** Can view users list, denied on save

---

## Test End-User Accounts

Non-admin users eligible for User Review submission and other user-facing features.

### 1. **Faculty User (Current)**
- **First Name:** TestFaculty
- **Last Name:** Current
- **Email:** testfaculty.current@uh.edu
- **Flags:** `faculty-fulltime`, `current-student`
- **Title:** Associate Professor
- **Academic Info:** CurrentGradYear = 2026 (current year)
- **Purpose:** Test UserReview submission for faculty, eligible for current-student status
- **Used in:** UserReview submission/approval scenarios

### 2. **Staff User (Alumni)**
- **First Name:** TestStaff
- **Last Name:** Alumni
- **Email:** teststaff.alumni@uh.edu
- **Flags:** `staff`, `alumni`
- **Title:** Program Coordinator
- **Academic Info:** CurrentGradYear = 2024 (past year)
- **Purpose:** Test UserReview submission for staff + alumni status
- **Used in:** UserReview submission/approval, flag-based visibility

### 3. **Adjunct Faculty**
- **First Name:** TestAdjunct
- **Last Name:** Faculty
- **Email:** testadjunct.faculty@uh.edu
- **Flags:** `faculty-adjunct`
- **Title:** Adjunct Instructor
- **Purpose:** Test faculty flag variation in permission/visibility logic
- **Used in:** Permission boundary tests

### 4. **Ineligible User (No Flags)**
- **First Name:** TestIneligible
- **Last Name:** NoFlags
- **Email:** testineligible.noflags@uh.edu
- **Flags:** (none)
- **Title:** Generic User
- **Purpose:** Test that ineligible users cannot submit reviews, access blocked
- **Used in:** UserReview negative tests (should see "not eligible" message)

### 5. **Active User with Photos Ready**
- **First Name:** TestMedia
- **Last Name:** Ready
- **Email:** testmedia.ready@uh.edu
- **Flags:** `current-student`
- **Title:** Student
- **Purpose:** Pre-seeded user for media upload/variant tests (no need to create user during test)
- **Used in:** User Media workflows (sources, variants, publishing)
- **Pre-populate:**
  - No existing images/sources (clean slate for test)
  - Academic info: CurrentGradYear = 2026

### 6. **Inactive User**
- **First Name:** TestInactive
- **Last Name:** User
- **Email:** testinactive.user@uh.edu
- **Flags:** `current-student`
- **Active:** 0 (disabled)
- **Purpose:** Test that inactive users don't appear in search/approval lists
- **Used in:** Negative tests (should be filtered out)

---

## Test Data: Organizations & Flags

### Organizations (Hierarchy for Testing)

Create the following org hierarchy to test parent-child relationships:

```
College of Medicine (ParentOrgID = NULL)
  ├─ Dean's Office (ParentOrgID = College of Medicine)
  ├─ Anatomy Department (ParentOrgID = College of Medicine)
  │  └─ Medical Education Program (ParentOrgID = Anatomy Department)
  └─ Surgery Department (ParentOrgID = College of Medicine)

School of Allied Health (ParentOrgID = NULL)
  └─ Nursing Program (ParentOrgID = School of Allied Health)
```

**Assign test users to orgs:**
- TestFaculty_Current → Anatomy Department (RoleTitle="Faculty", RoleOrder=1)
- TestStaff_Alumni → Dean's Office (RoleTitle="Staff", RoleOrder=1)
- TestMedia_Ready → Nursing Program (RoleTitle="Student", RoleOrder=1)

### Flags (Minimal Set for Testing)

```
- "current-student" (assigned to TestFaculty_Current, TestMedia_Ready, TestIneligible_NoFlags)
- "alumni" (assigned to TestStaff_Alumni)
- "faculty-fulltime" (assigned to TestFaculty_Current)
- "faculty-adjunct" (assigned to TestAdjunct_Faculty)
- "staff" (assigned to TestStaff_Alumni)
- "public-facing" (assigned to TestFaculty_Current, TestMedia_Ready)
```

### External IDs (for sync/lookup testing)

Create external systems and assign IDs:

```
ExternalSystems:
  - "PeopleSoft" (SystemID = 1)
  - "CougarNet" (SystemID = 2)
  - "UH_API_ID" (SystemID = 3)

ExternalIDs (assign to test users):
  - TestFaculty_Current: PeopleSoft="PS123456", CougarNet="tcurrent", UH_API_ID="UHAPI1001"
  - TestMedia_Ready: PeopleSoft="PS654321", CougarNet="tready", UH_API_ID="UHAPI2001"
```

---

## Test Image Assets

### Required Images

Prepare a test image folder with the following files. All images should be valid JPG/PNG, 500×500px or larger.

#### Local Folder Location
Create: `c:\inetpub\wwwroot\uhco_ident\_temp_source\test_images\`

#### Images to Prepare

1. **testmedia_ready.jpg** (headshot-like)
   - 600×600px, JPG format, ~100KB
   - Clear face/profile photo

2. **ready_testmedia.jpg** (alternate naming)
   - Same as above, different filename pattern
   - Tests filename pattern matching logic

3. **TestMedia_Ready.png** (uppercase variant)
   - 500×500px, PNG format
   - Tests case-sensitivity in filename matching

4. **invalidimage.txt** (negative test)
   - Plain text file, not an image
   - Tests file type filtering (should be rejected or handled gracefully)

5. **corrupt.jpg** (edge case)
   - File header suggests JPG but is truncated/unreadable
   - Tests image validation error handling

6. **large_image.jpg** (boundary test)
   - 4000×4000px, high resolution
   - Tests resize/crop logic at large dimensions

7. **small_image.jpg** (boundary test)
   - 50×50px, very small
   - Tests minimum dimension validation

8. **landscape.jpg** (orientation test)
   - 1200×600px (width > height)
   - Tests orientation detection and crop framing

9. **portrait.jpg** (orientation test)
   - 600×1200px (height > width)
   - Tests portrait variant generation

#### Dropbox Test Folder (If Testing Dropbox Integration)

Create a Dropbox folder: `/UHCO Identity Test/TestImages/`

Upload the same files as above to Dropbox so sources.cfm can browse and select them.

**Dropbox auth requirements:**
- Dropbox API token must be configured in AppConfig
- Test assumes Dropbox integration is already set up
- If Dropbox integration is not stable, focus Phase 1 on LOCAL sources only; defer Dropbox to Phase 2

---

## Database Reset & Cleanup Process

### Pre-Test Reset (Run Before Each Test Cycle)

**Goal:** Remove data created during previous test run so each cycle starts clean.

#### SQL Cleanup Script
Save as: `c:\inetpub\wwwroot\uhco_ident\dev\testing\reset-test-data.sql`

```sql
USE UHCO_Directory;

-- Delete test user submissions (UserReviewSubmissions)
DELETE FROM UserReviewSubmissions 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%' 
);

-- Delete test user images and variants
DELETE FROM UserImageVariants 
WHERE UserImageSourceID IN (
  SELECT UserImageSourceID FROM UserImageSources 
  WHERE UserID IN (
    SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
  )
);

DELETE FROM UserImages 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
);

DELETE FROM UserImageSources 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
);

-- Delete test user roles and orgs
DELETE FROM UserAccessAssignments 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
);

DELETE FROM UserOrganizations 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
);

DELETE FROM UserFlagAssignments 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
);

-- Delete test user contact info
DELETE FROM UserEmails 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
);

DELETE FROM UserPhones 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
);

DELETE FROM UserAddresses 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
);

-- Delete test user academic/profile data
DELETE FROM UserAcademicInfo 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
);

DELETE FROM UserStudentProfile 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
);

DELETE FROM UserDegrees 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
);

DELETE FROM UserAwards 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
);

DELETE FROM UserBio 
WHERE UserID IN (
  SELECT UserID FROM Users WHERE Email LIKE 'test%@%'
);

-- Delete test users themselves
DELETE FROM Users 
WHERE Email LIKE 'test%@%';

-- Verify cleanup
SELECT COUNT(*) AS RemainingTestUsers FROM Users WHERE Email LIKE 'test%@%';
```

#### Manual Reset Steps (If SQL Not Available)
1. Log in as SuperAdmin
2. Go to [admin/users/index.cfm](admin/users/index.cfm)
3. Search for "test"
4. For each test user:
   - Open user
   - Note UserID for reference
   - Click "Delete User" (should cascade delete related records)
5. Clear [_published_images/](../../_published_images/) folder (remove generated variants)
6. Clear [_temp_source/](../../_temp_source/) folder (remove temp uploads)

#### Verify Clean State
- [ ] No test users in Users table (search "test" returns 0 results)
- [ ] [_published_images/](../../_published_images/) folder is empty or contains only baseline images
- [ ] No orphaned UserImageSources or UserImageVariants
- [ ] UserReviewSubmissions contains no pending test submissions

---

## Environment Health Checks (Before Each Test Run)

Run these checks each morning before starting tests:

### 1. Application Availability
- [ ] App loads: `https://localhost/uhco_ident/admin/users/index.cfm`
- [ ] No 500 errors or exception pages
- [ ] Sidebar navigation appears

### 2. Test Database Connectivity
- [ ] ColdFusion datasource `UHCO_Directory` is active (check CF Admin)
- [ ] Any scheduled tasks are running (e.g., UH Sync) — pause if they might interfere with test data
- [ ] No recent DB errors in ColdFusion logs

### 3. Test Accounts Are Active
- [ ] Can log in as `testadmin.super@uhco.local`
- [ ] Can log in as `testadmin.media@uhco.local`
- [ ] CougarNet auth is working (or mock auth if local testing)

### 4. File System Permissions
- [ ] [_temp_source/](../../_temp_source/) is writable (test image uploads)
- [ ] [_published_images/](../../_published_images/) is writable (variant publishing)
- [ ] Dropbox API token (if testing) is valid and not expired

### 5. Configuration Settings
- [ ] `media.source_keys` is configured in AppConfig (check [admin/settings/media-config/](admin/settings/media-config/))
- [ ] Variant types are active (check ImageVariantTypes table — at least 2-3 types)
- [ ] UserReview settings are configured (check [admin/settings/user-review/](admin/settings/user-review/))

### 6. Baseline Image Assets Ready
- [ ] Test images exist in [_temp_source/test_images/](../../_temp_source/test_images/)
- [ ] Dropbox test folder exists and has images (if Dropbox testing)

---

## Test Environment Isolation

### What to Freeze During Test Cycles
- **AppConfig values** (media config, UserReview settings, API keys) — do NOT change mid-cycle
- **Variant types** — do NOT add/remove/deactivate during cycle
- **Admin permissions** — do NOT grant/revoke permissions mid-cycle (after baseline setup)

### What to Allow
- Creating/deleting test users (part of testing)
- Generating/publishing test images (part of testing)
- Submissions/approvals (part of testing)

### What to Monitor
- Server error logs (check daily for exceptions)
- Database lock warnings (sign of concurrent conflicts)
- Disk space (image generation can use space; keep free >10GB)

---

## Sign-Off & Verification

Before proceeding to Step 3 (test matrix creation), confirm:

- [ ] All test admin accounts created and accessible
- [ ] All test end-user accounts created and flagged correctly
- [ ] Organizations and hierarchy seeded
- [ ] Test image assets prepared and stored
- [ ] Reset SQL script tested (runs without errors)
- [ ] Environment health checks pass
- [ ] Test lead and developer lead agree on freeze/thaw boundaries

**Test Lead:** ___________________  **Date:** ___________

**Environment Owner:** ___________________  **Date:** ___________
