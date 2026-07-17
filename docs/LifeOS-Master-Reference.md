# LifeOS Master Reference

**Purpose of this document:** the single document a future AI (or human) needs to understand the complete LifeOS project. It **summarizes** the approved planning and points to the authoritative documents for full detail; it never replaces them. Where this summary and an authoritative document could ever be read differently, the authoritative document wins and the discrepancy must be raised, never silently resolved.

**Project state at time of writing:** planning is 100% complete, approved, and frozen. No implementation, code, SQL, migrations, or Supabase setup exists yet.

---

## 1. What LifeOS Is

LifeOS is a personal operating system: one calm, opinionated application that replaces a task manager, notes app, calendar, bill tracker, and project tool — built first for a student's school-plus-everyday life, structurally ready for every later life stage without a redesign. It is explicitly **not** a Notion-style open-ended workspace builder: no blank canvases, no databases-as-a-feature, no configuration before usefulness.

v1 ships as a **Privately Hosted** instance for **exactly two trusted members** — a **Workspace Owner** and one invited **Member** (for example, a couple or two household members) — running on the members' own Vercel and Supabase accounts, with public sign-up closed.

The single most important constraint in the entire project is the **Simplicity Standard** (Decision D27, governing and non-negotiable): a first-time nontechnical user must be able to perform ten core actions with no instructions, and failure of that test blocks release. Every other section of this document is subordinate to that rule.

Authoritative sources: *LifeOS-Source-of-Truth.md* (full condensed specification); *Product-Vision-and-Scope.md* (historical).

## 2. How the Project Is Governed

- **Architecture Freeze (in effect).** Planning is complete. No document may silently change an approved decision. No recommendation becomes a rule without the user's explicit approval.
- **Architecture Change Request (ACR).** Any future architectural change must be presented as an ACR containing: why the change is necessary, benefits, drawbacks, scope impact, migration impact, simplicity impact, and a recommendation — and must receive approval **before** any approved document is modified.
- **Amendment discipline.** Every rule introduced after the original planning is tagged as either extending a named approved decision or as a genuinely new decision; conflicts are flagged, never silently resolved. This discipline is binding on all future work, including implementation.
- **Terminology standard (F9, mandatory).** All documentation, code, comments, and UI copy use: **Workspace Owner**, **Space Owner**, **Private Space**, **Shared Space**, **Privacy Level**, **Privately Hosted**. Bare "Owner," "private," or "shared" are avoided wherever context leaves them ambiguous. (UI copy additionally obeys the plain-language rules of Section 5 — users see plain words like "Private" and "Shared" on a Space because context there is unambiguous.)
- **Decision trail.** Every decision, its reasoning, its source, and its status lives in *LifeOS-Decision-Register.md* (D1–D31 plus the Amendment and Final-Review Decisions table: C1–C2, P6-A–D, P7-A, P8-A/B/C, P10-A/B, F6, F9, ACR).

## 3. The Authoritative Document Set

Per approved decision F8, the **complete authoritative planning set** is:

1. **LifeOS-Master-Reference.md** — this document; read first.
2. **LifeOS-Source-of-Truth.md** — the condensed specification.
3. **LifeOS-MVP-Scope.md** — the must-have / soft-hidden / deferred / prohibited checklist; the daily scope-control instrument.
4. **LifeOS-Technical-Handoff.md** — the condensed technical design (stack, responsibilities, protected writes, RLS, migration order, jobs, architectures, phases).
5. **Private-Hosting-and-Two-Person-Access-Amendment.md** — the approved two-member model, Parts 1–12, including its Approval Record and the Architecture Freeze record.
6. **LifeOS-Implementation-Blueprint.md** — the master implementation guide (phases, build order, standards, security, testing, Definition of Done).
7. **LifeOS-Decision-Register.md** — every decision with source and status.
8. **LifeOS-Document-Index.md** — the document map and reading order.
9. **LifeOS-Current-Status-and-Next-Step.md** — where the project stands and exactly what happens next.

The nine original planning documents (Core-Domain-Architecture-v2, Product-Vision-and-Scope, User-Experience-and-Wireframes, Information-Architecture-and-Screen-Specifications, Architecture-Final-Review-and-Amendments, Database-Schema-Design, Database-Schema-Final-Audit-and-Simplicity-Amendment, Technical-Architecture-and-Implementation-Plan, and the superseded first-draft architecture) are **historical references only** — consulted solely when a historical decision must be researched.

## 4. Product Scope

