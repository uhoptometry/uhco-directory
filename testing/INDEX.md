# UHCO Identity System - Non-Developer UAT Testing Plan

## Overview & Quick Start

This folder contains a complete testing framework for non-developer testers. The goal is to validate **functional correctness** of core user-facing workflows (user editing, media management, user review submit/approve) before investing in UI/UX refinement.

**Total Test Coverage:** 30 happy-path scenarios + 23 edge-case scenarios = 53 core workflows tested

**Estimated Timeline:** 5-7 days (2-3 hours testing per day + daily triage)

---

## Documents in This Plan

### 1. **testingMatrix1.md** — THE MAIN PLAN (Read First)
- High-level overview of all 7 steps
- Scope and phase structure
- Decisions and constraints

**When:** Read this first to understand the overall approach

---

### 2. **step1-test-charter.md** — Test Objectives & Severity Scale
- What we're testing and why
- Definition of Critical / High / Medium / Low severity
- Pass/Fail criteria
- Functional vs. UX distinction

**When:** Review before Day 1 testing. Ensure all testers understand severity scale.

---

### 3. **step2-prerequisites.md** — Environment & Test Data Setup
- Test accounts by role (SuperAdmin, MediaAdmin, UserAdmin, ReviewerAdmin, Viewer)
- Test end-users to create (TestFaculty_Current, TestMedia_Ready, etc.)
- Organizations and flags to seed
- Test images needed
- Database reset script
- Environment health checks

**When:** This is a **setup checklist**, not a testing document. Complete this BEFORE Day 1 testing.

---

### 4. **step3-functional-test-matrix.md** — Happy-Path Test Scenarios
- **30 core test cases** across 6 workflows
- Each scenario includes:
  - ID (e.g., UE-001)
  - Role/account needed
  - Preconditions
  - Step-by-step actions
  - Expected result
  - Severity if fails

**When:** Use this as the **primary test execution checklist** for Phase 1 (Days 1-2).

**Workflows Covered:**
1. User Editing (8 scenarios)
2. User Media - Sources (4 scenarios)
3. User Media - Variants (5 scenarios)
4. User Review - Submission (4 scenarios)
5. User Review - Approval (4 scenarios)
6. Permission Boundaries (5 scenarios)

---

### 5. **step4-edge-case-matrix.md** — Phase 2 Edge Cases
- **23 edge-case test scenarios** testing boundary conditions, duplicates, permission revocation, etc.
- Same structure as Step 3 but with more complex/risky scenarios

**When:** Use for Phase 2 testing (Day 4) ONLY after Phase 1 is stable and no Critical defects remain.

**When to Execute Phase 2:**
- ✅ All Phase 1 scenarios completed
- ✅ No open Critical defects
- ✅ High defects triaged/deferred or fixed

---

### 6. **step5-execution-guide.md** — Non-Developer Tester Instructions
- Plain-language "how-tos" for common actions
- Daily test flow and checklist
- How to log defects
- Retest instructions
- Daily standup summary template
- FAQ for non-technical testers

**When:** Read this on Day 1. Refer to daily during testing. Use tracking templates.

---

## Execution Roadmap

### **PRE-TESTING (1-2 days before Day 1)**

1. **Setup Phase (Test Lead + 1 Dev):**
   - [ ] Create test accounts (step2-prerequisites.md: Test Accounts section)
   - [ ] Seed test users (step2-prerequisites.md: Test End-User Accounts section)
   - [ ] Create organizations/flags (step2-prerequisites.md: Test Data section)
   - [ ] Prepare test images (step2-prerequisites.md: Test Image Assets section)
   - [ ] Run DB reset script to ensure clean state
   - [ ] Verify environment health (step2-prerequisites.md: Health Checks section)
   - [ ] Walk through with testers on Day 0

2. **Tester Preparation:**
   - [ ] All testers read step1-test-charter.md
   - [ ] All testers read step5-execution-guide.md
   - [ ] All testers have test account credentials
   - [ ] All testers can log in successfully
   - [ ] All testers have access to this testing folder

---

### **PHASE 1: HAPPY PATHS (Days 1-2) — ~30 scenarios**

**Goal:** Validate core workflows complete successfully

