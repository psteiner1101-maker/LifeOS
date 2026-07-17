# LifeOS Technical Handoff
**Status:** Planning complete and frozen (Architecture Change Requests govern any change) — nothing described here has been implemented. Conformed (F7) to the approved Private-Hosting-and-Two-Person-Access-Amendment.md; all stack items are approved.

---

## Stack
Next.js (TypeScript, App Router) · Tailwind CSS · shadcn/ui (Radix-based) · Supabase (Authentication, PostgreSQL, Storage) · Vercel deployment · date-fns + date-fns-tz · React Hook Form + Zod · Tiptap rich-text editor *(approved, D20)* · FullCalendar *(approved, D21; free-tier features only)* · Vitest / Playwright / axe-core for testing · a hosted error-tracking service such as Sentry *(approved, D30 — technical diagnostics only, never private-record content)* · standard Supabase Auth email flow for invitations and password resets *(approved, P7-A)*.

## Client vs. Server vs. Database Responsibilities
- **Client:** renders UI, client-side Zod validation, navigates, calls server actions; may read the user's own single-table data directly under RLS (e.g., a Task list) and may make simple single-field edits to a record it owns directly.
- **Server:** every protected write (below), authoritative re-validation, multi-step transactions (Appointment+Event, Bill Occurrence generation, Inbox conversion), background jobs, file-storage authorization.
- **Database:** stores data; enforces foreign keys for essential domain links and check/uniqueness constraints; RLS is the baseline authorization boundary, never the sole integrity control for polymorphic references.

## Protected Write Services (must go through a controlled server-side path, never direct client writes)
Polymorphic relationship creation · polymorphic attachment creation · tag attachment · reminder attachment · Inbox conversion · permanent deletion · Bill occurrence generation · payment recording · Appointment-and-Event paired creation/deletion · recurrence changes · invitation creation/revocation · member removal (including P6-D ownership transfers) · Space visibility changes (Private↔Shared, Space-Owner-only) · (future) external sync. Each validates record-type allowance, target existence, non-deleted state, matching workspace on all sides, authorization, visibility coherence (the acting member can see every record involved — amendment 8.4), and duplicate/self-reference prevention, inside a single transaction per operation.

## Authentication & Workspace Setup
Sign-up creates, in one transaction: Auth user (Supabase), profile, workspace, one owner `workspace_members` row, and `user_settings` with approved defaults. Sign-up is closed after the first account: the invited Member's acceptance runs the same transaction shape but joins the existing workspace as Member instead of creating a new workspace, consuming the invitation atomically (amendment Part 7). Partial failure → plain-language retry, Auth user preserved for re-attempt, monitored error logged. Session via Supabase httpOnly cookies. Route protection via shared middleware. The word "Workspace" never appears in the UI.

## Row-Level-Security Approach
Every workspace-owned table: any workspace member may read/insert/update/soft-delete within their own workspace, additionally constrained by Space-level Private/Shared visibility and the "Only me" override, enforced at the row-visibility layer via the single shared query helper — never per-screen filtering (amendment Part 8). Polymorphic junction tables (record_tags, record_attachments, record_relationships, reminders, daily_priorities): reads follow workspace membership, but **writes only through the protected server path** — RLS alone cannot validate a polymorphic target lives in the correct table. Audit events: written only by server services/jobs, never exposed in the normal UI. Restricted-record exclusion from broad queries is enforced by one shared query-building helper applied everywhere, not per-screen logic.

## Migration Order (13 stages, no SQL yet)
1. Identity/ownership (profiles, workspaces, workspace_members, user_settings, invitations — F2) → 2. Organization (spaces — including Space ownership and Private/Shared visibility (F2) — projects, folders, tags) → 3. Core records (tasks, notes, contacts, files) → 4. School (classes, class_meeting_schedules, assignments) → 5. Bills (bills, bill_occurrences) → 6. Calendar/Appointments (events, appointments) → 7. Inbox/provenance (inbox_captures + provenance columns) → 8. Reminders (reminders, reminder_history, per-member delivery targeting — F2) → 9. Files/attachments (record_attachments) → 10. Cross-record systems (record_tags, record_relationships, daily_priorities — personal per member, P10-A/F2 — audit_events) → 11. Search indexes (trigram + full-text) → 12. Security policies (RLS) → 13. Seeded defaults. Each stage depends only on earlier stages; each is its own migration with a paired down-migration.