**Must-have MVP features** (full checklist with per-feature "Done when" criteria in *LifeOS-MVP-Scope.md*): closed-sign-up Authentication with automatic account setup; Spaces with Private/Shared visibility; Invitation & member removal; Dashboard; Quick Capture & Inbox; Tasks; Notes; Classes & Assignments; Bills & Bill Occurrences; Calendar (Month/Week/Day); Events & Appointments; Contacts; Reminders; Search; Privacy Levels; Archive/Trash/Recovery; Files.

**Present in schema but soft-hidden in v1** (D19): Projects, Folders, Tags (optional, under "More options"), workspace/workspace_members (the word "workspace" never appears in the UI), `assigned_to` (unused), audit events (never exposed), the daily-priorities table (powers the one-tap star; never browsable).

**Deferred:** full budgeting, bank connections, grade forecasting, vehicles, household inventory, health records, travel planning, collaboration beyond two members, AI-initiated writes, complex automations, offline sync, native mobile apps, Calendar Agenda view (→ v1.1), external calendar sync, field-level AI provenance.

**Explicitly prohibited — verbatim binding, no exceptions** (full list in *LifeOS-MVP-Scope.md*): storing full account/card numbers, security codes, or passwords; any payment-sending language ("Pay"/"Send"/"Transfer" — LifeOS records payments, never sends them); any AI action without explicit user confirmation; duplicating due dates as Events; rewriting historical Bill Occurrences; cascading a Space's archive date onto contained records; technical terms anywhere in the UI; requiring Tags/Projects/Folders/attachments/privacy changes during ordinary creation; ordinary client writes to any polymorphic table; **any interface path revealing another member's Private-Space or "Only me" content, including titles, previews, counts, storage summaries, or hints.**

## 5. The Simplicity Standard (D27 — governs everything)

LifeOS must be far easier to use than Notion: opinionated defaults, immediately useful, guided rather than blank-canvas, calm, beginner-friendly. The powerful architecture stays invisible; no technical vocabulary ever reaches the interface.

**The release-blocking ten-action test:** a first-time nontechnical user, with no instructions, can add a Task, add a Note, add a Class, add an Assignment, add a Bill, record a payment, add an Event, find an item, save a Quick Capture, and understand what's due today.

**Complexity budget rule:** nothing enters a primary v1 flow unless the majority of users need it to complete that flow.

**Approved acceptance criteria** (all release-blocking, implemented as Playwright tests — full list in *LifeOS-Source-of-Truth.md*): one-screen title-only Task creation; one-tap Quick Capture with zero categorization; context pre-selection (Assignment from a Class preselects the Class); no bank-transfer language; zero-setup Dashboard; ≤3 onboarding steps; advanced fields behind "More options"; one-tap-with-Undo (never confirmation dialogs) for completing Tasks, recording payments, and changing Assignment status; the mobile Quick Capture button never overlaps controls.

The entire sharing model adds exactly **two** user-facing controls and no others: the per-Space question "Is this Space private or shared?" and the optional "Only me" option on the existing quiet lock control.

## 6. Core Architecture — Three Layers

(Full model: *LifeOS-Source-of-Truth.md*; historical detail: Core-Domain-Architecture-v2 and Architecture-Final-Review-and-Amendments.)

1. **Layer 1 — Shared Platform Services** (built once, never duplicated): Authentication, Ownership/Permissions, Spaces, Tags, Typed Relationships, Search, Reminders, Notifications, Files & Attachments, Comments, Audit History, Import/Export, Calendar Sync, Soft Deletion & Recovery.
2. **Layer 2 — Universal Productivity Objects:** Task, Note, Event, Project, File, Contact.
3. **Layer 3 — Specialized Domain Records** (real structured fields; consume Layer 1; never rebuild it): Class, Assignment, Exam, Grade Category, Bill, Bill Occurrence, Subscription, Income Entry, Budget Entry, Appointment, Goal, Vehicle and maintenance records, Household Item, Document Renewal. Layer 3 records are not required to link to a Layer 2 object.

**The one binding layer rule (D1/D2):** a Layer 3 record never builds its own private Task/Note/Reminder/Search/File/Notification system.

## 7. Organizational Model (D3, D19)

