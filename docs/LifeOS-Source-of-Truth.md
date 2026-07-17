# LifeOS Source of Truth
**Status of this file:** Condensed authoritative specification, compiled from all approved LifeOS planning documents and conformed (approved F7 update pass) to the approved Private-Hosting-and-Two-Person-Access-Amendment.md and LifeOS-Implementation-Blueprint.md — which, together with this compact package, form the complete authoritative planning set (approved F8). Planning is complete and frozen under the Architecture Change Request (ACR) process. Nothing described here has been built yet.

---

## Product Purpose
LifeOS is a personal operating system — one shared foundation for school life now and everyday life (bills, work, household, projects, goals) later — replacing multiple separate apps (task manager, notes, calendar, project tool) without ever needing a redesign after school ends.

## Simplicity and Ease-of-Use Standard (governing, non-negotiable)
LifeOS must be far easier to use than Notion or other open-ended tools. It is opinionated by default, ready to use immediately, guided rather than blank-canvas, calm, and beginner-friendly. It is **not** a database builder or block-based workspace tool. The powerful underlying architecture stays fully hidden from the user — no technical terms (database, schema, entity, polymorphic, foreign key, query, etc.) ever appear in the interface.

A first-time nontechnical user must be able to, without instructions: add a Task, add a Note, add a Class, add an Assignment, add a Bill, record a payment, add an Event, find an item, save a Quick Capture, and understand what's due today. Failure on any of these is a release blocker.

**Complexity budget rule:** no feature or control is added to a primary v1 flow unless it's necessary for the majority of users completing that flow.

## Target Users
A student who wants school (classes, assignments, notes, exams) and everyday life (tasks, bills, personal notes) managed in one place. v1 ships as a **Privately Hosted** instance for **exactly two trusted members** — a Workspace Owner and one invited Member — per the approved Private-Hosting-and-Two-Person-Access-Amendment.md (D31, **approved**). Sign-up is closed: the first account creates the workspace; the second account exists only via the Workspace Owner's invitation, delivered through the standard Supabase Auth email flow (P7-A). Collaboration beyond two members remains deferred and would require a new amendment.

## Two-Member Sharing Model (approved amendment, summarized)
The primary sharing boundary is the **Space**: every Space is **Private** (visible only to its Space Owner) or **Shared** (both members), set by one plain question. Records inherit their Space's visibility; inside Shared Spaces an optional record-level **"Only me"** override exists for occasional private items (scheduled "Only me" items render as a generic "Busy" block to the other member; Private-Space items show nothing at all). Visibility is a separate axis from Privacy Level (Standard/Sensitive/Restricted). Each Space has one Space Owner (its creator); only the Space Owner archives, reopens, or switches it Private↔Shared (with confirmation). Manual permanent deletion of shared records is Workspace-Owner-only; each member permanently deletes only their own private records; the automatic 30-day Trash job remains a system action through the protected deletion service. Removing the Member transfers their Shared Spaces to the Workspace Owner and preserves their private records invisibly (P6-A/P6-D); the Workspace Owner never sees counts, titles, previews, or hints of the Member's private content (P6-B). Cross-visibility links are allowed but the private end is completely invisible to the other member (P8-A). Full detail: Private-Hosting-and-Two-Person-Access-Amendment.md.

## MVP Features (v1.0)
Authentication, Spaces, Dashboard, Quick Capture Inbox, Tasks, Notes, Classes, Assignments, Bills, Calendar (Month/Week/Day), Reminders, basic Search, Contacts (introduced contextually, not as a standalone push).

## Explicitly Deferred Features
Full budgeting, bank connections, advanced grade forecasting, Vehicles, household inventory, health records, travel planning, multi-user/household collaboration beyond the approved two-member model, advanced AI actions, complex automations, offline sync, native mobile apps, Calendar Agenda view (→ v1.1).

