# Step 4: High-Risk Edge-Case Matrix (Phase 2)

## Overview

This document defines edge cases and boundary conditions for Phase 2 testing. Execute these ONLY after Phase 1 (happy paths) are stable and no Critical defects remain.

Edge cases test:
- Boundary values (min/max, empty, null)
- Duplicate/concurrent operations
- State transitions and stale data
- Permission changes mid-session
- Error recovery

---

## WORKFLOW 1: User Editing - Edge Cases

### UE-E01: Boundary Test - Empty First Name

| Field | Value |
|-------|-------|
| **ID** | UE-E01 |
| **Workflow** | User Editing - Edge Cases |
| **Scenario** | Attempt to save user with empty first name |
| **Role** | testadmin.user@uhco.local |
| **Preconditions** | User edit form open; first name field populated |
| **Steps** | 1. Clear First Name field 2. Leave empty 3. Tab or click Save 4. Observe validation behavior |
| **Expected Result** | Either: (a) form prevents save with error "First Name required", OR (b) silently rejects (form resets) with toast message. NO blank name in DB. |
| **Severity if Fail** | High (data validation broken; invalid state in DB) |
| **Notes** | Required fields should be enforced client + server side |

---

### UE-E02: Boundary Test - Very Long Name (300+ chars)

| Field | Value |
|-------|-------|
| **ID** | UE-E02 |
| **Workflow** | User Editing - Edge Cases |
| **Scenario** | Paste very long name and verify truncation or error |
| **Role** | testadmin.user@uhco.local |
| **Preconditions** | User edit form open |
| **Steps** | 1. In First Name field, paste 300+ character string 2. Attempt save 3. Observe if truncated or rejected |
| **Expected Result** | Either: (a) field max-length enforced (e.g., 100 chars), truncated on save, OR (b) validation error displayed. Name stored correctly truncated or error shown. NO corruption. |
| **Severity if Fail** | Medium (name might be corrupted or overflow columns in display) |
| **Notes** | Database schema should have max length defined |

---

### UE-E03: Edge Case - Repeatable Field Stress (10 Emails)

| Field | Value |
|-------|-------|
| **ID** | UE-E03 |
| **Workflow** | User Editing - Edge Cases |
| **Scenario** | Add and save 10 email addresses to same user |
| **Role** | testadmin.user@uhco.local |
| **Preconditions** | User in Contact tab; initially 1 email |
| **Steps** | 1. Click "Add Email" 9 times 2. Fill in: test1@uh.edu, test2@uh.edu, ..., test10@uh.edu 3. Save 4. Refresh page 5. Verify all 10 persisted |
| **Expected Result** | All 10 emails saved and displayed; no truncation or loss; order preserved |
| **Severity if Fail** | High (repeatable fields failing at scale) |
| **Notes** | Tests array handling and bulk persistence |

---

### UE-E04: Edge Case - Academic Year Boundary (Invalid Year 1899, Future Year 2050)

| Field | Value |
|-------|-------|
| **ID** | UE-E04 |
| **Workflow** | User Editing - Edge Cases |
| **Scenario** | Attempt to set grad year outside valid range |
| **Role** | testadmin.user@uhco.local |
| **Preconditions** | User on Academic Info tab |
| **Steps** | 1. Try to set CurrentGradYear to 1899 2. Save 3. Observe response 4. Try CurrentGradYear to 2050 (future) 5. Save 6. Observe response |
| **Expected Result** | Both rejected with error message like "Year must be >= 1900 and <= [current+1]". OR if future year allowed per app logic, it saves. Consistent behavior documented. |
| **Severity if Fail** | Medium (boundary validation not enforced) |
| **Notes** | Verify app's actual range logic in code |

---

### UE-E05: Edge Case - Bio XSS Attempt (Script Tag in Rich Text)

| Field | Value |
|-------|-------|
| **ID** | UE-E05 |
| **Workflow** | User Editing - Edge Cases |
| **Scenario** | Paste HTML/script into bio editor; verify escaping |
| **Role** | testadmin.user@uhco.local |
| **Preconditions** | User on Bio tab with rich text editor |
| **Steps** | 1. In bio editor, paste: `<script>alert('xss')</script>` 2. Save 3. Refresh page 4. View bio in admin and end-user profile 5. Verify no script execution |
| **Expected Result** | Script tag escaped or stripped; bio displays as literal text (not executed); no console errors |
| **Severity if Fail** | Critical (XSS vulnerability) |
| **Notes** | Security test; should be strict escaping |