**Daily Cadence:**
- Start: 9 AM
- Execute: Run 15-20 scenarios per day (3-5 hours)
- End: 5 PM
- Triage: End-of-day summary, escalate Critical defects

**Scenarios to Execute (in order):**
- Day 1 AM: UE-001 to UE-004 (User Editing basics)
- Day 1 PM: UE-005 to UE-008 (User Editing advanced) + UM-001 to UM-002 (Media Sources)
- Day 2 AM: UM-003 to UM-004 + UV-001 to UV-003 (Media Variants/Publishing)
- Day 2 PM: UV-004 to UV-005 + UR-001 to UR-004 (User Review Submission)
- **If time:** UA-001 to UA-004 (User Review Approval) + PB-001 to PB-005 (Permission Boundaries)

**Exit Criteria for Phase 1:**
- ✅ All 30 happy-path scenarios executed
- ✅ No open Critical defects (or all in triage for immediate fix)
- ✅ High defects logged and prioritized
- ✅ Daily summaries filed

---

### **TRIAGE & FIX (Day 3) — As needed**

**By Test Lead + Dev:**
- Review Critical defects
- Assign priorities
- Deploy fixes to test environment
- Prepare retests

**By Testers:**
- Retest any fixed scenarios
- Verify fixes resolve original issue

---

### **PHASE 2: EDGE CASES (Day 4) — ~23 scenarios**

**Prerequisite:** Phase 1 complete + no blocking Critical defects

**Goal:** Test boundary conditions, duplicates, state transitions, permission changes

**Scenarios to Execute (in order):**
- UE-E01 to UE-E05 (User Editing edge cases)
- UM-E01 to UM-E04 (Media Source edge cases)
- UV-E01 to UV-E04 (Variant edge cases)
- UR-E01 to UR-E04 (Review Submission edge cases)
- UA-E01 to UA-E03 (Review Approval edge cases)
- PB-E01 to PB-E03 (Permission edge cases)

**Exit Criteria for Phase 2:**
- ✅ All 23 edge-case scenarios executed
- ✅ Edge-case defects logged with expected-vs-actual noted
- ✅ No additional Critical defects blocking core flows

---

### **PHASE 3: UI/UX OBSERVATIONS (Day 5, if time)**

**Prerequisite:** Phases 1-2 complete + functional stability confirmed

**Goal:** Collect UI/UX feedback (NOT blocking; separate from functional defects)

**Observations to Make:**
- Button clarity and placement
- Form field labels and instructions
- Loading feedback/spinners
- Error message helpfulness
- Responsive/layout on different screen sizes
- Accessibility basics (tab order, focus states)

**Output:** Consolidated "UI/UX Feedback" document (not part of Phase 1-2 defect list)

---

## Defect Triage & Severity Handling

### Critical (Testing Blocked)
- Definition: Feature completely broken, data lost, user cannot proceed
- Action: **STOP testing that workflow. Report immediately.** Do NOT proceed to next scenario in that workflow until fix deployed and retest confirms pass.
- Escalation: Test Lead → Dev (same hour)
- Impact: Can block Phase 1 completion if not resolved within 1-2 hours

### High (Workflow Completes, Wrong Result)
- Definition: Action completes but wrong data/state produced
- Action: **Log and continue to next scenario.** Do NOT pause testing.
- Escalation: End-of-day summary to Test Lead
- Retest: After fix deployed, retest same scenario
- Impact: Batched for end-of-day triage

### Medium (Workflow Completes, Minor Issue)
- Definition: Action succeeds; cosmetic or minor data issue
- Action: **Log and continue.** Do NOT pause.
- Escalation: Included in end-of-week summary
- Retest: After fix deployed, retest if impactful

### Low (UX Observation)
- Definition: Cosmetic/enhancement opportunity; no functional impact
- Action: **Log separately; do NOT include in Phase 1 defect list.** Continue testing.
- Escalation: Collected for Phase 3 UI/UX review
- Impact: No blocking; informational only

---

## Roles & Responsibilities

### Test Lead (Admin/QA)
- [ ] Prepare test environment (account creation, data seeding)
- [ ] Distribute testing documents to testers
- [ ] Monitor daily progress
- [ ] Triage Critical/High defects
- [ ] Escalate to dev as needed
- [ ] Approve Phase 1 completion before Phase 2 begins
- [ ] Manage retest scheduling
- [ ] Compile final summary report