- **Space** — a lasting area of life (School, Work, Personal, Finances, Household). The only organizational concept a new user must learn. Every Space has one **Space Owner** (its creator) and one visibility setting (Section 9).
- **Project** — a temporary, goal-bound container. Projects never appear on the Calendar, never generate reminders, never appear in due sections. Soft-hidden in v1.
- **Folder** — pure visual organization; one parent, no cycles, owns no behavior. Soft-hidden in v1.
- **Tag** — a lightweight cross-cutting label; optional, never required.

## 8. The Two-Member Model

(Authoritative: *Private-Hosting-and-Two-Person-Access-Amendment.md*, Parts 1–12 and Approval Record. This section is a faithful summary.)

**Roles.** Exactly two membership roles: **Workspace Owner** (created the workspace; can invite/revoke/remove; sole manual permanent-deleter of shared records) and **Member** (full ordinary use). Day-to-day authority follows **Space ownership**, not membership role — the Workspace Owner has no special power inside a Member-owned Space and cannot see a Member-owned Private Space at all.

**Closed sign-up (Part 7).** The first account creates the workspace via the approved one-transaction setup. After that, public registration is disabled; the second account exists only via a valid, unexpired, unrevoked invitation link, whose acceptance runs the same transaction shape (joining as Member; invitation consumed atomically). Email for invitations and password resets uses the standard Supabase Auth flow (P7-A). Neither member can touch the other's credentials.

**Invitation lifecycle (Part 4):** invite (one at a time, Owner-only, from a single Settings section) → deliver → accept → expire/revoke → remove → re-invite. All language plain; nothing sharing-related appears in onboarding, navigation, or creation forms; a never-shared workspace behaves exactly like the single-user design.

**Member removal (P6-D):** Member-owned Shared Spaces transfer to the Workspace Owner (audit-recorded; records, attribution, and history intact; nothing deleted or duplicated). Member-owned Private Spaces and "Only me" records remain preserved and invisible (P6-A) — never transferred, exposed, or auto-deleted; a future secure export/account-restoration process may address them. Member-created records in Shared Spaces remain, fully attributed.

**Operations (Part 12):** one private Vercel project + one private Supabase project; the instance operator keeps sign-up closed (verified by test), follows the approved migration/backup/rollback rules, maintains the email path, and keeps error tracking scrubbed of private-record content. "Privately Hosted" means privately *hosted* — not local-only; offline operation remains deferred.

**Trust boundary, stated honestly (Part 6.8/12.5):** the application guarantees zero interface-level leakage between members; whoever operates the database can technically access stored data outside the application. This is acknowledged plainly — one plain-language sentence at invitation acceptance — never hidden. Per-record end-to-end encryption is out of scope for v1.

## 9. Visibility and Privacy — Two Separate Axes

This is the most important model in the project after the Simplicity Standard. **Never conflate the axes.**

**Axis 1 — Visibility (who can see it):**

- **Private Space:** visible only to its Space Owner. For the other member it does not exist: absent from navigation, Dashboard, Search, Calendar (not even a "Busy" block), counts, previews, storage summaries, suggestions, and metadata. Records inherit Private visibility automatically — nobody marks records one by one.
- **Shared Space:** visible to both members; both use and update ordinary records identically. Records inherit Shared visibility automatically.
- **"Only me" (record-level override, Shared Spaces only):** for the occasional private record inside a shared area. Visible only to its creator; excluded from the other member's every surface and count; scheduled "Only me" items render to the other member as a generic, non-interactive **"Busy"** block (unless a later approved decision changes this).
- **Inheritance and movement:** Private Space → Private records; Shared Space → Shared records; Shared + "Only me" → creator only. A record in a Private Space cannot be flipped to Shared in place — it must be deliberately moved or copied to a Shared Space. Quick Capture conversion raises, never lowers, protection, for both axes.
- **Space management (C2):** only the Space Owner archives, reopens, or switches a Space Private↔Shared, each direction with confirmation.

**Axis 2 — Privacy Level (how it behaves for those who can see it), D9/D10 unchanged:**

- **Standard:** normal Search/Dashboard/AI eligibility.
- **Sensitive:** excluded from AI access by default; normal visibility.
- **Restricted:** excluded from AI access and from *broad* views (Dashboard sections, Search previews, aggregate counts) for **every** member who can see it; opened only by current, deliberate intent — never a session boundary or viewed-timestamp (D10). Restricted scheduled items render as "Busy" in broad calendar views.

A Private-Space record is *stricter* than Restricted for the other member: Restricted limits broad exposure for people with access; Private-Space visibility removes access entirely.

**Cross-visibility rules (approved):**