---

## WORKFLOW 2: User Media - Edge Cases

### UM-E01: Edge Case - Add Same Source Twice (Duplicate Prevention)

| Field | Value |
|-------|-------|
| **ID** | UM-E01 |
| **Workflow** | User Media - Sources |
| **Scenario** | Attempt to add same source file twice |
| **Role** | testadmin.media@uhco.local |
| **Preconditions** | User has one source (testmedia_ready.jpg) already added |
| **Steps** | 1. Click "Add Source" again 2. Select same file (testmedia_ready.jpg) 3. Try to add 4. Observe behavior |
| **Expected Result** | Either: (a) duplicate prevented with message "Source already exists", OR (b) second source created but flagged as duplicate. NO silent duplicate creates |
| **Severity if Fail** | High (duplicate sources create confusion; variants assigned to wrong source) |
| **Notes** | Depends on app logic; verify intended behavior |

---

### UM-E02: Edge Case - Very Large Image File (10+ MB)

| Field | Value |
|-------|-------|
| **ID** | UM-E02 |
| **Workflow** | User Media - Sources |
| **Scenario** | Upload very large image file and verify handling |
| **Role** | testadmin.media@uhco.local |
| **Preconditions** | 10MB+ image file available |
| **Steps** | 1. Click "Add Source" 2. Upload 10MB image 3. Wait for upload to complete 4. Observe timeout or success |
| **Expected Result** | Either: (a) upload succeeds but takes time (show progress), OR (b) rejected with "File too large" message. NO silent failures or app hang. |
| **Severity if Fail** | Medium (large file handling unpredictable) |
| **Notes** | May require tuning upload timeout or max file size |

---

### UM-E03: Edge Case - Non-Image File Uploaded (e.g., .txt, .pdf)

| Field | Value |
|-------|-------|
| **ID** | UM-E03 |
| **Workflow** | User Media - Sources |
| **Scenario** | Attempt to add non-image file as source |
| **Role** | testadmin.media@uhco.local |
| **Preconditions** | Non-image file available (e.g., document.txt) |
| **Steps** | 1. Click "Add Source" 2. Try to upload .txt or .pdf file 3. Observe validation |
| **Expected Result** | Upload rejected with "Invalid file type" message. NO non-image files added. |
| **Severity if Fail** | High (invalid files corrupt media workflow) |
| **Notes** | File type validation critical |

---

### UM-E04: Edge Case - Delete Source with Pending Variants

| Field | Value |
|-------|-------|
| **ID** | UM-E04 |
| **Workflow** | User Media - Sources |
| **Scenario** | Delete source that has assigned variants (not all generated/published) |
| **Role** | testadmin.media@uhco.local |
| **Preconditions** | Source with 1 variant assigned but not generated |
| **Steps** | 1. Delete the source 2. Observe variant status 3. Check if orphaned records remain |
| **Expected Result** | Source deleted; associated variants cascade deleted. NO orphaned variant records in DB. |
| **Severity if Fail** | High (orphaned records; data integrity) |
| **Notes** | Cascade delete rules critical |

---

## WORKFLOW 3: User Media Variants - Edge Cases

### UV-E01: Edge Case - Variant Dimension Boundary (1×1 px, 5000×5000 px)

| Field | Value |
|-------|-------|
| **ID** | UV-E01 |
| **Workflow** | User Media - Variants |
| **Scenario** | Generate variants with extreme dimensions (very small, very large) |
| **Role** | testadmin.media@uhco.local |
| **Preconditions** | Source images with 1px and 5000px variants defined |
| **Steps** | 1. Generate 1×1 variant 2. Generate 5000×5000 variant 3. Observe if both succeed or fail gracefully |
| **Expected Result** | Generation succeeds with usable output, OR fails gracefully with error message. NO crash. NO malformed files. |
| **Severity if Fail** | Medium (extreme dimensions may cause crashes) |
| **Notes** | Test resize logic robustness |

---

### UV-E02: Edge Case - Generate After Source Deactivated