### Non-Developer Testers (1-2 people)
- [ ] Execute test scenarios exactly as written
- [ ] Record actual vs. expected results
- [ ] Log defects clearly with screenshots
- [ ] Report blockers immediately
- [ ] Complete daily summaries
- [ ] Retest fixed scenarios as assigned

### Developer/Triage Owner
- [ ] On-call for environment setup (Day -1)
- [ ] Investigates Critical defects immediately
- [ ] Deploys fixes to test environment
- [ ] Validates retest environment ready
- [ ] Reviews test findings for root cause (post-Phase-1)

---

## Key Success Metrics

### By End of Phase 1:
- ✅ 30/30 happy-path scenarios executed (100% coverage)
- ✅ >= 95% scenarios PASS (< 5% failure rate for functional core)
- ✅ 0 open Critical defects (or all in active retest)
- ✅ All High defects identified and triaged

### By End of Phase 2:
- ✅ 23/23 edge-case scenarios executed
- ✅ Edge-case defects logged and categorized
- ✅ No regression in Phase 1 (retests still pass)

### By End of Phase 3 (Optional):
- ✅ UI/UX feedback collected separately
- ✅ Top 5 UX improvements identified
- ✅ No changes to functional test results

---

## Escalation & Support

### During Testing:

**"The app won't load"**
→ Report to Test Lead immediately. Stop testing. Do NOT continue.

**"I found a Critical defect"**
→ Screenshot, log it, then call/message Test Lead immediately (same hour).

**"I'm confused about a scenario step"**
→ Ask Test Lead before proceeding. Don't guess.

**"A test failed but I don't understand why"**
→ Log exactly what happened (actual vs. expected). Test Lead + Dev will investigate.

### Post-Phase-1:

**"Why did this test fail?"**
→ Dev will review root cause after Phase 1 complete + defects compiled.

**"Should I log this as High or Medium?"**
→ Compare to severity definitions in step1-test-charter.md. If uncertain, ask Test Lead.

---

## File Naming Convention

Test artifacts created during execution should follow this naming:

- **Defect screenshots:** `defect-[SCENARIO_ID]-[BRIEF_TITLE].png`
  - Example: `defect-UE-002-name-not-saved.png`
  
- **Daily summaries:** `daily-summary-[DATE]-[TESTER_NAME].txt`
  - Example: `daily-summary-2026-04-21-jane-tester.txt`

- **Retest results:** `retest-[SCENARIO_ID]-[OUTCOME].txt`
  - Example: `retest-UE-002-PASS-verified.txt`

All files stored in: `c:\inetpub\wwwroot\uhco_ident\dev\testing\`

---

## Final Checklist Before Day 1

### Test Lead:
- [ ] All test accounts created
- [ ] All test users seeded with correct flags/orgs
- [ ] Test images in [_temp_source/test_images/](../../_temp_source/test_images/) folder
- [ ] Database clean (reset script run)
- [ ] Environment health checks passed
- [ ] Testers trained on step1 & step5
- [ ] Testers have credentials and can log in

### Testers:
- [ ] Can log in to test account
- [ ] Have read step1-test-charter.md
- [ ] Have read step5-execution-guide.md
- [ ] Have step3-functional-test-matrix.md on hand
- [ ] Know who to contact if blocked
- [ ] Have daily summary template ready

### Dev/Infrastructure:
- [ ] ColdFusion datasource `UHCO_Directory` working
- [ ] No errors in ColdFusion logs
- [ ] File write permissions working ([_temp_source/](../../_temp_source/), [_published_images/](../../_published_images/))
- [ ] Dropbox integration tested (if applicable)

---

## Questions?

Refer to:
1. **For "Why are we testing this?"** → step1-test-charter.md
2. **For "How do I set up the environment?"** → step2-prerequisites.md
3. **For "What are the test scenarios?"** → step3-functional-test-matrix.md or step4-edge-case-matrix.md
4. **For "How do I run a test?"** → step5-execution-guide.md
5. **For quick reference** → This document (index.md)

---

**Ready to start? Begin with step2-prerequisites.md to prepare the environment. Then move to step5-execution-guide.md for Day 1 instructions.**

Good luck! 🚀
