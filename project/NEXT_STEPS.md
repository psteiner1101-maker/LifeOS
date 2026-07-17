# Next Steps — Implementation Roadmap

*Roadmap baseline: 2026-07-17, immediately after Phase 1 (project foundation
scaffold).*

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

## Slice 0 — Infrastructure Provisioning

- **Objective:** Provision a real Supabase project (dev environment) and a
  real Vercel project; wire environment variables; add a CI workflow that
  runs `lint`, `typecheck`, `test`, and `build` on every push/PR; enable
  branch protection on `main` (required checks, no direct pushes).
- **Estimated complexity:** Low–Medium (configuration, no application code).
- **Dependencies:** None — can start immediately.
- **Files likely to change:** `.github/workflows/ci.yml` (new), `README.md`
  (setup instructions), no application code.
- **Testing required:** Open a throwaway PR to confirm CI runs and blocks on
  a deliberately broken check; confirm a direct push to `main` is rejected.
- **Definition of Done:** CI green on a real PR; branch protection verified;
  `PROJECT_STATUS.md` "Deployment/Supabase/Vercel/GitHub Status" updated to
  reflect real infrastructure.
- **Suggested branch:** `chore/infra-provisioning`

---

## Slice 1 — Foundation: Identity & Workspace Migrations

- **Objective:** Numbered migrations for `profiles`, `workspaces`,
  `workspace_members`, `user_settings`, `invitations` (schema only — no
  application code), per migration stage 1 (`LifeOS-Technical-Handoff.md`
  "Migration Order").
- **Estimated complexity:** Medium.
- **Dependencies:** Slice 0 (needs a real Supabase project to apply
  migrations against).
- **Files likely to change:** `db/migrations/0001_identity_and_workspace.sql`
  + paired down-migration.
- **Testing required:** Migration applies/reverts cleanly against a fresh
  dev database; no application-level tests yet (nothing reads/writes these
  tables until Slice 2).
- **Definition of Done:** Migration numbered, reversible, applied to dev;
  down-migration verified to actually undo it.
- **Suggested branch:** `feat/foundation-identity-migrations`

---

## Slice 2 — Foundation: Sign-Up, Sign-In, Closed Sign-Up Posture

- **Objective:** The approved one-transaction sign-up (Auth user, profile,
  workspace, owner `workspace_members` row, default `user_settings`),
  sign-in, sign-out, password reset, and closed-sign-up enforcement (public
  sign-up disabled after the first account) — the invitation *acceptance*
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