## Background Jobs (Supabase Scheduled Functions, not an always-on server)
Bill occurrence generation (daily) · Reminder firing (every few minutes) · Reminder delivery retry (on failure, one retry) · Trash expiration (daily, 30-day window) · Polymorphic orphan detection (weekly, backup safety net) · Audit maintenance (not scheduled in MVP — indefinite retention).

## Reminder Architecture
Each reminder stores a materialized `next_fire_at`, recalculated on: record date change, offset change, user time-zone change, occurrence generation, or snooze. Scheduler needs one indexed query: `next_fire_at ≤ now`. Bill reminders: default rules on the Bill definition, actual instances on each Occurrence (cancelled on payment). Appointment reminders: live solely on the linked Event. Delivery defaults to the reminder's creator only, with an optional "Remind both of us" control on Shared-Space records; snooze/dismiss is per member (amendment Part 5.5). In-app delivery always happens; browser push is a best-effort secondary channel with one bounded retry.

## Search Architecture
Exact match (case-insensitive) → trigram match on titles/names (`pg_trgm`, real substring + mild typo tolerance) → full-text match on long content (native Postgres FTS, stemming). Per-table queries combined and ranked at the application layer. Privacy/archived/deleted filters — and cross-member visibility exclusion (the other member's Private-Space and "Only me" content) — applied via one shared query helper (amendment Parts 8 and 10). No unified search-index table in MVP — deferred until proven necessary. No general fuzzy/typo tolerance promised beyond the mild trigram effect on short fields.

## File Architecture
Metadata (`files` table) separate from physical bytes (Supabase Storage, path namespaced by workspace + file ID). One File attaches to many records via `record_attachments` — one upload, many links. Downloads always via a server-checked short-lived signed URL, never a public URL. Soft-delete keeps the object; permanent deletion removes both metadata and bytes together.

## Quick Capture Architecture
Save raw text immediately (fast, non-polymorphic write) → assign privacy (default/Space-context/optional user choice) → async parsing (never blocks save) → suggestions stored on the same row → user reviews/confirms/edits → protected conversion service creates the target record (+ paired Event if Appointment) and marks the capture Processed, atomically → provenance (`ai_assisted`, `original_capture_id`) and an audit event recorded. Parsing failure never blocks capture; nothing becomes structured data without explicit confirmation.

## Calendar Architecture
FullCalendar, Month/Week/Day only (Agenda deferred to v1.1). Events and Appointment-linked Events fetched directly per visible range; Class meeting schedules expanded into virtual blocks at query time (never persisted as Events); Task/Assignment/Bill deadlines rendered as labeled chips, never time-blocks. All times resolved in the user's stored time zone. Restricted items render as generic "Busy" blocks. Dragging a scheduled Event updates it directly with Undo; dragging a deadline chip is intercepted into a required confirm-and-edit step.

## Error Handling
Failed saves never clear user input; every multi-step protected write is one transaction (all-or-nothing); offline/autosave/upload failures show plain-language messages with retry, preserving entered content; version conflicts show "changed elsewhere — reload"; authorization failures show a plain "you don't have access," never a technical code; expired Trash items get a clear explanation, not a generic failure.

## Testing Strategy
Vitest (unit/integration, including protected-write-service and database-policy tests confirming cross-workspace access is blocked) · Playwright (end-to-end across desktop/mobile viewports) · axe-core plus manual keyboard checks (accessibility). **The 13 simplicity acceptance criteria are release-blocking Playwright end-to-end tests**, not optional polish checks.

## Git Workflow
Single GitHub repo, main branch protected (tests required, no direct pushes), feature branches, small commits, pull-request review checkpoints even for solo development, numbered ordered migrations only (no manual DB changes), backups before any production schema change, rollback via down-migrations (DB) or Vercel instant rollback (app). Claude must inspect existing files before changing them and must never replace working systems unnecessarily.

## Implementation Phases
**Foundation slice:** sign-up (auto profile/workspace/settings) → sign-in → basic Dashboard shell → Spaces (including Space ownership and Private/Shared visibility structures, per amendment 1.3) → simple title-only Tasks → soft deletion → basic RLS including visibility enforcement, verified by cross-workspace **and** cross-visibility policy tests.
**Then, in order:** Quick Capture → Notes → Classes & Assignments → Bills → Calendar & Appointments → Reminders → Search → Files → Privacy → Invitation & two-member flows (closed sign-up posture, invitation lifecycle, member removal with P6-D — approved F1 insertion; unrelated phases unchanged) → final UX/accessibility/mobile refinement pass. Each phase ends with a working, testable slice before the next begins.