| Field | Value |
|-------|-------|
| **ID** | UV-E02 |
| **Workflow** | User Media - Variants |
| **Scenario** | Source is deactivated; try to generate variant from stale source |
| **Role** | testadmin.media@uhco.local |
| **Preconditions** | Variant assigned and generated; source then deactivated |
| **Steps** | 1. Deactivate source 2. Try to re-generate variant 3. Observe if generation proceeds or blocked |
| **Expected Result** | Either: (a) generation blocked with "Source inactive", OR (b) generation succeeds but uses cached/archive version. Behavior documented. |
| **Severity if Fail** | Medium (unclear behavior; potential state confusion) |
| **Notes** | Test state machine consistency |

---

### UV-E03: Edge Case - Publish Generates Twice Concurrently

| Field | Value |
|-------|-------|
| **ID** | UV-E03 |
| **Workflow** | User Media - Variants |
| **Scenario** | Two users/admins try to publish same variant simultaneously |
| **Role** | testadmin.media@uhco.local (primary), testadmin.super@uhco.local (secondary if simulated) |
| **Preconditions** | Variant ready to publish; simulate concurrent requests |
| **Steps** | 1. Open [variants.cfm](admin/user-media/variants.cfm) in two browser tabs/windows 2. On both tabs, click "Publish" at same time (or within seconds) 3. Observe if both succeed or one is blocked/rolled back |
| **Expected Result** | Only one publish completes successfully; second request either blocked, queued, or fails gracefully with "Variant already published". NO duplicate publishes. NO race condition. |
| **Severity if Fail** | High (concurrent conflict; data corruption possible) |
| **Notes** | Database locking/optimistic concurrency important |

---

### UV-E04: Edge Case - Corrupted Generated Variant File

| Field | Value |
|-------|-------|
| **ID** | UV-E04 |
| **Workflow** | User Media - Variants |
| **Scenario** | Generation fails (e.g., disk full); verify error state |
| **Role** | testadmin.media@uhco.local |
| **Preconditions** | Simulate disk full or I/O error |
| **Steps** | 1. Trigger variant generation when disk space is low 2. Observe error handling 3. Check variant status in DB |
| **Expected Result** | Generation fails with error message; variant status marked "error" with reason; no corrupted/partial files left; user can retry |
| **Severity if Fail** | Medium (error recovery unclear) |
| **Notes** | Error state handling critical for UX |

---

## WORKFLOW 4: User Review Submission - Edge Cases

### UR-E01: Edge Case - Duplicate Submission (Submit, Then Submit Again Immediately)

| Field | Value |
|-------|-------|
| **ID** | UR-E01 |
| **Workflow** | User Review - Submission |
| **Scenario** | User submits review twice in quick succession |
| **Role** | testfaculty.current@uh.edu |
| **Preconditions** | User on UserReview form; has unsaved edits |
| **Steps** | 1. Edit pronouns to "They/Them" 2. Click "Submit" 3. Immediately (within 1 sec) click "Submit" again 4. Observe if duplicate submission created |
| **Expected Result** | Only one submission created. Second submit either blocked (button disabled) or overwrites first (only latest submission is pending). NO duplicates in queue. |
| **Severity if Fail** | High (admin review queue confusion; duplicate processing) |
| **Notes** | Client-side disable button + server-side idempotency both needed |

---

### UR-E02: Edge Case - Very Long Review Note (5000+ chars)

| Field | Value |
|-------|-------|
| **ID** | UR-E02 |
| **Workflow** | User Review - Submission |
| **Scenario** | Submit review with very long text in bio/contact sections |
| **Role** | testfaculty.current@uh.edu |
| **Preconditions** | User on UserReview form |
| **Steps** | 1. In Bio section, paste 5000+ character text 2. Submit review 3. Admin reviews and approve 4. Verify text persisted correctly |
| **Expected Result** | Long text saved without truncation or corruption; formatting preserved if rich text |
| **Severity if Fail** | Medium (data loss; text corruption) |
| **Notes** | Test database column max length |

---

### UR-E03: Edge Case - Submit While Flagged User Becomes Ineligible

