## Plan: Non-Developer Functional UAT Matrix

Build a practical UAT framework for non-developer testers that prioritizes functional correctness of core workflows (user edits, user media, user review submit/approve) before UI/UX polish. The approach uses role-based scenarios, clear pass/fail checks, and phased execution so feedback is actionable and easy to triage.

**Steps**
1. Define test charter, audience, and pass/fail rubric.
Depends on: none.
Deliverables: test objectives, severity scale (Critical, High, Medium, Low), and what counts as functional failure vs. UX observation.

2. Prepare test prerequisites and environment guardrails.
Depends on: step 1.
Includes: test accounts by role, seeded test users/data, image files, reset/retest process, and issue logging template.

3. Build the core functional test matrix by workflow (functionality-first phase).
Depends on: step 2.
Includes workflows:
- User Editing (search, open, edit, save, verify persistence)
- User Media Source Management (add source, load files, deactivate/delete)
- User Media Variants/Publishing (assign variant, generate, publish, verify output/state)
- User Review Submission (eligible user edits and submits)
- User Review Approval (admin approve/reject all and partial)
- Permission Boundaries (allowed/blocked actions by role)
For each matrix row: role, preconditions, steps, expected result, severity if failed, notes field.

4. Define high-risk edge-case matrix (still functionality-focused).
Depends on: step 3.
Includes: duplicate submissions, stale state after source changes, partial approvals, rejected note visibility, boundary values, permission changes mid-session.

5. Create the non-developer step-by-step execution guide.
Depends on: step 3 and step 4.
Format: plain-language instructions with screen-by-screen checkpoints and exact expected outcomes.
Sections:
- Before You Start
- Daily Test Flow
- Scenario Scripts (A through F)
- How to Log Defects
- Retest Instructions

6. Run phased test cycles with explicit priority.
Depends on: step 5.
Phase 1 (Functional Happy Paths): complete all core scenarios.
Phase 2 (Functional Edge Cases): run high-risk matrix.
Phase 3 (UI/UX Secondary): only after phases 1-2 are stable.

7. Consolidate findings into decision-ready feedback summaries.
Depends on: step 6.
Output: defects grouped by workflow and severity, plus top 5 blocking issues and top 5 UX improvements.

**Relevant files**
- c:/inetpub/wwwroot/uhco_ident/admin/users/index.cfm — user search/list entry point for edit flows.
- c:/inetpub/wwwroot/uhco_ident/admin/users/edit.cfm — primary user editing form behaviors under test.
- c:/inetpub/wwwroot/uhco_ident/admin/user-media/index.cfm — user media entry point and search.
- c:/inetpub/wwwroot/uhco_ident/admin/user-media/sources.cfm — adding/loading user image sources.
- c:/inetpub/wwwroot/uhco_ident/admin/user-media/variants.cfm — assigning/generating/publishing variants.
- c:/inetpub/wwwroot/uhco_ident/userreview/index.cfm — end-user submission workflow.
- c:/inetpub/wwwroot/uhco_ident/admin/settings/user-review/index.cfm — admin review queue and configuration context.
- c:/inetpub/wwwroot/uhco_ident/admin/settings/user-review/review.cfm — field-level review and resolution decisions.
- c:/inetpub/wwwroot/uhco_ident/dev/ADMIN_PERMISSIONS_PLAN.md — permission matrix source for role-based testing.

**Verification**
1. Validate test matrix completeness: every core workflow has at least one happy-path and one failure-path test.
2. Dry-run scenario scripts with one non-developer pilot tester and refine ambiguous wording.
3. Confirm reproducibility by having a second tester rerun 3 random scenarios and match outcomes.
4. Verify defect reports include: scenario ID, role, exact step, observed vs expected, screenshot, and severity.
5. Ensure functional findings are reviewed first; UI/UX findings are reviewed only after blockers are triaged.

**Decisions**
- Included scope: manual UAT for non-developers centered on user editing, media workflow, and user review submit/approve.
- Excluded scope: code-level unit/integration tests, API contract tests, performance benchmarking, and infrastructure/deployment testing.
- Priority rule: functionality first, UI/UX second.

**Further Considerations**
1. Recommendation: choose one primary source type for UAT (local image files or Dropbox) for cycle 1 to reduce test variance; add the second source type in cycle 2.
2. Recommendation: freeze app-config/media-config changes during each UAT cycle to avoid changing expected behavior mid-run.
3. Recommendation: appoint one triage owner to classify defects daily and prevent backlog ambiguity.