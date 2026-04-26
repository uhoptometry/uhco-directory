# Step 1: Test Charter, Audience & Pass/Fail Rubric

## Test Charter & Objectives

**Primary Objective:**  
Validate functional correctness of core user-facing workflows before investing in UI/UX refinement. Feedback should focus on whether features work as intended, not how they look or feel.

**Scope In:**
- User profile editing (search, open, save, persistence)
- User media source management (add, load, delete)
- User media variants and publishing (assign, generate, publish, state transitions)
- User review submission (eligible user edits and submits)
- User review approval (admin approve/reject all and partial approval)
- Permission boundaries (role-based access, allowed/blocked actions)

**Scope OUT:**
- Code-level unit/integration tests
- API contract testing
- Performance benchmarking (load testing, stress testing)
- Infrastructure/deployment testing
- Accessibility compliance testing (WCAG) — noted for future phase
- Cross-browser compatibility (Phase 3 only, after functional blockers resolved)

**Success Criteria:**
- All Phase 1 happy-path scenarios pass without blocking defects
- All P1/Critical and High functional defects identified and prioritized
- UI/UX observations logged separately and reviewed only after Phase 1-2 closure
- At least 95% of core workflows complete successfully in happy path
- No data loss or persistence failures

---

## Testing Audience & Roles

### Test Participants

**Non-Developer Testers** (primary audience for this UAT)
- Background: Administrative staff, content managers, workflow coordinators
- Technical skill: Can use web forms, click buttons, upload files, recognize error messages
- NOT required: Understanding of databases, code, APIs, or technical debugging
- Responsibility: Execute scenario scripts, log observations, report what they see vs. expect

**Test Administrators** (internal team)
- Background: Can have some technical knowledge or QA background
- Responsibility: Triage defects, assign severity, track retests, manage test environment

**Developer Observer** (optional)
- Role: On standby for immediate environmental/setup issues only; NOT for fixing bugs during UAT cycle
- Responsibility: Ensure test database/app state is consistent, clear logs if queries fail

---

## Severity Scale & Definitions

### Critical (Blocks all further testing in that workflow)
**Definition:** Feature is completely broken, data is lost/corrupted, or user cannot proceed to next required step.

**Examples:**
- User cannot save changes (POST fails, nothing persists)
- Submit button on user review fails silently; no submission created
- Admin approval fails; submission stays pending despite clicking Approve
- Role-based access control fails; unauthorized user can access restricted page
- File upload fails; source is created but file list empty despite files in folder

**Impact:** Workflow is unusable; testing must pause for fix.

**Action:** Stop execution in that workflow, escalate to dev, retest after fix.

---

### High (Workflow completes but with incorrect/unexpected behavior)
**Definition:** Core action completes but produces wrong result, wrong state, or omits critical data.

**Examples:**
- User edits name, saves, but wrong field updated (e.g., first name saved to last name)
- Variant published but to wrong folder or with wrong filename
- User review approved, but only some fields applied (rest ignored)
- Permission denied to allowed user (caching issue or stale session)
- Duplicate check fails; same source added twice

**Impact:** Workflow appears to work but delivers wrong outcome; data integrity at risk.

**Action:** Log as High; dev prioritizes; retest after fix.

---

### Medium (Workflow completes; minor data or UX issue)
**Definition:** Workflow succeeds but with cosmetic issue, incorrect message, or minor data inconsistency that doesn't prevent other workflows.

**Examples:**
- Success message says "saved" but also shows a stale value before refresh
- Tab saves correctly but does not show visual feedback (no toast/alert)
- Error message is confusing ("Error: null" instead of "Email already in use")
- Variant status shows "error" but error reason is blank
- Field label is unclear (e.g., "Ext." instead of "Externship")

**Impact:** User can work around it; data is correct; no blocking defects.

**Action:** Log as Medium; note pattern; prioritize fixes after Critical/High.

---

### Low (Observation; nice-to-have improvement)
**Definition:** Cosmetic/UX observation; no functional impact. No blocking, no data loss, no confusion.

**Examples:**
- Button text could be clearer ("Approve & Publish" instead of "Publish")
- Loading spinner could be more obvious
- Modal layout could be better centered
- Form could benefit from field hints/placeholders
- Color contrast is barely readable but readable

**Impact:** Enhancement opportunity; collected for Phase 3 (UI/UX) consideration.

**Action:** Log as Low; save for UI/UX review; do NOT block functional testing.

---

## Functional vs. UX Distinction

### FUNCTIONAL (what we test NOW, Phase 1-2)
Focus: **Does it work correctly?**