## Core Architecture — Three Layers
1. **Layer 1 — Shared Platform Services** (built once, never duplicated): Authentication, Ownership/Permissions, Spaces, Tags, Typed Relationships, Search, Reminders, Notifications, Files & Attachments, Comments, Audit History, Import/Export, Calendar Sync, Soft Deletion & Recovery.
2. **Layer 2 — Universal Productivity Objects** (generic, reusable): Task, Note, Event, Project, File, Contact.
3. **Layer 3 — Specialized Domain Records** (structured fields, reuse Layer 1 services, never duplicate them): Class, Assignment, Exam, Grade Category, Bill, Bill Occurrence, Subscription, Income Entry, Budget Entry, Appointment, Goal, Vehicle, Vehicle Maintenance Record, Household Item, Document Renewal.

**Rule:** a Layer 3 record may have its own structured fields but must never build its own private Task/Note/Reminder/Search/File/Notification system — it links to Layer 2 objects and consumes Layer 1 services instead. Layer 3 records are **not required** to link to a Layer 2 object (e.g., a Vehicle can exist independently).

## Spaces, Projects, Folders, and Tags
- **Space** = a lasting area of life (School, Work, Personal, Finances, Household) — the only organizational concept a new user needs to learn.
- **Project** = a temporary, goal-bound container with start/target-completion dates (Kitchen Remodel, Moving). Projects **never** appear on the Calendar, generate reminders, appear in Dashboard due sections, or create notifications — only the records linked to them do.
- **Folder** = purely organizational; can nest inside a Space, a Project, or another Folder (exactly one parent, no circular nesting). Folders cannot own permissions, reminders, recurrence, AI behavior, dashboard widgets, notifications, or due dates.
- **Tag** = a lightweight, reusable, cross-cutting label.
- **v1 interface note:** Projects and Folders remain fully in the schema but are **soft-hidden** — absent from onboarding, primary navigation, default creation forms, and Quick Capture; discoverable only as secondary actions inside Space Detail. Tags are optional, surfaced only under "More options" or in filters.

## Main Record Types
Task, Note, Event, Project, File, Contact (Layer 2); Class, Assignment, Bill, Bill Occurrence, Appointment (Layer 3, v1-relevant subset). Class meeting times render from a recurrence schedule, never generate persisted Event rows.

## Dashboard Behavior
Sections (default visible): Today's Schedule, Overdue, Due Today, Due Soon, Quick Capture, Upcoming Bills. Hidden-by-default (togglable): Daily Priorities, Weekly Workload, Recent Notes, Recently Completed. Each member's Dashboard shows all Shared Spaces plus that member's own active Private Spaces — never the other member's Private Spaces (approved conforming amendment) — prioritized by urgency (date-driven), never by Space — this stays true before and after archiving School. Four distinct concepts never collapse into one another: **Priority** (general importance, user-set), **Today's Priority** (a day-scoped one-tap flag, resets naturally, stored in its own small dated table, personal to each member — P10-A), **Due Date** (the actual deadline), **Urgency** (Overdue/Due Today/Due Soon — purely date-computed, never Priority-influenced). Restricted records are excluded from every Dashboard section, including aggregate counts, unless the user has intentionally navigated to that specific record. Archived-Space content never appears, with no partial/summarized exception.

## Quick Capture and Inbox
Type freeform text, save instantly with zero required categorization. A background suggestion proposes the most specific applicable type (Task, Note, Assignment, Bill, or Appointment — never a bare standalone Reminder unless nothing more specific applies); the user must explicitly confirm before anything becomes a structured record. Converting marks the capture **Processed** (never deleted) and keeps a two-way link (`created_from` / `original_capture_id`) between the capture and the resulting record. Inbox captures are visible only to their author; visibility of the resulting record is determined at conversion by the destination Space (P10-B). A capture carries an optional, quiet privacy control (lock icon); it inherits the current Space's default privacy if opened in-context, and is automatically raised (never lowered) to match the resulting record's privacy at conversion.

## Tasks
Title required; everything else optional (description, due date/time, priority, Space/Project/Folder, tags, reminder, attachments, linked records, future-ready assignee). **Binary status only** (Incomplete/Complete) — never the five-state Assignment model.

## Notes
Freeform content; title optional at creation. Pinned/archived status supported. Autosave, always with a visible save-status indicator.