| Field | Value |
|-------|-------|
| **ID** | UR-E03 |
| **Workflow** | User Review - Submission |
| **Scenario** | User eligible when viewing form; admin removes flag before submission; submission fails |
| **Role** | testfaculty.current@uh.edu |
| **Preconditions** | User has "current-student" flag; on review form |
| **Steps** | 1. Open UserReview form 2. Edit pronouns 3. (Concurrently, admin removes "current-student" flag) 4. User clicks "Submit" 5. Observe behavior |
| **Expected Result** | Submit fails with error "You are no longer eligible for review" OR submission queued but rejected on approval (status = "rejected" with reason "User no longer eligible"). Clear error message to user. |
| **Severity if Fail** | Medium (unclear behavior; ineligible submission accepted) |
| **Notes** | Eligibility check must occur at submission time AND approval time |

---

### UR-E04: Edge Case - Submit With All Fields Unchanged

| Field | Value |
|-------|-------|
| **ID** | UR-E04 |
| **Workflow** | User Review - Submission |
| **Scenario** | User views review form but makes NO changes; submits as-is |
| **Role** | testfaculty.current@uh.edu |
| **Preconditions** | User opens UserReview form; no edits made |
| **Steps** | 1. Open UserReview form 2. Don't edit anything 3. Click "Submit" immediately 4. Observe if submission created |
| **Expected Result** | Either: (a) submission accepted (empty/no-op submission recorded), OR (b) form prevents submit with "No changes made" message. Behavior documented. NO error. |
| **Severity if Fail** | Low (minor UX; doesn't break workflow) |
| **Notes** | Design choice whether to allow no-op submissions |

---

## WORKFLOW 5: User Review Approval - Edge Cases

### UA-E01: Edge Case - Approve After User Is Deleted

| Field | Value |
|-------|-------|
| **ID** | UA-E01 |
| **Workflow** | User Review - Approval |
| **Scenario** | User deleted from system; admin tries to approve their submission |
| **Role** | testadmin.reviewer@uhco.local |
| **Preconditions** | Submission pending; then user deleted from Users table |
| **Steps** | 1. Delete TestMedia_Ready user 2. Admin opens [review.cfm](admin/settings/user-review/review.cfm) for their pending submission 3. Try to approve 4. Observe behavior |
| **Expected Result** | Either: (a) approve fails with "User not found" error, OR (b) approval proceeds but target user lookup fails gracefully. NO database constraint violation. Clear error message. |
| **Severity if Fail** | Medium (orphaned submission; FK constraint) |
| **Notes** | Cascade delete rules important; submission should be deleted with user |

---

### UA-E02: Edge Case - Partial Approval, Then Re-Submit

| Field | Value |
|-------|-------|
| **ID** | UA-E02 |
| **Workflow** | User Review - Approval |
| **Scenario** | Partial approval applied; user re-submits to change rejected fields |
| **Role** | testfaculty.current@uh.edu |
| **Preconditions** | Previous submission partially approved (some fields accepted, some rejected) |
| **Steps** | 1. User logs back in 2. Views rejection reason on rejected fields 3. Edits rejected field (e.g., changes email to @uh.edu) 4. Re-submits 5. Admin reviews new submission |
| **Expected Result** | New submission created; old partial submission archived/replaced; new submission reviewable separately; no data collision |
| **Severity if Fail** | High (old/new submissions confusing; approval state tangled) |
| **Notes** | Test resubmission workflow |

---

### UA-E03: Edge Case - Approval Note with Special Characters & Unicode

| Field | Value |
|-------|-------|
| **ID** | UA-E03 |
| **Workflow** | User Review - Approval |
| **Scenario** | Admin enters rejection note with quotes, XML, emoji, and unicode |
| **Role** | testadmin.reviewer@uhco.local |
| **Preconditions** | Submission pending review |
| **Steps** | 1. On review.cfm, click "Reject All" 2. In note field, enter: `Please resubmit with "valid" email. Expected: name@uh.edu (not <fake>). 🙏 Спасибо.` 3. Submit rejection 4. User views note |
| **Expected Result** | Note saved without escaping errors; user sees readable text; no XSS; unicode/emoji rendered correctly |
| **Severity if Fail** | Medium (note corruption; display errors) |
| **Notes** | Security + internationalization test |

---

## WORKFLOW 6: Permission Boundaries - Edge Cases

### PB-E01: Edge Case - Permission Granted, Then Revoked Mid-Session

| Field | Value |
|-------|-------|
| **ID** | PB-E01 |
| **Workflow** | Permission Boundaries |
| **Scenario** | Admin has permission, uses it, then permission revoked, tries to use again |
| **Role** | testadmin.media@uhco.local (MediaAdmin) |
| **Preconditions** | MediaAdmin logged in; granted media.publish permission |
| **Steps** | 1. Publish a variant successfully 2. (Concurrently, dev/super admin revokes media.publish from MediaAdmin role) 3. MediaAdmin refreshes page and tries to publish another variant 4. Observe if access denied or cached |
| **Expected Result** | Access denied on second attempt; OR permission cache expires within reasonable time (< 1 min). NO silent success if permission revoked. |
| **Severity if Fail** | Critical (permission revocation not respected; access control broken) |
| **Notes** | Test permission refresh logic; cache TTL important |

---

### PB-E02: Edge Case - Multiple Roles Assigned to Same User

| Field | Value |
|-------|-------|
| **ID** | PB-E02 |
| **Workflow** | Permission Boundaries |
| **Scenario** | Assign multiple roles to same admin; verify union of permissions |
| **Role** | testadmin.super@uhco.local (for test setup) |
| **Preconditions** | Create test user with both USER_ADMIN and USER_MEDIA_ADMIN roles |
| **Steps** | 1. Grant both roles to new test admin 2. Admin logs in 3. Verify can edit users AND manage media 4. Verify can access both [admin/users/edit.cfm](admin/users/edit.cfm) and [admin/user-media/variants.cfm](admin/user-media/variants.cfm) |
| **Expected Result** | Permissions are UNION of both roles; user has both capabilities; no conflicts |
| **Severity if Fail** | High (role aggregation broken; access incorrect) |
| **Notes** | Test AND/OR logic in permission checks |

---

### PB-E03: Edge Case - Permission Lookup Fails (Bad Role Record)

| Field | Value |
|-------|-------|
| **ID** | PB-E03 |
| **Workflow** | Permission Boundaries |
| **Scenario** | Admin role corrupted/deleted; user permission lookup fails |
| **Role** | testadmin.user@uhco.local |
| **Preconditions** | Simulate database corruption: delete user's role record |
| **Steps** | 1. Corrupt/delete role assignment 2. Admin refreshes page and tries to access [admin/users/edit.cfm](admin/users/edit.cfm) 3. Observe error handling |
| **Expected Result** | Either: (a) graceful error "Permissions could not be loaded", OR (b) default to no permissions (deny access). NO 500 error. Logged for investigation. |
| **Severity if Fail** | Medium (error handling; app stability) |
| **Notes** | Test error recovery |

---

## Edge Case Test Execution Summary

| Workflow | Edge Case ID | Scenario | Total |
|----------|--------------|----------|-------|
| User Editing | UE-E01 to UE-E05 | 5 edge cases | 5 |
| User Media - Sources | UM-E01 to UM-E04 | 4 edge cases | 4 |
| User Media - Variants | UV-E01 to UV-E04 | 4 edge cases | 4 |
| User Review - Submit | UR-E01 to UR-E04 | 4 edge cases | 4 |
| User Review - Approve | UA-E01 to UA-E03 | 3 edge cases | 3 |
| Permission Boundaries | PB-E01 to PB-E03 | 3 edge cases | 3 |
| **TOTAL PHASE 2 EDGE CASES** | | | **23** |

---

## Execution Notes

- Execute Phase 2 ONLY after Phase 1 (30 scenarios) are complete and stable
- If Phase 1 Critical/High defects are open, defer Phase 2 until resolution
- Edge cases may require manual setup (e.g., simulating concurrent requests, disk full, permission revocation)
- Test environment may need to be reset between edge cases to avoid state contamination
- Estimated time: 3-4 hours for all 23 edge cases
- Document workarounds if edge cases reveal design decisions (e.g., "app allows no-op submissions by design")

---

## Sign-Off & Approval

Before executing Phase 2:

- [ ] Phase 1 testing completed; no open Critical defects
- [ ] High defects triaged and deferred or fixed
- [ ] Test lead approves readiness for edge case testing
- [ ] Additional test environment setup (concurrent test, disk monitoring, etc.) ready

**Test Lead:** ___________________  **Date:** ___________

**Phase 1 Completion Date:** ___________________