- **P8-A:** a member may link a Shared record to one of their own private records; the private end is completely invisible to the other member — no titles, previews, counts, results, metadata, or hints; the relationship behaves exactly as though it does not exist for anyone without access.
- **P8-B:** structural references (Class→Instructor, Bill→Payee, Appointment→Provider) on Shared records may reference only records visible to both members; the interface never offers invalid selections; no hidden structural references exist on Shared records.
- **P8-C:** an Appointment and its Event always belong to the same Space with identical visibility; moving one automatically moves the other; an Appointment never exists without its Event. (Deleting an Appointment while choosing "keep the Event" unpairs that Event into a standalone Event, preserving D4's approved deletion-choice flow.)
- **P10-B:** Inbox captures are visible only to their author; the resulting record's visibility is determined at conversion by the destination Space.
- **F6:** attaching a File to a Shared record is a deliberate sharing action for that File — made intuitive, without added confirmation dialogs unless future testing proves them necessary.

## 10. Record-Type Rules (summary; full field lists in *LifeOS-Source-of-Truth.md*)

- **Task:** title required, everything else optional; **binary status** Incomplete/Complete (D7); no default reminder (D25).
- **Note:** freeform, optional title, autosave with visible save status.
- **Class:** name required; meeting times render from a recurrence schedule and are **never persisted as Events**.
- **Assignment:** title + Class required; **five statuses** — Not Started, In Progress, Completed, Submitted, Graded (D6); official due date and personal target date always separate fields.
- **Bill / Bill Occurrence (D5, D14):** Bill is the definition; Occurrences generate on a rolling 90-day window; history is never rewritten by recurrence changes; last-four-digits only, never full numbers; "Mark Paid"/"Record Payment," never "Pay." Reminder rules live on the Bill; actual instances live per Occurrence and are cancelled for both members on payment.
- **Event / Appointment (D4, D15, P8-C):** Event owns all scheduling; Appointment owns appointment-specific detail and links to exactly one Event; Appointment reminders live solely on the linked Event; paired creation/deletion is one protected transaction.
- **Contact:** universal Layer 2 record; never owns due dates, reminders, or calendar presence; structural references use dedicated foreign keys (P8-B applies), open-ended associations use the relationship graph — never both for the same purpose.

## 11. Behavioral Summaries

**Dashboard.** Each member's Dashboard composes all Shared Spaces plus that member's own active Private Spaces — never the other member's. Sections: Today's Schedule, Overdue, Due Today, Due Soon, Upcoming Bills, Quick Capture (default); Daily Priorities, Weekly Workload, Recent Notes, Recently Completed (togglable). Ordered by date-computed urgency, never grouped by Space. Four concepts never collapse: **Priority** (user-set importance), **Today's Priority** (day-scoped one-tap star, personal per member — P10-A, D26), **Due Date**, **Urgency** (purely date-computed). Restricted records excluded from every section and count; archived-Space content never appears; no shared/private badges anywhere.

**Quick Capture & Inbox.** One tap, save raw text instantly, zero required categorization; async suggestion of the most specific type (never a bare Reminder unless nothing fits — D8); nothing becomes structured without explicit confirmation; conversion marks the capture Processed with a two-way provenance link; captures are author-only until conversion (P10-B); the quiet lock control (D28) carries privacy and the "Only me" option.

**Calendar.** Month/Week/Day only in v1 (Agenda → v1.1, D22). One calendar per member, composed by the visibility rule. Scheduled Events drag-to-update with Undo; deadline chips (Tasks/Assignments/Bills — never duplicated as Events) drag into a required confirm-and-edit. Class meetings are query-time virtual blocks. Restricted and "Only me" items show as non-interactive "Busy" to the relevant viewer; Private-Space items show nothing to the other member.

**Reminders.** One shared system (never per-type); each reminder materializes `next_fire_at` (D13), recalculated on date/offset/time-zone/occurrence/snooze changes; one indexed scheduler query. Defaults: Assignment 1 day before, Bill 3 days, Event 30 minutes, Appointment same-day morning, Task none. Delivery defaults to the creator only; optional "Remind both of us" on Shared-Space records; snooze/dismiss is per member.

**Search (D12).** Exact match → trigram on titles/names (mild typo tolerance) → full-text on long content; ranked at the application layer; archived excluded by default (toggle), deleted always excluded, Restricted never previewed broadly, the other member's private content never present in any result or count. No general fuzzy tolerance promised; no unified index table until proven necessary.

**Archive / Trash / Recovery (D11, D23).** Archiving a Space touches only that Space's own `archived_at` — zero rewrites of contents. Archived Spaces and Trash are separate flows. Uniform 30-day Trash retention; deleted parents never orphan children — references stay intact, selectors exclude the deleted parent, restoring reconnects everything.

## 12. Data and Schema Approach

(Authoritative: *LifeOS-Technical-Handoff.md*; historical: Database-Schema-Design + its Final Audit.)

PostgreSQL; UUID primary keys; polymorphic `record_type` + `record_id` for cross-cutting tables (D16) with integrity enforced by the protected server-side write path (D17) — never by RLS alone — plus a weekly orphan-detection sweep as backup; real foreign keys for essential domain links; date-only values as dates (never midnight UTC); currency as fixed-precision decimal; every record workspace-anchored (D18).

**Migration order (13 stages, each with a paired down-migration; F2 placements included):** 1 identity/ownership + invitations → 2 organization incl. Space ownership and visibility → 3 core records → 4 school → 5 bills → 6 calendar/appointments → 7 inbox/provenance → 8 reminders + delivery targeting → 9 attachments → 10 cross-record systems incl. per-member daily priorities → 11 search indexes → 12 RLS policies → 13 seeded defaults.

## 13. Technical Architecture

(Authoritative: *LifeOS-Technical-Handoff.md* and *LifeOS-Implementation-Blueprint.md*.)

**Stack (all approved):** Next.js (TypeScript, App Router) · Tailwind CSS · shadcn/ui · Supabase (Auth, PostgreSQL, Storage; standard Auth email flow — P7-A) · Vercel · date-fns/date-fns-tz · React Hook Form + Zod · Tiptap (D20) · FullCalendar, free tier (D21) · Vitest/Playwright/axe-core · hosted error tracking, e.g. Sentry (D30 — technical diagnostics only, never private-record content). Starting point: the official Vercel `with-supabase` starter (App Router, cookie-based sessions via supabase-ssr, shadcn/ui initialized), stripped of demo content, with invited-account acceptance replacing default sign-up behavior for the second account.

**Responsibilities:** client renders/validates/navigates and may read its own permitted data under RLS; server performs every protected write, authoritative re-validation, multi-step transactions, jobs, and file authorization; database stores, constrains, and enforces RLS as the baseline boundary.

**Protected write services (D17 — the complete list, each a single transaction validating type-allowance, existence, non-deleted state, workspace match, authorization, duplicate/self-reference prevention, and visibility coherence):** polymorphic relationship/attachment/tag/reminder creation · Inbox conversion · permanent deletion · Bill Occurrence generation · payment recording · Appointment+Event paired creation/deletion · recurrence changes · invitation creation/revocation · member removal with P6-D transfers · Space visibility changes · (future) external sync.

**Background jobs (Supabase Scheduled Functions):** Bill Occurrence generation (daily) · reminder firing (every few minutes, one bounded delivery retry) · Trash expiration (daily; system action through the protected deletion service — C1) · polymorphic orphan detection (weekly) · audit maintenance (none in MVP; indefinite retention, D24).

**Error handling:** failed saves never clear input; all-or-nothing transactions; plain-language messages with retry; "changed elsewhere — reload" for conflicts; plain "you don't have access"; clear explanations for expired Trash items.

## 14. Security Model

- Layered authorization, in order: workspace membership → Space visibility → protected server writes → Privacy-Level filtering, the last two enforced via the single shared query-building helper (never per-screen logic).
- Release-blocking policy-test families: **cross-workspace access blocked** and **cross-visibility access blocked** — no path (queries, services, file URLs, search, counts, exports, error reports) may reveal another member's private content.
- Manual permanent deletion: Workspace-Owner-only for shared records; creator-only for private records. Closed sign-up verified by test. Files served only via server-checked short-lived signed URLs.
- The Prohibited list (Section 4) is verbatim binding.

## 15. Implementation Plan

(Authoritative: *LifeOS-Implementation-Blueprint.md* Sections 5–8, 14.)

**Phases:** Foundation slice (sign-up/auto-setup, sign-in, Dashboard shell, Spaces with ownership + visibility structures, title-only Tasks, soft deletion, baseline RLS with visibility enforcement, policy tests) → Quick Capture → Notes → Classes & Assignments → Bills → Calendar & Appointments → Reminders → Search → Files → Privacy → Invitation & two-member flows → final UX/accessibility/mobile pass. Each phase ends with a working, testable slice.

**Release milestones:** Alpha (foundation, policy tests green) → Beta (single-user complete, all must-have criteria) → v1.0 (two-member complete, every release-blocking test green, prohibited-terms sweep clean) → v1.1 (Agenda view).

**Definition of Done** (blueprint Section 14, per slice): approved behavior implemented or an approved ACR exists; service tests incl. failure/rollback; both policy-test families for new paths; Playwright on desktop + mobile; axe-core clean + keyboard works; no prohibited term/behavior; relevant simplicity criteria pass; numbered migrations with working down-migrations; failed saves preserve input; merged via PR with tests green.

**Workflow rules:** protected main, feature branches, small commits, PR checkpoints even solo, numbered migrations only, backups before production schema changes, rollback via down-migrations/Vercel; **inspect existing files before changing them; never replace working systems unnecessarily.**

## 16. Decision Quick Index

(One line each; full reasoning and sources in *LifeOS-Decision-Register.md*.)

D1 three-layer architecture · D2 Layer 3 has real fields, consumes Layer 1 · D3 Space/Project/Folder/Tag distinctions · D4 Event owns scheduling; Appointment links to one Event · D5 Bill vs. Occurrence, 90-day window, history never rewritten · D6 five Assignment statuses · D7 binary Task status · D8 Quick Capture requires explicit confirmation; Reminder is fallback type · D9 three Privacy Levels · D10 Restricted governed by deliberate intent · D11 archive ≠ trash; zero-rewrite archiving · D12 exact > trigram > full-text search · D13 materialized `next_fire_at` · D14 Bill reminder rules on definition, instances per Occurrence · D15 Appointment reminders live on the Event · D16 polymorphic `record_type`+`record_id` · D17 protected server-side writes; RLS insufficient alone · D18 workspace anchoring · D19 Projects/Folders soft-hidden · D20 Tiptap · D21 FullCalendar (free tier) · D22 Agenda view → v1.1 · D23 uniform 30-day Trash · D24 indefinite audit retention, never exposed · D25 no default Task reminder · D26 separate dated daily-priorities table · D27 Simplicity Standard, governing · D28 quiet Quick Capture lock; conversion raises privacy · D29 `ai_assisted` naming · D30 error tracking, diagnostics only · D31 the Privately Hosted two-member model (the amendment).

Amendment/final-review: C1 Trash expiration is a system action · C2 Space management is Space-Owner-only · P6-A removed Member's private records preserved invisibly · P6-B zero-leak to the Workspace Owner · P6-C Space-level visibility is the primary sharing model · P6-D removal transfers/preservation rules · P7-A Supabase Auth email · P8-A invisible cross-visibility links · P8-B both-visible structural references only · P8-C Appointment/Event same-Space invariant · P10-A personal Today's Priority · P10-B author-only Inbox · F6 attaching to Shared shares the File · F9 terminology standard · ACR freeze governance.

## 17. Glossary

**Workspace** — the invisible container anchoring all data; one per instance; the word never appears in the UI. **Workspace Owner** — the first account; invites/removes the Member; sole manual permanent-deleter of shared records. **Member** — the one invited account. **Space** — a lasting life area; the only organizational concept users must learn. **Space Owner** — a Space's creator; sole controller of its visibility and archival. **Private Space / Shared Space** — the two visibility states of a Space. **"Only me"** — record-level creator-only override inside Shared Spaces. **Privacy Level** — Standard/Sensitive/Restricted; a separate axis from visibility. **Privately Hosted** — deployed on the members' own accounts with sign-up closed. **Protected write** — a server-side, single-transaction operation (D17). **ACR** — Architecture Change Request, the only path to changing approved decisions.

## 18. Rules of Engagement for the Implementing AI

1. Read in the order given by *LifeOS-Document-Index.md*; this document first.
2. The approved documents are law. If code and a document would diverge, stop and raise it — as an ACR if architectural, as a question otherwise. Never silently resolve.
3. Never begin implementation of anything on the Deferred or Prohibited lists.
4. Every prohibited-list item, simplicity acceptance criterion, and both policy-test families are release blockers, not suggestions.
5. Inspect before changing; never replace working systems unnecessarily; migrations numbered and reversible; no manual database changes.
6. Use the F9 terminology standard everywhere.
7. When in doubt between two valid designs, choose the one that minimizes user decisions, cognitive load, and interface complexity (D27).

---

*End of Master Reference. Planning is complete; implementation has not begun.*