## Classes and Assignments
Class: name required; course code, term, instructor Contact, schedule, location, meeting link, color optional. Assignment: title + Class required; **five-state status** — Not Started, In Progress, Completed, Submitted, Graded — with a distinct official due date and personal target date, always kept as separate fields.

## Bills and Bill Occurrences
Bill (the recurring/one-time definition): name, expected amount, due date required; payee Contact, recurrence, automatic-payment status, payment-method label, account nickname, last-four-digits (never a full account/card number) optional. Bill Occurrence (a specific billing period): generated on a rolling 90-day-ahead window; historical occurrences are **never rewritten** by a recurrence-rule change — only future, eligible occurrences are affected, after confirmation. "Automatic payment" is purely informational, never implies a confirmed payment. **LifeOS records payments; it never sends them** — actions are always labeled "Mark Paid" / "Record Payment," never "Pay."

## Calendar, Events, and Appointments
Event owns all scheduling (date, time, duration, recurrence, location); Appointment owns appointment-specific info (purpose, provider, confirmation number, prep/follow-up notes) and links to exactly one Event. An Appointment and its Event always belong to the same Space with identical visibility; moving one automatically moves the other; an Appointment never exists without its Event — deleting an Appointment while keeping its Event unpairs that Event into a standalone Event, preserving the approved deletion-choice flow (P8-C). Deleting an Appointment does not cascade-delete its Event by default (user is offered the choice). Task/Assignment/Bill due dates are never duplicated as Events. Calendar shows Month/Week/Day only in v1 (Agenda view deferred to v1.1); every item is type-labeled; dragging a scheduled Event updates it directly (with Undo); dragging a due-date item requires explicit edit-and-confirm, never a silent change. Restricted scheduled items render as a generic "Busy" block unless deliberately opened.

## Contacts
A Layer 2 universal record: name, contact_type (Person, Organization, Service Provider, School, Medical Provider, Employer, Household Member, Other), phone, email, address, notes, tags, privacy, linked records. Never owns due dates/reminders/calendar presence. Structural references (Class→Instructor, Bill→Payee, Appointment→Provider) always use dedicated foreign keys, and on Shared records may reference only records visible to both members — invalid selections are simply never offered (P8-B); open-ended user associations use the generic relationship graph — never both for the same purpose.

## Search
Covers Spaces, Classes, Tasks, Notes, Assignments, Bills, Events, Appointments, Contacts, Files. Exact title match ranks highest, then trigram-based title/name matching (real substring matching plus mild typo tolerance), then full-text content matching. Archived content excluded by default (explicit include-toggle available); deleted content always excluded. Restricted records never show title/snippet/preview in broad results unless the current request is a deliberate, intentional access to that specific record; the other member's Private-Space and "Only me" content never appears in any result, suggestion, or count (amendment Part 10) — general typo/fuzzy tolerance beyond mild trigram similarity on titles is **not** promised.

## Reminders
One shared Reminder system across Task, Assignment, Bill, Event, Appointment — never a separate system per record type. Each reminder resolves to a concrete `next_fire_at`, recalculated whenever the record's date, the offset, the user's time zone changes, an occurrence generates, or the reminder is snoozed. Defaults: Assignment 1 day before, Bill 3 days before, Event 30 min before, Appointment same-day morning, **Task none (opt-in only)**. Bill reminders: the Bill definition stores default rules; each generated Occurrence gets its own actual scheduled reminder instance(s); paying an occurrence cancels its pending reminders. Appointment reminders live solely on the linked Event (no separate Appointment-level reminder channel), editable identically from Appointment Detail, Event Detail, or the Calendar entry. Reminders deliver by default only to their creator, with an optional "Remind both of us" control on Shared-Space records; one member's snooze/dismiss never affects the other's (amendment Part 5.5). In-app reminders are always the reliable fallback regardless of external push support.

