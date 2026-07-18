# Next Steps — Implementation Roadmap

_Roadmap baseline: 2026-07-17, immediately after Phase 1 (project foundation
scaffold). Updated 2026-07-17 at the Slice 0 checkpoint: Slice 0 is complete
(PR #2 merged, CI green, repository public — all verified by GitHub
metadata); Slice 1 is expanded below into a detailed execution plan.
Updated 2026-07-18: Slice 1's database schema is complete (migrations
0001–0005 implemented, individually reviewed/verified, and clean-room
verified — see the Slice 1 section below). Authentication, RLS, and all
later-slice work remain unimplemented._

This roadmap breaks the approved architecture into concrete, git-branch-sized
slices. It follows the phase order in `LifeOS-Technical-Handoff.md`
"Implementation Phases" and `LifeOS-Implementation-Blueprint.md` §5 exactly —
the **Foundation slice** is broken into six smaller sequential slices
(0 is infrastructure, 1–6 are sub-parts of the single approved "foundation
slice") because that's how it will actually be branched and reviewed; nothing
here reorders or reinterprets the approved phase sequence. Every later phase
(Quick Capture → ... → final pass) maps to exactly one slice, matching the
approved order one-for-one.

Re-slice this document whenever a slice's actual scope diverges materially
from what's written here (see `DEVELOPMENT_RULES.md` "Documentation
Expectations").

---

## Slice 0 — Infrastructure Provisioning — ✅ COMPLETE

- **Objective:** Provision a real Supabase project (dev environment) and a
  real Vercel project; wire environment variables; add a CI workflow that
  runs `lint`, `typecheck`, `test`, and `build` on every push/PR; enable
  branch protection on `main` (required checks, no direct pushes).
- **Estimated complexity:** Low–Medium (configuration, no application code).
- **Dependencies:** None.
- **Files changed:** `.github/workflows/ci.yml` (added, PR #2, merged).
- **Testing performed:** CI verified green on PR #2 (pull_request trigger)
  and on `main` after merge (push trigger) — both confirmed via GitHub
  metadata.
- **Definition of Done — status:**
  - [x] CI green on a real PR — verified by GitHub metadata.
  - [x] Supabase project provisioned — user-reported.
  - [x] Vercel project provisioned, connected, deploying successfully —
        verified by GitHub metadata (commit-status API).
  - [x] Repository made public — verified by GitHub metadata.
  - [~] Branch protection — **partially done**: a protection rule exists on
    `main` (verified by GitHub metadata), but the CI check is not yet
    attached as a _required_ status check (`contexts: []`, verified by
    GitHub metadata), and the rest of the rule's configuration isn't
    readable by this session's token (403 — needs direct confirmation
    in GitHub Settings). Marked complete per instruction, with this
    residual item tracked in `PROJECT_STATUS.md` Open Issues #1–#2.
  - [x] `PROJECT_STATUS.md` updated to reflect real infrastructure.
- **Suggested branch:** `chore/infra-provisioning` — merged via PR #2, then
  deleted (confirmed via GitHub metadata).

---

## Slice 1 — Foundation: Identity & Workspace Migrations

**Branch:** implemented directly on `claude/lifeos-docs-upload-s5nyrn` (not
yet merged to `main`)
**Status:** **Database schema complete.** All 17 ACR-001 decisions were
approved, then migrations `0001_profiles` → `0005_invitations` were
implemented one at a time, each individually reviewed and manually
verified, then the complete five-migration chain passed a separate
clean-room verification on PostgreSQL 16: fresh apply `0001 → 0005`
succeeded; all 26 combined behavioral checks passed (identity/`auth.users`
linkage, workspace membership rules, two-active-member enforcement,
`user_settings` cascade behavior, invitation constraints and lifecycle
uniqueness, `updated_at` trigger behavior on every trigger-backed table,
and the full foreign-key delete-behavior matrix); full rollback
`0005 → 0001` succeeded, leaving zero Slice 1 tables, functions, triggers,
or indexes in `public`; reapplying `0001 → 0005` reproduced a schema
identical to the first fresh apply; no discrepancies were found.

**This is schema completion only.** Authentication, RLS, service-layer
logic, invitation delivery and acceptance, automatic invitation
expiration, and every other later-slice item below (Slice 2 onward)
remain entirely unimplemented.

**Schema source-of-truth update:** the original `Database-Schema-Design.md`
and its audit amendment are confirmed permanently unavailable (see
`PROJECT_STATUS.md`). Rather than let the plan below's inferred specifics
silently become real schema, they were formally reconstructed as an
Architecture Change Request and reviewed with the project owner
decision-by-decision — all 17 field-level decisions are now approved:

**→ [`project/architecture/ACR-001-Slice-1-Identity-and-Workspace-Schema.md`](./architecture/ACR-001-Slice-1-Identity-and-Workspace-Schema.md)**

**Historical note — approval gate satisfied:** reviewing and approving
ACR-001's 17 individual decisions was, by itself, not authorization to
begin implementation. ACR-001 was separately approved as a finalized whole
and implementation was explicitly authorized before any migration was
written — the two-step gate described in earlier revisions of this
document, and in ACR-001 §11, is recorded here as satisfied, not removed
from history. The execution-plan outline below (kept for the process
structure — objective, testing strategy, verification checklist, DoD,
files) was superseded on schema specifics by ACR-001 wherever the two
differed; ACR-001 governed field-level detail. **One specific, deliberate
deviation from this outline** is recorded in "Row-Level Security (RLS)
Strategy" below.

### Objective

Stand up the schema-only foundation for identity and workspace ownership —
`profiles`, `workspaces`, `workspace_members`, `user_settings`,
`invitations` — exactly matching migration stage 1
(`LifeOS-Technical-Handoff.md` "Migration Order": _"Identity/ownership
(profiles, workspaces, workspace_members, user_settings, invitations —
F2)"_) and the workspace-anchoring model (D18), with Space ownership and
visibility deliberately **not** included here (that's Slice 4, migration
stage 2). No application code, no auth flow, no RLS _policies_ with real
logic yet beyond enabling RLS itself — this slice is pure schema.

### Migration Order

Five migrations, applied in this sequence (each a separate numbered file
with a paired down-migration, per the approved Git Workflow — no manual
database changes, no combined mega-migration):

1. `0001_profiles`
2. `0002_workspaces`
3. `0003_workspace_members`
4. `0004_user_settings`
5. `0005_invitations`

This ordering is _within_ migration stage 1 only — it doesn't renumber the
13-stage order in `LifeOS-Technical-Handoff.md`; stage 1 simply now has 5
internal steps instead of 1. (Alternative considered: one combined
migration for the whole stage, matching the Handoff's stage-level
granularity exactly. Recommendation is 5 small files instead, for smaller
reversible units and cleaner code review — this is an implementation
choice, not an architectural one; flagged in Assumptions below for
confirmation.)

### Table Creation Order (= Foreign Key Dependency Order)

```
profiles            (references auth.users — Supabase-managed, already exists)
  └── workspaces          (no FK to profiles in the minimal model — see Assumption 1)
        └── workspace_members   (FK → workspaces, FK → profiles)
  └── user_settings        (FK → profiles)
  └── invitations          (FK → workspaces, FK → profiles [created_by])
```

Creation must proceed top-to-bottom in this order because `workspace_members`
and `invitations` both depend on rows existing in `workspaces` and
`profiles` first. `user_settings` depends only on `profiles`.

### Foreign Key Dependencies

| Table               | Foreign keys                                                                        | On delete                                                                                                                          |
| ------------------- | ----------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| `profiles`          | `id` → `auth.users.id` (shared PK, not a separate UUID — standard Supabase pattern) | cascade (Supabase manages `auth.users` deletion; out of scope to override here)                                                    |
| `workspaces`        | none in the minimal model (see Assumption 1)                                        | —                                                                                                                                  |
| `workspace_members` | `workspace_id` → `workspaces.id`; `user_id` → `profiles.id`                         | restrict (membership rows are removed by the protected member-removal service, Slice 16 — never cascaded silently)                 |
| `user_settings`     | `user_id` → `profiles.id`                                                           | cascade (settings are meaningless without the profile)                                                                             |
| `invitations`       | `workspace_id` → `workspaces.id`; `created_by` → `profiles.id`                      | restrict on `workspace_id`; `created_by` should tolerate the inviter's profile existing (it always will in v1's two-account model) |

### Indexes

- `workspace_members(workspace_id)` — every RLS policy from Slice 2 onward
  joins through this table to check membership; this is the hottest lookup
  path in the entire schema.
- `workspace_members(user_id)` — a user's own membership lookup ("what
  workspace do I belong to").
- `invitations(workspace_id)` — Owner's Settings view of their own
  invitation(s).
- `invitations(token)` — unique index, for the acceptance flow's token
  lookup (Slice 16); token stored hashed, looked up by exact match only
  (never scanned).
- Primary key indexes are automatic on all five tables.

### Constraints

- `workspace_members`: `CHECK (role IN ('owner', 'member'))`; `UNIQUE (workspace_id, user_id)`; a **partial unique index** `UNIQUE (workspace_id) WHERE role = 'owner'` to guarantee exactly one owner row per workspace at the database level, as defense-in-depth alongside the service-layer check (see RLS Strategy).
- `invitations`: `CHECK (status IN ('pending', 'accepted', 'revoked', 'expired'))`; a **partial unique index** `UNIQUE (workspace_id) WHERE status = 'pending'` to enforce "at most one invitation at a time" (amendment Part 4.2) at the database level too.
- `user_settings`: `UNIQUE (user_id)` (or `user_id` as the primary key directly — equivalent, pick one at implementation time).
- All tables: `created_at timestamptz NOT NULL DEFAULT now()`; `updated_at timestamptz NOT NULL DEFAULT now()`.
- The **two-member-per-workspace cap** cannot be expressed as a simple `CHECK` (it requires counting sibling rows) — see Triggers below.

### Triggers

- `updated_at` auto-touch trigger on all five tables (standard pattern, implementation detail, not architectural).
- A trigger (or equivalent) enforcing the **two-member-per-workspace cap** as a database-level backstop. Per D17's own stated philosophy — the database/RLS layer is the _baseline_, never the _sole_ integrity control — primary enforcement of the two-member cap belongs in the protected invitation-acceptance service (Slice 16), with this trigger as defense-in-depth, not the other way around. This mirrors existing precedent rather than inventing new architecture.

### Row-Level Security (RLS) Strategy

**Superseded by explicit instruction during implementation — RLS was
deferred in full, not partially enabled.** This section's original plan
below was not what was built: per explicit, repeated instruction during
Migrations 0001–0005's implementation, **no `ENABLE ROW LEVEL SECURITY`
statement and no `CREATE POLICY` statement exists anywhere in the five
committed migrations.** RLS remains entirely future work, to be
implemented and reviewed as its own slice — it is not partially in place.
The per-table policy intent below is preserved as a record of the original
plan and remains a reasonable starting point for that future slice, but
none of it has been built yet.

Per `LifeOS-Technical-Handoff.md` "Row-Level-Security Approach" and the
Foundation slice's original requirement that baseline RLS structures land
from day one, the original plan called for: **RLS enabled on all five
tables in this slice**, even though full membership-based policies can't
be meaningfully exercised until Slice 2 provides a way to actually create
a session.

- `profiles`: a user may `SELECT`/`UPDATE` only their own row (`auth.uid() = id`). No cross-user visibility yet — a public-safe subset for Shared-Space display (e.g., showing the other member's name) is a later slice's concern, not this one.
- `workspaces`: a user may `SELECT` only workspaces they belong to (via a `workspace_members` join). No client-side `INSERT` policy — workspace creation happens only through the Slice 2 protected sign-up service (server-side, using elevated privileges, not an ordinary authenticated client insert).
- `workspace_members`: a user may `SELECT` rows for workspaces they belong to (so a member can see that the other membership row exists — this is basic roster information, not "private content" under P6-B). No client-side `INSERT`/`UPDATE`/`DELETE` policy — all writes go through protected services (sign-up, invitation acceptance, member removal).
- `user_settings`: a user may `SELECT`/`UPDATE` only their own row (`auth.uid() = user_id`).
- `invitations`: `SELECT`/`INSERT`/`UPDATE` restricted to the Workspace Owner of the relevant workspace (Part 4.1, Owner-only). The invitee — who has no account and thus no membership row yet — cannot be reached via an RLS policy at all; acceptance must be a protected, token-validating service call (Slice 16), not a client-side read.

No polymorphic tables exist in this slice, so D17's "controlled server-side
write path" requirement applies here in its simplest form: direct client
writes to any of these five tables are not expected to be the normal path
for anything except `profiles`/`user_settings` self-updates.

### Rollback Strategy

- Each of the 5 migrations ships with a paired down-migration that drops
  exactly what its up-migration created (table, indexes, triggers,
  constraints) — no down-migration touches a table it didn't create.
- Down-migrations run in **reverse** dependency order:
  `invitations` → `user_settings` → `workspace_members` → `workspaces` →
  `profiles`.
- Rollback is tested against a scratch/dev database only, never production,
  per the approved Git Workflow ("backups before any production schema
  change"). A full up → down → up cycle must produce an identical schema
  each time (verified as part of the Verification Checklist below).

### Testing Strategy

Slice 1 is schema-only, so its testing looks different from a feature
slice's:

- **Migration apply/rollback verification**: apply all 5 up-migrations to
  a clean dev database, confirm the expected tables/columns/constraints/
  indexes/triggers exist, then run the down-migrations in reverse and
  confirm a clean drop, then re-apply and confirm an identical result.
- **No RLS _policy behavior_ tests yet.** Real cross-workspace/cross-visibility
  policy tests need an actual way to create two authenticated sessions —
  that doesn't exist until Slice 2 (sign-up/sign-in). Writing "policy
  tests" against empty tables with no service layer would be theater, not
  verification. This is a deliberate, explained deferral to Slice 2 — not
  a silently skipped Definition-of-Done item.
- **Known CI gap to flag, not silently work around:** the current CI
  workflow (`.github/workflows/ci.yml`) has no database service and cannot
  run live migrations. Before or during this slice, decide whether to (a)
  extend CI with a local Postgres/Supabase service container so migration
  apply/rollback is automated, or (b) apply migrations manually to the dev
  Supabase project and verify via the checklist below, deferring CI
  automation to a later slice. This decision should be made explicitly,
  not assumed — see Risks.

### Verification Checklist

- [x] All 5 up-migrations apply cleanly, in order, to a fresh dev database. — confirmed by clean-room verification (fresh apply and final reapply), PostgreSQL 16, this session.
- [x] All 5 down-migrations, run in reverse order, drop everything with no orphaned objects (indexes, triggers, constraints) left behind. — confirmed; zero Slice 1 tables/functions/triggers/indexes remained in `public`.
- [x] A full up → down → up cycle produces an identical schema (diffed, not eyeballed). — confirmed; the reapplied schema matched the first fresh apply, table by table.
- [ ] Every table has RLS enabled (even where policies are minimal). — **not done; deferred in full, see "Row-Level Security (RLS) Strategy" above.**
- [x] Every foreign key, index, and constraint listed above exists exactly as specified (or the deviation is explained in the PR). — confirmed against ACR-001, the authoritative source (supersedes this outline's own constraint list wherever they differ — see each migration's commit message for specifics).
- [x] `updated_at` triggers fire correctly on update for all 5 tables. — confirmed (real-change and no-op-update behavior both verified per table).
- [x] The two-member-per-workspace backstop (trigger or equivalent) rejects a third `workspace_members` row for the same `workspace_id` when manually tested. — confirmed, including a real two-session concurrency test (Migration 0003 verification).
- [x] The one-pending-invitation-per-workspace partial unique index rejects a second pending invitation when manually tested. — confirmed, including a full accepted/revoked/expired lifecycle re-test in clean-room verification.
- [x] No other environment (staging/production) was touched by this testing. — confirmed; all verification used local scratch PostgreSQL databases only.
- [ ] `npm run lint`, `npm run typecheck`, `npm run test`, `npm run build` all still pass (no application code changed, so this should be a no-op, but confirm). — **not re-run as part of this documentation pass.** No application code was touched by Migrations 0001–0005 (SQL files only), so this remains expected to be a no-op, but hasn't been explicitly re-confirmed.

### Definition of Done (adapted from `DEFINITION_OF_DONE.md` for a schema-only slice)

- [x] Implementation (migrations) matches this plan, or deviations are explained in the PR. — matches ACR-001 (the authoritative source); the RLS deviation is explained above, not silent.
- [x] Unit tests: N/A in the traditional sense (no services yet) — the Verification Checklist above stands in for this item; noted explicitly rather than left silently blank.
- [x] Policy tests: explicitly deferred to Slice 2, with the reason stated (no session-creation path exists yet) — not skipped without explanation.
- [x] Playwright / accessibility: N/A — no UI in this slice.
- [ ] TypeScript clean, ESLint clean, production build passes (unaffected by a schema-only change, but confirm — a Supabase-generated types file, if added, must typecheck). — **not explicitly re-run as part of this documentation pass;** no application code was touched, so this remains expected to be a no-op.
- [x] Documentation updated: `PROJECT_STATUS.md` (Slice Completion table), `NEXT_STEPS.md` (this update), `db/migrations/README.md` (placeholder replaced).
- [x] No architectural violations: nothing here duplicates a Layer 1 service, nothing here builds Space visibility (that's Slice 4), the word "workspace" appears only in code/DB, never in any UI copy (there is no UI in this slice).
- [x] No prohibited terminology in any comment, commit message, or generated documentation.
- [x] Migrations numbered, each with a working, tested down-migration.
- [ ] Pull request created against `main`, referencing D18 and the amendment Parts 4/7 this slice's schema anticipates. — **not done.** The migrations are committed to `claude/lifeos-docs-upload-s5nyrn`; no dedicated pull request has been opened or updated for this slice specifically.

### Estimated Implementation Size

**Small–Medium.** Five small migration files (plus down-migrations) and no
application code. The bulk of the effort is in getting the constraints,
indexes, and RLS-enablement right the first time, and in deciding the CI/
migration-testing question (see Risks) — not in volume of SQL.

### Risks

1. **The original field-level schema document isn't in this repository.**
   `Database-Schema-Design.md` (and its audit) are referenced throughout
   the compact planning package as historical sources, but only the
   compact package itself (`LifeOS-Source-of-Truth.md`,
   `LifeOS-Technical-Handoff.md`, the Decision Register, the amendment) is
   physically present in `/docs`. This plan reconstructs a reasonable
   schema from those compact descriptions, but exact field-level specifics
   beyond what's stated (precise additional columns, naming conventions
   used in the original) were not — and could not be — checked against the
   original document. **If you still have that original document, it
   should be checked against this plan before writing real SQL.**
2. **CI cannot currently test real migrations** — no database service
   exists in `.github/workflows/ci.yml`. Needs an explicit decision (see
   Testing Strategy) before or during this slice, not an assumption either
   way.
3. **Supabase's own `auth.users` integration pattern** (e.g., a
   `handle_new_user()` trigger vs. an application-level insert into
   `profiles`) is a common, well-documented Supabase pattern but isn't
   spelled out in the compact planning docs — an implementation choice to
   make at build time, not a deviation from architecture either way.
4. **Branch protection isn't fully wired yet** (per the Slice 0 residual
   item) — the PR for this slice should still pass CI cleanly, but the
   safety net isn't currently enforced at the GitHub level.

### Assumptions (flagged for confirmation, not yet locked in)

1. `profiles.id` is the same UUID as `auth.users.id` (shared primary key) — the standard Supabase pattern, not a separate identity column.
2. Soft-deletion (Trash/Restore, D23, uniform 30-day retention) does **not** apply to these five identity/ownership tables — Trash/Restore is scoped to user-content records (Tasks, Notes, etc.) per the Source of Truth's "Archive, Trash, and Recovery" section; member removal and workspace archival are distinct, purpose-built protected operations, not generic soft-delete. Worth an explicit yes/no before implementation.
3. The two-member cap and single-owner invariant are enforced primarily at the service layer (Slices 2/16), with database constraints/triggers as defense-in-depth — following D17's stated precedent, not inventing a new pattern.
4. Five separate migration files (one per table) rather than one combined stage-1 migration — an implementation-granularity choice, open to being overridden.
5. RLS is enabled on all five tables immediately, even though policies can't be exercised end-to-end until Slice 2 provides a session-creation path.

### Files That Will Be Created or Modified

- `db/migrations/0001_profiles.sql` + down-migration (new)
- `db/migrations/0002_workspaces.sql` + down-migration (new)
- `db/migrations/0003_workspace_members.sql` + down-migration (new)
- `db/migrations/0004_user_settings.sql` + down-migration (new)
- `db/migrations/0005_invitations.sql` + down-migration (new)
- `db/migrations/README.md` (modified — replace the current "no migrations exist yet" placeholder)
- `project/PROJECT_STATUS.md` (modified — Slice Completion table)
- `project/NEXT_STEPS.md` (modified — mark Slice 1 complete)
- **Not touched in this slice:** any file under `/app`, `/components`, `/lib/services`, `/lib/queries`, `/lib/validation` — no application code begins until Slice 2.

---

## Slice 2 — Foundation: Sign-Up, Sign-In, Closed Sign-Up Posture

- **Objective:** The approved one-transaction sign-up (Auth user, profile,
  workspace, owner `workspace_members` row, default `user_settings`),
  sign-in, sign-out, password reset, and closed-sign-up enforcement (public
  sign-up disabled after the first account) — the invitation _acceptance_
  path itself is deferred to Slice 16.
- **Estimated complexity:** High — first protected-write service, first
  policy tests, first real auth surface.
- **Dependencies:** Slice 1.
- **Files likely to change:** `lib/services/signUp.ts`, `app/auth/*` (new,
  rebuilt from scratch — not the removed starter pages), `lib/validation/auth.ts`,
  `tests/unit/services/signUp.test.ts`, `tests/policies/cross-workspace.test.ts`.
- **Testing required:** Unit tests for the sign-up transaction including
  partial-failure rollback; cross-workspace policy tests; Playwright for the
  sign-up → sign-in → sign-out journey.
- **Definition of Done:** Full `DEFINITION_OF_DONE.md` checklist; closed
  sign-up verified by a release-blocking test (amendment 12.2).
- **Suggested branch:** `feat/foundation-auth`

---

## Slice 3 — Foundation: Dashboard Shell

- **Objective:** Minimal Dashboard route and layout shell (no real
  data-driven sections yet), and re-enable route protection in
  `lib/supabase/proxy.ts` now that a real sign-in flow exists to redirect
  to.
- **Estimated complexity:** Low–Medium.
- **Dependencies:** Slice 2.
- **Files likely to change:** `app/dashboard/layout.tsx`, `app/dashboard/page.tsx`,
  `lib/supabase/proxy.ts` (restore redirect-to-login enforcement).
- **Testing required:** Playwright smoke test (authenticated route renders,
  unauthenticated request redirects); axe-core clean.
- **Definition of Done:** Full checklist; no widgets built yet (those arrive
  with the features that populate them).
- **Suggested branch:** `feat/foundation-dashboard-shell`

---

## Slice 4 — Foundation: Spaces (Ownership + Private/Shared Visibility)

- **Objective:** Space create/view/archive/reopen, Space Owner assignment,
  the Private/Shared visibility setting with confirmation on change, and the
  first version of the single shared visibility/privacy query helper
  (`lib/queries`) — this is where the amendment's governing sharing rule
  (Part 6) actually gets built.
- **Estimated complexity:** High — this slice establishes the enforcement
  pattern every later feature depends on.
- **Dependencies:** Slice 3.
- **Files likely to change:** `db/migrations/0002_spaces.sql`,
  `lib/services/spaces.ts`, `lib/queries/visibility.ts`, `app/spaces/*`,
  `tests/policies/cross-visibility.test.ts`.
- **Testing required:** Unit tests; **both** policy-test families
  (cross-workspace and cross-visibility — this is the first path where
  cross-visibility applies); Playwright; axe-core.
- **Definition of Done:** Full checklist; the shared query helper is proven
  by test to exclude the other member's Private Spaces from every surface.
- **Suggested branch:** `feat/foundation-spaces-visibility`

---

## Slice 5 — Foundation: Title-Only Tasks + Soft Deletion

- **Objective:** Minimal Task (title required, everything else absent) —
  create, list, complete/incomplete (binary status, D7), soft-delete,
  restore — exercised end-to-end through the Slice 4 query helper and RLS.
- **Estimated complexity:** Medium.
- **Dependencies:** Slice 4.
- **Files likely to change:** `db/migrations/0003_tasks.sql`,
  `lib/services/tasks.ts`, `lib/queries/tasks.ts`, `lib/validation/task.ts`,
  Dashboard/Space UI integration.
- **Testing required:** Unit; both policy-test families; Playwright
  (create/complete/undo/soft-delete/restore journey); axe-core.
- **Definition of Done:** Full checklist; one-tap-with-Undo behavior verified
  for completing a Task (no confirmation dialog).
- **Suggested branch:** `feat/foundation-tasks-soft-delete`

---

## Slice 6 — Foundation: RLS Hardening & Policy Suite Completion (Alpha gate)

- **Objective:** Close out and audit RLS policies across every foundation
  table, and bring the policy-test suite to full coverage of the foundation
  slice. This slice is the **Alpha milestone** gate
  (`LifeOS-Implementation-Blueprint.md` §8: "Foundation slice complete;
  policy tests green").
- **Estimated complexity:** Medium.
- **Dependencies:** Slices 1–5.
- **Files likely to change:** `db/migrations/0004_rls_policies.sql`,
  `tests/policies/*` (comprehensive pass).
- **Testing required:** Full policy suite, both families, across every
  foundation table.
- **Definition of Done:** Full checklist; Alpha milestone criteria met;
  `PROJECT_STATUS.md` phase-completion table updated to mark the Foundation
  slice complete.
- **Suggested branch:** `feat/foundation-rls-hardening`

---

## Slice 7 — Quick Capture

- **Objective:** Instant-save raw-text capture, async type suggestion
  (Task/Note/Assignment/Bill/Appointment — never a bare Reminder unless
  nothing fits, D8), explicit user confirmation before conversion, the
  quiet privacy lock control (D28).
- **Estimated complexity:** High (first protected conversion service, first
  AI-adjacent suggestion surface with a hard confirmation gate).
- **Dependencies:** Slice 6.
- **Files likely to change:** `db/migrations/0005_inbox_captures.sql`,
  `lib/services/inboxConversion.ts`, `lib/queries/inbox.ts`, Quick Capture UI.
- **Testing required:** Unit (conversion service, incl. never-auto-saves
  invariant); both policy families; Playwright (capture → suggest →
  confirm → converted, and capture → dismiss); axe-core.
- **Definition of Done:** Full checklist; "nothing becomes structured data
  without explicit confirmation" proven by test.
- **Suggested branch:** `feat/quick-capture`

---

## Slice 8 — Notes

- **Objective:** Freeform Notes, optional title, autosave with a visible
  save-status indicator, pinned/archived status.
- **Estimated complexity:** Medium.
- **Dependencies:** Slice 6 (builds on foundation query/service patterns);
  benefits from Slice 7 for Quick-Capture-to-Note conversion but does not
  strictly require it.
- **Files likely to change:** `db/migrations/0006_notes.sql`,
  `lib/services/notes.ts`, `lib/queries/notes.ts`, Notes UI (Tiptap
  integration begins here, D20).
- **Testing required:** Unit; both policy families; Playwright (create,
  autosave, pin, archive); axe-core.
- **Definition of Done:** Full checklist.
- **Suggested branch:** `feat/notes`

---

## Slice 9 — Classes & Assignments

- **Objective:** Class (name required; course code/term/instructor
  Contact/schedule/location/meeting link/color optional; meeting times as a
  recurrence schedule, never persisted Events); Assignment (title + Class
  required, five-state status, separate official/personal due dates).
- **Estimated complexity:** High (first Layer 3 record type, first
  structural-reference-to-Contact pattern, five-state workflow).
- **Dependencies:** Slice 6; Contact needs to exist as at least a minimal
  Layer 2 record before "Instructor" can be selected — this slice includes a
  minimal Contact creation path if Contacts hasn't landed yet, or depends on
  a Contacts slice being pulled forward. Flag this dependency explicitly
  when planning the sprint.
- **Files likely to change:** `db/migrations/0007_classes_assignments.sql`,
  `lib/services/classes.ts`, `lib/services/assignments.ts`, Class/Assignment
  UI, minimal Contact selection UI.
- **Testing required:** Unit; both policy families; Playwright (add Class →
  add Assignment preselecting the Class → move through all five statuses);
  axe-core.
- **Definition of Done:** Full checklist; "Assignment creation from a Class
  preselects that Class" acceptance criterion verified.
- **Suggested branch:** `feat/classes-assignments`

---

## Slice 10 — Bills & Bill Occurrences

- **Objective:** Bill definition (name, expected amount, due date required;
  payee Contact, recurrence, auto-pay status, payment-method label, account
  nickname, last-four-digits optional); rolling 90-day Bill Occurrence
  generation job; payment recording with no bank-transfer language;
  historical Occurrences never rewritten by a recurrence change.
- **Estimated complexity:** High (first background job, first currency
  handling, strict prohibited-language surface).
- **Dependencies:** Slice 6; Contact (payee) — same dependency note as
  Slice 9.
- **Files likely to change:** `db/migrations/0008_bills.sql`,
  `lib/services/bills.ts`, `lib/services/recordPayment.ts`,
  `jobs/generateBillOccurrences.ts`, Bills UI.
- **Testing required:** Unit (incl. the 90-day generation job and the
  never-rewrite-history invariant); both policy families; Playwright
  (add Bill → see Occurrences → record a payment); axe-core; a prohibited-terminology
  sweep on all copy ("Mark Paid"/"Record Payment," never "Pay").
- **Definition of Done:** Full checklist; "Record Payment never uses
  bank-transfer language" acceptance criterion verified.
- **Suggested branch:** `feat/bills-occurrences`

---

## Slice 11 — Calendar & Appointments

- **Objective:** Event (owns all scheduling) and Appointment (links to
  exactly one Event, paired creation/deletion as one transaction);
  FullCalendar Month/Week/Day (D21, free tier only); Class meeting times as
  query-time virtual blocks; Task/Assignment/Bill deadlines as chips, never
  duplicated as Events.
- **Estimated complexity:** High (first paired-transaction service, first
  drag-and-drop interaction rules, third-party calendar library
  integration).
- **Dependencies:** Slices 6, 9 (Class meeting expansion), 10 (Bill
  deadline chips) for full chip coverage — Events/Appointments themselves
  only need Slice 6.
- **Files likely to change:** `db/migrations/0009_events_appointments.sql`,
  `lib/services/appointments.ts` (paired Event+Appointment transaction),
  `lib/queries/calendar.ts`, Calendar UI (FullCalendar wiring).
- **Testing required:** Unit (paired creation/deletion, incl. the
  keep-Event-unpair-it choice, P8-C); both policy families; Playwright
  (create Appointment+Event, drag to reschedule with Undo, drag a deadline
  chip into confirm-and-edit); axe-core.
- **Definition of Done:** Full checklist; P8-C same-Space/same-visibility
  invariant verified by test.
- **Suggested branch:** `feat/calendar-appointments`

---

## Slice 12 — Reminders

- **Objective:** One shared reminder system across Task/Assignment/Bill/
  Event/Appointment; materialized `next_fire_at` (D13); per-member delivery
  targeting with the optional "Remind both of us" control; snooze/dismiss
  per member; the reminder-firing and retry background jobs.
- **Estimated complexity:** High (scheduler correctness, per-member
  delivery targeting is new sharing-model surface).
- **Dependencies:** Slices 6, 9, 10, 11 (reminders attach to records from
  all of those).
- **Files likely to change:** `db/migrations/0010_reminders.sql`,
  `lib/services/reminders.ts`, `jobs/fireReminders.ts`,
  `jobs/retryReminderDelivery.ts`, Reminder UI surfaces across record types.
- **Testing required:** Unit (recalculation triggers: date/offset/timezone/occurrence/snooze
  changes); both policy families; Playwright (set a reminder, snooze,
  dismiss, verify the other member's copy is unaffected); axe-core.
- **Definition of Done:** Full checklist; "one member's snooze/dismiss never
  affects the other's" verified by test (amendment 5.5).
- **Suggested branch:** `feat/reminders`

---

## Slice 13 — Search

- **Objective:** Exact → trigram → full-text search across all searchable
  record types; archived excluded by default with a toggle; deleted always
  excluded; Restricted never previewed broadly; the other member's private
  content never present in any result, suggestion, or count.
- **Estimated complexity:** Medium–High (ranking logic, `pg_trgm` +
  Postgres FTS wiring, must route entirely through the Slice 4 query
  helper).
- **Dependencies:** Slice 6 at minimum; more useful once Slices 7–12 give
  it real content to search.
- **Files likely to change:** `db/migrations/0011_search_indexes.sql`,
  `lib/queries/search.ts`, Search UI.
- **Testing required:** Unit (ranking order); both policy families
  (search is a named enforcement point in amendment 10.4); Playwright;
  axe-core.
- **Definition of Done:** Full checklist; cross-visibility exclusion in
  search results verified by test.
- **Suggested branch:** `feat/search`

---

## Slice 14 — Files

- **Objective:** File metadata separate from Storage bytes; one File
  attachable to multiple records; download only via server-checked
  short-lived signed URLs; attaching to a Shared record as a deliberate
  sharing action (F6).
- **Estimated complexity:** Medium–High (Storage integration, signed-URL
  authorization path).
- **Dependencies:** Slice 6; more useful with Slices 7–13 as attachment
  targets.
- **Files likely to change:** `db/migrations/0012_files_attachments.sql`,
  `lib/services/files.ts`, `lib/queries/files.ts`, File upload/attach UI.
- **Testing required:** Unit (signed-URL authorization, soft-delete keeps
  the object, permanent deletion removes both metadata and bytes); both
  policy families; Playwright; axe-core.
- **Definition of Done:** Full checklist; unauthorized download attempt
  verified to fail by test.
- **Suggested branch:** `feat/files`

---

## Slice 15 — Privacy Levels

- **Objective:** Standard/Sensitive/Restricted (D9/D10) applied uniformly
  across every record type already built; Restricted's deliberate-intent
  access rule; AI-eligibility flag (`ai_assisted`, D29) plumbing (no AI
  write behavior yet — just the field and its exclusion rules).
- **Estimated complexity:** Medium (mostly wiring an existing axis into the
  Slice 4 query helper and every screen built so far, rather than new
  concepts).
- **Dependencies:** Slice 6, and effectively every record-type slice built
  before it (7–14) since this slice retrofits Privacy Level UI onto all of
  them.
- **Files likely to change:** `lib/queries/*` (privacy filtering added to
  the shared helper), Privacy Level control in each record's edit surface.
- **Testing required:** Unit; both policy families; Playwright (Restricted
  record excluded from Dashboard/Search/counts until deliberately opened);
  axe-core.
- **Definition of Done:** Full checklist; the intent-based (not
  session-based) Restricted rule verified by test.
- **Suggested branch:** `feat/privacy-levels`

---

## Slice 16 — Invitation & Two-Member Flows

- **Objective:** Invitation lifecycle (invite/deliver/accept/expire/revoke/remove/re-invite),
  invitation acceptance transaction (joins existing workspace as Member),
  member removal with P6-D transfers, the one-sentence trust-boundary
  disclosure at acceptance (Part 12.5).
- **Estimated complexity:** High (last major protected-write surface;
  membership-mutating, audit-relevant, Owner-only authorization).
- **Dependencies:** Slice 6 at minimum; realistically wants Slices 7–15
  complete so the two-member experience can be tested against a full
  feature set, per the approved phase placement (F1: this phase is
  deliberately late).
- **Files likely to change:** `db/migrations/0013_invitations_finalize.sql`
  (if any adjustment is needed beyond Slice 1's invitations table),
  `lib/services/invitations.ts`, `lib/services/removeMember.ts`, Settings UI
  invitation section.
- **Testing required:** Unit (acceptance transaction, atomic invitation
  consumption, P6-D transfer logic); both policy families (this is where
  the second real account first exists — cross-visibility tests become
  meaningful end-to-end here); Playwright (invite → accept → use as Member →
  remove); axe-core.
- **Definition of Done:** Full checklist; P6-A/P6-B/P6-D all verified by
  test; closed-sign-up posture re-verified with two real accounts.
- **Suggested branch:** `feat/invitations-two-member`

---

## Slice 17 — Final UX / Accessibility / Mobile Pass

- **Objective:** The 13 simplicity acceptance criteria and the 10-action
  no-instructions test run as the release-blocking Playwright suite across
  the whole app; full axe-core sweep; mobile-viewport pass; prohibited-terms
  sweep across all UI copy.
- **Estimated complexity:** Medium (mostly verification and targeted fixes,
  not new features).
- **Dependencies:** Slices 0–16 complete.
- **Files likely to change:** Targeted fixes across `app/` and `components/`
  wherever a criterion fails; `tests/e2e/simplicity-acceptance.spec.ts`.
- **Testing required:** All 13 simplicity criteria as Playwright tests
  (release-blocking); full axe-core sweep; mobile viewport Playwright pass;
  prohibited-terminology sweep.
- **Definition of Done:** Full checklist; every release-blocking test green;
  this is the **v1.0 milestone** (`LifeOS-Implementation-Blueprint.md` §8).
- **Suggested branch:** `feat/final-ux-accessibility-mobile-pass`

---

## After v1.0

`LifeOS-Decision-Register.md` D22: Calendar Agenda view is the first
post-release item (v1.1). Nothing beyond v1.0 is sliced here — re-derive
from `LifeOS-MVP-Scope.md` "Deferred Until Later" when that work is
actually approved to begin.