- ✅ Data persists after save and refresh
- ✅ User can complete required actions step-by-step
- ✅ Correct user sees allowed pages; blocked user gets 403
- ✅ Variants generate and publish to expected location
- ✅ Approval decisions take effect and user sees result
- ✅ Duplicate submissions prevented
- ✅ No data corruption or loss on edge cases

**Test fails if:** Wrong data, missing data, user blocked incorrectly, action silently fails, state incorrect

---

### UX (what we test LATER, Phase 3)
Focus: **Is it easy/pleasant to use?**

- ⏸️ Loading feedback is visible
- ⏸️ Button labels are clear
- ⏸️ Layout is responsive and readable
- ⏸️ Error messages are helpful
- ⏸️ Navigation is intuitive
- ⏸️ Forms are easy to complete

**Test deferred until:** Core workflows reliably work in Phase 1-2

**Rationale:** Fixing UX before functionality is stable wastes effort; refinement compounds if underlying behavior changes.

---

## Pass/Fail Criteria per Test

### What Constitutes PASS
- ✅ All steps complete without error
- ✅ Expected result matches observed result exactly
- ✅ Data persists (verify after refresh or page navigation)
- ✅ User is able to proceed to next step or close scenario
- ✅ No unexpected redirects or error pages
- ✅ No data loss or corruption

### What Constitutes FAIL
- ❌ Any required step cannot be completed (button inactive, field locked, etc.)
- ❌ Action completes but observable result differs from expectation
- ❌ Data missing, wrong, or corrupted after action
- ❌ Silent failure (action appears to complete but has no effect)
- ❌ Unexpected error page, 500, or permission denied
- ❌ User cannot verify that action succeeded

### What Requires ESCALATION (vs. simple log)
If a test fails with **Critical** severity:
1. Screenshot the failure state
2. Note exact step and observable behavior
3. Flag for dev review before continuing other tests in that workflow
4. Wait for fix/retest instruction
5. Do NOT continue with other High/Medium scenarios in that workflow until resolved

If a test fails with **High** severity:
1. Log fully (step, observed, expected, screenshot)
2. Continue with next scenario
3. Mark workflow as "High-priority defect pending" in daily summary
4. Batch for dev review end-of-day

If a test fails with **Medium** severity:
1. Log with screenshot
2. Continue testing (do not block)
3. Include in end-of-week summary

If observation is **Low** (UX):
1. Make brief note
2. Continue testing
3. Save for Phase 3 review (do not include in Phase 1 defect list)

---

## Daily Test Workflow

### Before Starting Tests (Each Day)
- [ ] Environment is stable (app loads, no errors in logs)
- [ ] Test database is in known/clean state (or reset script run)
- [ ] Test accounts are active and accessible
- [ ] Any retests from previous day are planned and scheduled

### During Testing (Each Scenario)
- [ ] Read scenario from script
- [ ] Note preconditions (user role, test data needed)
- [ ] Execute steps exactly as written
- [ ] Record observed result at each checkpoint
- [ ] Compare observed vs. expected
- [ ] Assign severity if defect found
- [ ] Move to next scenario

### After Testing (Each Day)
- [ ] Count pass/fail by severity
- [ ] Escalate Critical defects to dev immediately
- [ ] Consolidate High defects into summary for daily standup
- [ ] Save Medium/Low observations for end-of-phase review
- [ ] Update test tracking sheet with results

---

## Defect Logging Template

Each defect must include:

```
**Scenario ID:** [e.g., UE-001 or UR-02]
**Severity:** [Critical / High / Medium / Low]
**Workflow:** [User Editing / Media Sources / Variants / Review Submission / Review Approval / Permissions]

**Preconditions:**
- User role: [e.g., AdminUser]
- Test data: [e.g., TestUser_Faculty, source="local folder"]

**Steps to Reproduce:**
1. [exact step 1]
2. [exact step 2]
3. [exact step 3]

**Expected Result:**
[what should happen]

**Observed Result:**
[what actually happened]

**Screenshot/Additional Info:**
[URL, error message, state of form, etc.]

**Triaged By:** [initials]
**Status:** [New / In Progress / Resolved / Verified / Deferred]
```

---

## Sign-Off & Approval

This charter defines the boundaries of Phase 1-2 UAT testing. All participants acknowledge:

1. **Functional correctness** is the primary focus; UI/UX is secondary
2. **Non-developers** can execute scripts without technical debug skills
3. **Critical/High defects** block subsequent workflows; Medium/Low do not
4. **UX observations** are logged separately and reviewed only after functional stability
5. **Daily triage** is required to maintain momentum and prevent backlog confusion

**Test Lead:** ___________________  **Date:** ___________

**Developer Lead:** ___________________  **Date:** ___________