## Files
Metadata/identity stored separately from the physical object (which lives in external storage, never as bytes in a database row). One File may attach to multiple records without duplicate uploads. Attaching a File to a Shared record is a deliberate sharing action for that File (approved F6) — intuitive, with no added confirmation dialog unless future testing proves one necessary. Downloads always go through an authorization check; Restricted files never appear in previews and are served only for deliberate, intentional access.

## Privacy Levels
Three levels: **Standard** (normal Search/Dashboard/AI eligibility), **Sensitive** (excluded from AI access by default, normal Search/Dashboard visibility), **Restricted** (excluded from AI access, broad Search previews, and Dashboard/widgets/suggestions unless the user intentionally navigates to or requests that specific record). Privacy Level is a separate axis from Space visibility (Private Space / Shared Space / "Only me"), which governs *who* can see a record (amendment Part 6.1). Privacy Level supplements — never replaces — ownership, authorization, row-level security, and encryption. Visibility is governed by **current, deliberate user intent**, not by any historical "viewed" timestamp or session boundary.

## Archive, Trash, and Recovery
**Archiving ≠ deleting.** Archiving a Space sets only that Space's own `archived_at` — contained records are never individually rewritten; their inactivity is derived by relationship to the archived Space, so reopening requires zero rewrites. **Archived Spaces** (reopen) and **Trash and Recovery** (restore a soft-deleted record) are two entirely separate destinations/flows. Uniform **30-day Trash retention** for all record types, showing deletion date, days remaining, Restore, and Permanently Delete. A deleted parent (Class, Contact, Project, Folder) never makes its children inaccessible — references stay intact, selectors exclude the deleted parent, and restoring it reconnects everything automatically.

## Ownership and Workspace Model
Every user-owned record is anchored to a `workspace`, not directly to a user — each Privately Hosted instance has exactly one workspace, with a Workspace Owner and at most one invited Member (amendment Parts 4 and 7); within it, Space-level Private/Shared visibility is the primary sharing boundary. The word "Workspace" never appears in the v1 interface. `assigned_to` exists structurally now (referencing the future membership model) but is unused in v1.

## Approved Schema Approach
UUID primary keys; PostgreSQL; polymorphic `record_type` + `record_id` references for cross-cutting concerns (tags, attachments, relationships, reminders, daily_priorities, audit_events) — chosen over a shared records registry as the simpler, more beginner-maintainable option, with integrity enforced by a **controlled server-side write path** (not by ordinary client inserts, and not solely by row-level security) plus scheduled orphan-detection sweeps as a backup, not the primary control. Essential domain links (Assignment→Class, Appointment→Event) always use real, dedicated foreign keys instead of the generic graph. Date-only values are stored as dates, never "midnight UTC"; only true timestamps use UTC-internal storage. Currency stored as fixed-precision decimal, never floating-point.

## Approved Technology Stack
Next.js + TypeScript + Tailwind CSS + shadcn/ui; Supabase (Authentication, PostgreSQL, Storage); Vercel deployment; date-fns/date-fns-tz; React Hook Form + Zod; Tiptap (rich-text editor — **approved, D20**); FullCalendar (free-tier features only — **approved, D21**); Vitest, Playwright, axe-core for testing; a hosted error-tracking service such as Sentry (**approved, D30** — technical diagnostics only, never private-record content); standard Supabase Auth email flow for invitations and password resets (**approved, P7-A**).

## Approved Simplicity Acceptance Criteria (release-blocking)
Task creation in one screen with only a title; Quick Capture opens in one tap/keystroke and saves with zero categorization; Assignment creation from a Class preselects that Class; Note creation from a Class prelinks it; Record Payment never uses bank-transfer language; Dashboard is useful with zero setup; a new user reaches the Dashboard in 3 or fewer onboarding steps; advanced fields hidden by default behind "More options"; Projects, Folders, relationship types, and system metadata never appear in ordinary flows; completing a Task / recording a payment / changing Assignment status are each one tap with Undo, not a confirmation dialog; the mobile Quick Capture button never overlaps other controls; the 10-action no-instructions ease-of-use test passes for a first-time nontechnical user.

## All Final Product Decisions
See **LifeOS-Decision-Register.md** for the complete, sourced list.
