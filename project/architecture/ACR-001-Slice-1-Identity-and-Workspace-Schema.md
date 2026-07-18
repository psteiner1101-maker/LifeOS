# ACR-001 — Slice 1: Identity and Workspace Schema

## 1. Status

**All 17 field-level decisions reviewed and approved by the project owner,
decision-by-decision, on 2026-07-17.** This document now reflects the
approved schema design for Slice 1. **Implementation remains gated:** no
migration, SQL, or application code may be written until the project owner
separately approves this finalized document and explicitly authorizes
implementation to begin (see Section 11).

## 2. Context

### 2.1 Why this ACR exists

The nine authoritative planning documents in `/docs` are a condensed,
approved package: `LifeOS-Source-of-Truth.md`, `LifeOS-Decision-Register.md`,
`LifeOS-MVP-Scope.md`, `LifeOS-Technical-Handoff.md`,
`LifeOS-Current-Status-and-Next-Step.md`, `LifeOS-Document-Index.md`,
`Private-Hosting-and-Two-Person-Access-Amendment.md`,
`LifeOS-Implementation-Blueprint.md`, and `LifeOS-Master-Reference.md`. These
documents describe _what_ LifeOS is, _why_ each product and architectural
decision was made, and _which stage_ each table belongs to in the 13-stage
migration order — but they are explicitly a compact summary, not the
field-level schema itself.

The actual field-level schema — `Database-Schema-Design.md` ("Full logical
schema: principles, entity inventory, ~27 table specs, identity pattern,
relationships, dates, bills, calendar, inbox, reminders, files, search,
privacy, archive, audit, indexes, retention, ERD, worked examples," per
`LifeOS-Document-Index.md`) and its correction layer,
`Database-Schema-Final-Audit-and-Simplicity-Amendment.md` — is confirmed
**permanently unavailable**. A full audit of this repository (every branch,
every commit, all git history) found neither document, nor any of the other
seven original historical planning documents, ever committed here. They are
referenced by name throughout the compact package as historical sources, but
were never physically present in this repository, and per the project
owner, the originals no longer exist anywhere.

### 2.2 Why deliberate reconstruction was required, rather than inference

Absent the original documents, someone implementing Slice 1 would otherwise
have had to _guess_ a large number of field-level specifics (exact columns,
types, constraints, indexes) to write real SQL. Under the Architecture
Freeze, an inferred guess must never quietly become permanent schema just
because it was convenient or plausible at implementation time — that would
be exactly the kind of silent architectural drift the Freeze exists to
prevent (`LifeOS-Master-Reference.md` §2: _"No document may silently change
an approved decision. No recommendation becomes a rule without the user's
explicit approval."_).

This ACR was the deliberate, visible alternative: every proposed field,
constraint, and behavior was traced to its actual source, labeled
**Explicitly sourced**, **Derived**, or **New architecture decision**, and
walked through the project owner one decision at a time — 17 decisions in
total — each with its options, tradeoffs, a recommendation, a sourcing
classification, and an explicit approval before moving to the next. Every
decision below reflects that review, not unilateral inference.

### 2.3 Scope

This ACR covers **only** the five Slice 1 / migration-stage-1 tables named
in `LifeOS-Technical-Handoff.md` "Migration Order": `profiles`, `workspaces`,
`workspace_members`, `user_settings`, `invitations`. It does not touch
Spaces, Private/Shared visibility, or any later-stage table — those remain
scoped to their own future slices and, if the same unavailability problem
recurs, their own ACRs.

## 3. Binding Existing Decisions

These are the requirements this ACR must not contradict, with exact
citations. Every approved decision in Section 5 traces back to one or more
of these.

| #   | Decision                                                                                                                                                                                                                                                            | Citation                                                                                       |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| B1  | Every user-owned record anchors to a `workspace`, not to a user; the word "workspace" never appears in the UI.                                                                                                                                                      | `LifeOS-Source-of-Truth.md` "Ownership and Workspace Model"; `LifeOS-Decision-Register.md` D18 |
| B2  | `workspaces` + `workspace_members` are created at sign-up now (one owner row), fully hidden from the v1 UI.                                                                                                                                                         | `LifeOS-Decision-Register.md` D18                                                              |
| B3  | Sign-up creates, in one transaction: Auth user (Supabase), profile, workspace, one owner `workspace_members` row, and `user_settings` with approved defaults.                                                                                                       | `LifeOS-Technical-Handoff.md` "Authentication & Workspace Setup"                               |
| B4  | Partial sign-up failure → plain-language retry, Auth user preserved for re-attempt, monitored error logged.                                                                                                                                                         | `LifeOS-Technical-Handoff.md` "Authentication & Workspace Setup"                               |
| B5  | Profiles and `user_settings` are already per-user, not per-workspace — two members having different time zones, notification preferences, and defaults requires no restructuring.                                                                                   | Amendment Part 3, item 4                                                                       |
| B6  | Exactly two membership roles: Workspace Owner (created the workspace, fixed, ownership transfer out of scope) and Member. Hard maximum of two members per workspace; no third member, ever, under this amendment.                                                   | Amendment Part 4.1; Part 1.1; Part 2.3                                                         |
| B7  | Invitation lifecycle: invite (Owner-only, one at a time, only while the workspace has one member) → deliver → accept → expire/revoke → remove → re-invite.                                                                                                          | Amendment Part 4.2                                                                             |
| B8  | Invitation acceptance is a single transaction: Auth user, profile, a Member row in the existing `workspace_members`, and personal `user_settings` with approved defaults; the invitation is consumed atomically so a link can never be accepted twice.              | Amendment Part 7.2                                                                             |
| B9  | Closed sign-up: after the first account, public registration is disabled; the second account exists only via a valid, unexpired, unrevoked invitation link.                                                                                                         | Amendment Part 7.1                                                                             |
| B10 | Removal ends the Member's access immediately but destroys no data; the removed Member's private records are preserved and invisible (P6-A); Member-owned Shared Spaces transfer to the Workspace Owner (P6-D).                                                      | Amendment Part 4.2 point 5; Part 6.6; Approval Record P6-D                                     |
| B11 | RLS baseline: any workspace member may read/insert/update/soft-delete within their own workspace; RLS is never the sole integrity control — protected server-side writes are required for polymorphic/multi-step operations (D17).                                  | `LifeOS-Technical-Handoff.md` "Row-Level-Security Approach"; `LifeOS-Decision-Register.md` D17 |
| B12 | Authorization is layered: workspace membership → Space visibility → protected server-side writes → privacy-level filtering.                                                                                                                                         | `LifeOS-Implementation-Blueprint.md` §2; Amendment Part 8.1                                    |
| B13 | Every protected server-side write validates: record-type allowance, target existence, non-deleted state, matching workspace on all sides, authorization, visibility coherence, and duplicate/self-reference prevention — inside a single transaction per operation. | `LifeOS-Technical-Handoff.md` "Protected Write Services"; Amendment Part 8.4                   |
| B14 | Invitation creation/revocation and member removal are protected server-side operations (membership-mutating, audit-relevant), Owner-only, each a single transaction, each audit-recorded.                                                                           | Amendment Part 8.6                                                                             |
| B15 | UUID primary keys; PostgreSQL; date-only values stored as dates, never midnight UTC; only true timestamps use UTC-internal storage; currency as fixed-precision decimal (not relevant to these 5 tables, but the general schema-approach rule).                     | `LifeOS-Source-of-Truth.md` "Approved Schema Approach"                                         |
| B16 | Numbered, ordered migrations only, each with a paired down-migration; no manual database changes; backups before any production schema change.                                                                                                                      | `LifeOS-Technical-Handoff.md` "Git Workflow"; `LifeOS-Implementation-Blueprint.md` §9          |
| B17 | Sessions via Supabase httpOnly cookies; route protection via shared middleware; the word "Workspace" never appears in the UI.                                                                                                                                       | `LifeOS-Technical-Handoff.md` "Authentication & Workspace Setup"                               |
| B18 | `assigned_to` exists structurally (on Task, a later-stage table) but is unused in v1 — not relevant to these 5 tables directly, cited here only to confirm no analogous column is implied for `workspace_members`.                                                  | `LifeOS-Source-of-Truth.md` "Ownership and Workspace Model"                                    |
| B19 | Audit events record every meaningful operation with an acting user; never exposed in the normal UI (D24). The `audit_events` table itself belongs to migration stage 10, not stage 1.                                                                               | Amendment Part 3, item 5; `LifeOS-Technical-Handoff.md` "Migration Order"                      |
| B20 | Uniform 30-day Trash retention "for all record types" (D23) — stated in the context of user-content records (Archive/Trash/Recovery); never explicitly extended to or excluded from identity/ownership tables.                                                      | `LifeOS-Source-of-Truth.md` "Archive, Trash, and Recovery"; `LifeOS-Decision-Register.md` D23  |

## 4. Approved Tables

Every column below is tagged **[Sourced]**, **[Derived]**, or **[New
architecture decision]**, reflecting the outcome of the 17-decision review
in Section 5. Nothing below is inferred or unresolved.

### 4.1 `profiles`

**Purpose [Sourced — B1, B3, B5]:** the per-user identity record created at
sign-up, holding personal identity distinct from the workspace. Time zone
and other preferences live on `user_settings` (Decision 13), not here.

| Column       | Type          | Nullable | Default | Status                                                                                                                          |
| ------------ | ------------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `id`         | `uuid`        | not null | —       | **[New architecture decision — Decision 1]** equals `auth.users.id` directly (shared PK); no separate `profiles.user_id` column |
| `created_at` | `timestamptz` | not null | `now()` | **[Derived]**                                                                                                                   |
| `updated_at` | `timestamptz` | not null | `now()` | **[New architecture decision — Decision 12]** trigger-maintained                                                                |

**Primary key:** `id`.
**Foreign keys:** `id` → `auth.users.id`.
**Unique constraints:** none beyond the primary key.
**Check constraints:** none.
**Indexes:** none beyond the primary key.
**Delete behavior:** no deletion mechanism in Slice 1 — **[Derived —
Decision 9]**; no approved account-deletion feature exists yet. Any future
account-deletion feature requires its own ACR.
**Update behavior:** self-only.
**Ownership and access model:** a user owns and may read/update only their
own row — **[Derived from B5, B11]**.
**Soft deletion:** does not apply — **[Derived — Decision 9]**.
**Timestamps:** `created_at`/`updated_at`, the latter trigger-maintained
(Decision 12).
**RLS expectation (intent only, no policy syntax):** self-row read/update —
**[Derived from B5 and B11]**.

**Deliberately not included, per approved decisions:** `display_name`
(Decision 14 — no friendly display name is stored in Slice 1; where a
human identifier is needed, the authenticated user's email from
`auth.users` may be used until a future approved feature introduces a
separate profile naming model); `time_zone` (Decision 13 — lives on
`user_settings`); `created_by`/`updated_by` (Decision 10 — a profile's
creator is trivially its own subject).

### 4.2 `workspaces`

**Purpose [Sourced — B1, B2]:** the single invisible container anchoring
every Space and record for one Privately Hosted instance.

| Column       | Type          | Nullable | Default             | Status                                                           |
| ------------ | ------------- | -------- | ------------------- | ---------------------------------------------------------------- |
| `id`         | `uuid`        | not null | `gen_random_uuid()` | **[Sourced — B15]** UUID PK                                      |
| `created_at` | `timestamptz` | not null | `now()`             | **[Derived]**                                                    |
| `updated_at` | `timestamptz` | not null | `now()`             | **[New architecture decision — Decision 12]** trigger-maintained |

**Primary key:** `id`.
**Foreign keys:** none at this table's own level.
**Unique constraints:** none.
**Check constraints:** none.
**Indexes:** none beyond the primary key.
**Delete behavior:** no deletion mechanism proposed in Slice 1 — no document
describes a workspace ever being deleted.
**Update behavior:** no update path defined in Slice 1 beyond the
trigger-maintained `updated_at`.
**Ownership and access model:** a user may read the workspace row(s) they
belong to via `workspace_members` — **[Derived from B1, B11]**. Ownership
itself is represented **only** via `workspace_members.role = 'owner'` —
**[Sourced — B2, D18, Amendment Part 2.1]** for the underlying model;
**[Derived — Decision 3]** for the deliberate choice not to also add a
`workspaces.owner_user_id` column, avoiding two sources of truth.
**Soft deletion:** does not apply — **[Derived — Decision 9]**.
**Timestamps:** `created_at`/`updated_at`, the latter trigger-maintained
(Decision 12).
**RLS expectation:** member-of-workspace read only; no client-side insert
policy (creation happens only through the protected sign-up service, B3) —
**[Derived from B11, B13]**.

**Deliberately not included, per approved decisions:** `owner_user_id`
(Decision 3); a `name` field (never sourced anywhere; the word "Workspace"
never appears in the UI at all, per B1/B17).

### 4.3 `workspace_members`

**Purpose [Sourced — B1, B2, B3, B6]:** the join table expressing who
belongs to a workspace, in what role, and their current standing (active or
removed).

| Column         | Type          | Nullable | Default             | Status                                                                                                                                                                     |
| -------------- | ------------- | -------- | ------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `id`           | `uuid`        | not null | `gen_random_uuid()` | **[Derived — Decision 15]** surrogate primary key                                                                                                                          |
| `workspace_id` | `uuid`        | not null | —                   | **[Sourced — B1, B2]**                                                                                                                                                     |
| `user_id`      | `uuid`        | not null | —                   | **[Sourced — B1, B2]**                                                                                                                                                     |
| `role`         | `text`        | not null | —                   | **[Sourced — B6]** two-role model; **[New architecture decision — Decision 4]** stored as lowercase machine tokens (`'owner'`, `'member'`), independent of UI display copy |
| `status`       | `text`        | not null | `'active'`          | **[Derived — Decision 5]** `'active'` / `'removed'`; retained with a status rather than hard-deleted on removal                                                            |
| `created_at`   | `timestamptz` | not null | `now()`             | **[Derived]**                                                                                                                                                              |
| `updated_at`   | `timestamptz` | not null | `now()`             | **[Derived — Decision 12]** added as a required consequence of `status` becoming mutable (Decision 5); trigger-maintained                                                  |

**Primary key:** `id` — **[Derived — Decision 15]**, not composite.
**Foreign keys:** `workspace_id` → `workspaces.id`; `user_id` → `profiles.id`.
**Unique constraints:**

- `UNIQUE (workspace_id, user_id)` — **[Derived — Decision 5]**: exactly one
  row ever exists per user/workspace pair, for the lifetime of that
  relationship; re-inviting a previously removed person to the _same_
  workspace reactivates their existing row (`status: 'removed' → 'active'`)
  rather than inserting a new one.
- Partial unique index `UNIQUE (user_id) WHERE status = 'active'` —
  **[Derived — Decisions 2 & 5]**: a user may have at most one _active_
  workspace membership at a time, globally. (Originally proposed as a
  blanket constraint in Decision 2; refined to this partial form in
  Decision 5 so a removed member isn't permanently blocked from
  re-invitation.)

**Check constraints:**

- Named constraint on `role`: `CHECK (role IN ('owner', 'member'))` —
  **[New architecture decision — Decision 16]**.
- Named constraint on `status`: `CHECK (status IN ('active', 'removed'))` —
  **[New architecture decision — Decision 16]**.

Both are plain `text` + `CHECK`, not native Postgres `ENUM` types or
`domain`s — chosen for migration simplicity and ease of future change
(Decision 16).

**Indexes:** `(workspace_id)`, `(user_id)` — **[Derived]** — the hottest
lookup path in the schema, since every future RLS policy joins through this
table.
**Delete behavior:** rows are never hard-deleted on removal —
**[Derived — Decision 5]**. Removal sets `status = 'removed'`.
**Update behavior:** `status` transitions (`active` ↔ `removed`) via
protected services only (B14); `updated_at` is trigger-maintained
(Decision 12) and records only the most recent modification, not full
history — detailed removal/reactivation history belongs in `audit_events`
once that stage-10 table exists.
**Ownership and access model:** both members may read membership rows for
their own workspace — roster visibility is not "private content" under
P6-B, which concerns record _content_, not membership existence —
**[Derived]**; no client-side write path — all mutations via protected
services (B3, B8, B14).
**Soft deletion:** does not apply in the D23 Trash/Restore sense —
**[Derived — Decision 9]**; the `active`/`removed` status is this table's
own purpose-built lifecycle mechanism, not generic soft-delete.
**Timestamps:** `created_at`, `updated_at` (trigger-maintained, Decision 12).
**RLS expectation:** member-of-same-workspace read; zero client
insert/update/delete — **[Derived from B11, B13, B14]**.

**Two-member-limit enforcement [Sourced cap — B6; Derived enforcement
mechanism — Decision 11]:** enforced in **both** layers:

1. **Service layer (primary):** the invitation-acceptance protected service
   checks the workspace's active-member count before activating or
   creating a membership row, and returns a clear, user-friendly message
   when the workspace is already full.
2. **Database trigger (backstop):** rejects any insert or update —
   including reactivation from `'removed'` to `'active'`, not only new
   inserts — that would result in more than 2 rows with `status = 'active'`
   for a given `workspace_id`. Raises a stable, identifiable error the
   service layer can catch and translate into the same user-friendly
   message. Must be concurrency-safe, so two simultaneous acceptance
   attempts cannot both succeed and create a third active member. The
   exact concurrency/locking strategy (e.g., row-level locking vs. a
   constraint-trigger approach) is an implementation detail and is
   intentionally not prescribed by this ACR.

This mirrors D17's own established precedent (RLS/DB constraints are the
baseline, never the sole integrity control) applied to this non-polymorphic
but structurally similar write-time business rule.

### 4.4 `user_settings`

**Purpose [Sourced — B3, B5]:** per-user settings, created with defaults at
sign-up/acceptance, owning the user's time zone and governing other
personal preferences.

| Column       | Type               | Nullable | Default | Status                                                                                                                                                                   |
| ------------ | ------------------ | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `user_id`    | `uuid`             | not null | —       | **[Derived]** primary key — one row per user                                                                                                                             |
| `time_zone`  | `text` (IANA name) | not null | —       | **[Derived — Decision 13]** owned here, not on `profiles`; exact defaulting strategy at sign-up time left open for later definition (not settled in any source document) |
| `created_at` | `timestamptz`      | not null | `now()` | **[Derived]**                                                                                                                                                            |
| `updated_at` | `timestamptz`      | not null | `now()` | **[New architecture decision — Decision 12]** trigger-maintained                                                                                                         |

**Primary key:** `user_id`.
**Foreign keys:** `user_id` → `profiles.id`.
**Unique constraints:** none beyond the primary key.
**Check constraints:** none proposed.
**Indexes:** none beyond the primary key.
**Delete behavior:** cascade with `profiles` — **[Derived]** — settings are
meaningless without the profile. No independent deletion mechanism in
Slice 1 (Decision 9).
**Update behavior:** self-only. Changing a user's time zone never alters
`profiles` (Decision 13) — the two tables stay independent.
**Ownership and access model:** a user owns and may read/update only their
own row — **[Derived from B5, B11]**.
**Soft deletion:** does not apply — **[Derived — Decision 9]**.
**Timestamps:** `created_at`/`updated_at`, the latter trigger-maintained
(Decision 12).
**RLS expectation:** self-row read/update — **[Derived]**.

**What remains open, deliberately:** "notification preferences" and other
"defaults" named only abstractly in Amendment Part 3 item 4 are not given
concrete columns here — nothing beyond `time_zone` was sourced with enough
specificity to schema during this review. Reminder delivery targeting (the
"Remind both of us" control, Amendment Part 5.5) is a _per-record_ setting
belonging to the reminders table (migration stage 8), not `user_settings`.
Additional `user_settings` columns, if needed, are additive and can be
introduced without revisiting this ACR.

### 4.5 `invitations`

**Purpose [Sourced — B6, B7, B8, B9]:** the record of an outstanding or
resolved invitation from the Workspace Owner to a prospective Member.

| Column          | Type          | Nullable | Default                          | Status                                                                                                                                                                                                       |
| --------------- | ------------- | -------- | -------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `id`            | `uuid`        | not null | `gen_random_uuid()`              | **[Derived]**                                                                                                                                                                                                |
| `workspace_id`  | `uuid`        | not null | —                                | **[Sourced — B7]**                                                                                                                                                                                           |
| `invited_email` | `text`        | not null | —                                | **[Sourced — B7]** ("the Owner... enters the invitee's email address")                                                                                                                                       |
| `token_hash`    | `text`        | not null | —                                | **[New architecture decision — Decision 6]** deterministic HMAC-SHA-256 digest of the invitation token, using a server-only secret; field renamed from `token` to `token_hash` so its purpose is unambiguous |
| `status`        | `text`        | not null | `'pending'`                      | **[Derived — Decision 8]** `'pending'` / `'accepted'` / `'revoked'` / `'expired'`                                                                                                                            |
| `created_by`    | `uuid`        | not null | —                                | **[Derived — Decision 10]** references `profiles.id`; the inviting user; immutable after creation                                                                                                            |
| `created_at`    | `timestamptz` | not null | `now()`                          | **[Derived]**                                                                                                                                                                                                |
| `updated_at`    | `timestamptz` | not null | `now()`                          | **[Derived — Decision 8, formalized by Decision 12]** trigger-maintained; captures revocation/expiration timing, not just acceptance                                                                         |
| `expires_at`    | `timestamptz` | not null | `created_at + interval '7 days'` | **[New architecture decision — Decision 7]** 7-day default window                                                                                                                                            |
| `accepted_at`   | `timestamptz` | nullable | `null`                           | **[Derived]**                                                                                                                                                                                                |

**Primary key:** `id`.
**Foreign keys:** `workspace_id` → `workspaces.id`; `created_by` →
`profiles.id`.
**Unique constraints:**

- Partial unique index on `workspace_id` where `status = 'pending'` —
  **[Derived from B7]** ("At most one invitation may exist at a time").
- Unique constraint on `token_hash` — **[Derived]** — needed for the
  acceptance lookup to be unambiguous.

**Check constraints:** named constraint on `status`:
`CHECK (status IN ('pending', 'accepted', 'revoked', 'expired'))` —
**[New architecture decision — Decision 16]**, plain `text` + `CHECK`, not
`ENUM`/`domain`.
**Indexes:** `(workspace_id)`, `(token_hash)` — **[Derived]**.
**Delete behavior:** rows are never hard-deleted — **[Derived — Decision
8]**; revoked and expired invitations remain queryable for history and
auditing.
**Update behavior:** `status`/`accepted_at`/`updated_at` transitions per the
protected service (B8, B14) — never a direct client write. `created_by` is
immutable once set and must **never** be inferred later from the
workspace's current Owner — a future ownership change could make that
inference historically inaccurate (explicit requirement from Decision 10).
**Ownership and access model:** Workspace-Owner-only read/write (Amendment
Part 4.1: only the Owner can invite) — **[Sourced]**. The invitee, having no
account yet, cannot be reached by any RLS policy at all — acceptance must
be a token-validating protected service call, not a client-side read —
**[Derived from B8, B13]**.
**Soft deletion:** does not apply in the D23 sense — **[Derived — Decision
9]**; the `status` field already models this table's lifecycle.
**Timestamps:** `created_at`, `updated_at`, `expires_at`, `accepted_at` —
all **[Derived]**, with `expires_at`'s 7-day default value being a **[New
architecture decision — Decision 7]**.
**RLS expectation:** Owner-only, scoped to their own workspace —
**[Sourced from Amendment Part 4.1]**.

**Invitation token security design [New architecture decision — Decision
6], fully specified:**

- A cryptographically secure, high-entropy random token is generated at
  invitation creation.
- The raw token appears **only** in the invitation link — it is never
  logged and is unrecoverable after creation.
- The database stores **only** a deterministic HMAC-SHA-256 digest of the
  token, computed with a server-only secret (not a per-token random salt,
  since the acceptance service must re-derive the identical digest from
  the presented token to perform a direct lookup).
- Digest comparison uses constant-time comparison where applicable.
- The stored digest is never exposed to the client.

**Invitation expiration [New architecture decision — Decision 7]:**

- `expires_at = created_at + 7 days` by default.
- Expiration is evaluated server-side; expired invitations can never be
  accepted.
- The Owner may revoke an invitation before it expires.
- A new invitation may be issued after expiration, subject to the
  one-pending-invitation rule.
- Changing this default duration in the future affects only newly created
  invitations, unless a separate migration explicitly recalculates
  existing rows.

## 5. Approved Decisions

All 17 decisions below were reviewed individually with the project owner —
plain-English statement, why it matters, available options, tradeoffs,
recommendation, sourcing classification, and ease-of-later-change — and
explicitly approved before the next was presented. This section is the
permanent record of that review.

| #   | Decision                                                                                   | Approved outcome                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 | Classification                                                                                                                                          | Ease of later change                                      |
| --- | ------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------- |
| 1   | Does `profiles.id` equal `auth.users.id`?                                                  | **Yes — shared PK; no separate `profiles.user_id` column.**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      | New architecture decision                                                                                                                               | Difficult (touches every downstream foreign key)          |
| 2   | May a user belong to more than one workspace?                                              | **No — enforced via a constraint on `workspace_members` (refined by Decision 5 into a partial unique index).**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | Derived (Amendment Part 2.2, Part 12.1, Part 1.2)                                                                                                       | Moderate                                                  |
| 3   | Is ownership represented only via `workspace_members`, or also `workspaces.owner_user_id`? | **`workspace_members.role = 'owner'` only; no `owner_user_id` column.**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          | Ownership-via-membership-row: Explicitly sourced (D18, Amendment Part 2.1). Omission of a duplicate column: Derived                                     | Easy                                                      |
| 4   | Exact allowed `role` values                                                                | **`'owner'`, `'member'` — lowercase machine tokens, independent of UI display copy.**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | Two-role model: Explicitly sourced (Amendment Part 4.1, 1.1, 2.3). Exact lowercase representation: New architecture decision                            | Easy                                                      |
| 5   | Are removed members deleted or retained with a status?                                     | **Retained: `workspace_members.status` = `'active'` / `'removed'`. Decision 2's constraint refined to a partial unique index (`user_id` WHERE `status='active'`). New blanket `UNIQUE(workspace_id, user_id)` added — one row per user/workspace pair ever; re-invitation reactivates the existing row.**                                                                                                                                                                                                                                                                                                                        | Derived (Amendment Part 4.2, P6-D, B14)                                                                                                                 | Moderate                                                  |
| 6   | Invitation token storage and hashing                                                       | **HMAC-SHA-256 digest with a server-only secret, stored in a renamed `token_hash` column; raw token never stored, logged, or recoverable; constant-time comparison; digest never exposed to client.**                                                                                                                                                                                                                                                                                                                                                                                                                            | New architecture decision                                                                                                                               | Easy                                                      |
| 7   | Invitation expiration duration                                                             | **7 days from creation (`expires_at = created_at + 7 days`), evaluated server-side.**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            | Existence of a window: Explicitly sourced (Amendment Part 4.2). The 7-day value: New architecture decision                                              | Easy                                                      |
| 8   | Invitation revocation behavior                                                             | **Status transition `pending → revoked` (not a delete); revoked invitations never acceptable, remain queryable; `invitations.updated_at` added; revoked invitations no longer count toward the one-pending rule.**                                                                                                                                                                                                                                                                                                                                                                                                               | Derived (Amendment Part 4.2)                                                                                                                            | Easy                                                      |
| 9   | Do identity tables support Trash/Restore?                                                  | **No — all five Slice 1 tables excluded from D23's generic Trash/Restore; no `deleted_at` added to any of them; `profiles`/`workspaces`/`user_settings` have no deletion mechanism in Slice 1 (no approved account/workspace-deletion feature exists); any future one requires its own ACR.**                                                                                                                                                                                                                                                                                                                                    | Derived (D23/Amendment Part 5.4 scoped to content records; the approved status lifecycles; absence of any approved identity-deletion feature)           | Easy                                                      |
| 10  | Are `created_by`/`updated_by` columns required?                                            | **Only `invitations.created_by` (required, references `profiles.id`, immutable, never to be inferred from the workspace's current Owner). No `updated_by` on `invitations`. None on `profiles`, `workspaces`, `workspace_members`, `user_settings`.**                                                                                                                                                                                                                                                                                                                                                                            | Derived (audit-relevance of invitations per B14; value of preserving historical attribution)                                                            | Easy                                                      |
| 11  | Trigger or service-layer enforcement of the two-member limit?                              | **Both: service-layer check is primary (user-friendly messaging); database trigger is a concurrency-safe backstop covering both inserts and reactivation. Decision 5's partial unique index on `user_id` remains separately.**                                                                                                                                                                                                                                                                                                                                                                                                   | Two-member cap: Explicitly sourced (B6). Dual-layer enforcement: Derived (D17 defense-in-depth pattern)                                                 | Moderate                                                  |
| 12  | Is `updated_at` trigger-maintained?                                                        | **Yes — one shared, reusable trigger function across all five tables; client-supplied values never override it; `workspace_members.updated_at` added as a required consequence of Decision 5. Each table's `updated_at` reflects only changes to that row itself — it is never touched by changes to a related row in another table (e.g., a Workspace's `updated_at` does not change when one of its `workspace_members` rows changes).**                                                                                                                                                                                       | Adding `workspace_members.updated_at`: Derived (from the approved mutable lifecycle). Trigger-maintained `updated_at` itself: New architecture decision | Easy                                                      |
| 13  | Where is time zone stored?                                                                 | **`user_settings`, not `profiles`; changing it never alters profile identity; exact sign-up defaulting strategy left open for later definition.**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | Derived (Amendment Part 3 item 4 groups it with `user_settings`)                                                                                        | Moderate                                                  |
| 14  | Are profile display names required?                                                        | **No friendly display name is stored in Slice 1 — no `display_name` field exists. Where a human identifier is needed, the authenticated user's email from `auth.users` may be used until a future approved feature introduces a separate profile naming model. No onboarding step added.**                                                                                                                                                                                                                                                                                                                                       | New architecture decision (absence of a sourced v1 requirement; D27 complexity budget)                                                                  | Easy                                                      |
| 15  | Surrogate or composite PK for `workspace_members`?                                         | **Surrogate `id` (uuid); not composite.**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        | Derived (existing UUID-PK convention; simpler future foreign-key references)                                                                            | Easy now; Difficult once referenced elsewhere             |
| 16  | `ENUM`, `text` + `CHECK`, or `domain`?                                                     | **`text` + named `CHECK` constraints for `workspace_members.role`, `workspace_members.status`, `invitations.status`; no `ENUM` types, no `domain`s; stored values remain lowercase machine tokens; app TypeScript unions may mirror them, but the database `CHECK` constraints are the source of truth.**                                                                                                                                                                                                                                                                                                                        | New architecture decision (migration simplicity, ease of future change)                                                                                 | Easy                                                      |
| 17  | One combined migration or five separate files?                                             | **Five separate, small, focused migration files in dependency order (`profiles` → `workspaces` → `workspace_members` → `user_settings` → `invitations`), each with a paired down-migration; shared functions (e.g., the `updated_at` trigger function) live in the earliest migration where they have no unmet dependencies, and are dropped only in the final down-migration after all dependent triggers are removed; the two-active-member concurrency-safe trigger lives with the `workspace_members` migration; treated as one reviewed Slice 1 migration set despite being five independently readable/reversible files.** | New architecture decision (reviewability, dependency clarity, this project's established small-change discipline)                                       | N/A — a file-organization choice for work not yet written |

## 6. Security Model

_(Intent only — no executable RLS policies are written here, per
instruction.)_

- **Authentication boundary [Sourced — B17]:** Supabase Auth is the sole
  identity provider; sessions are httpOnly cookies; route protection is
  shared middleware. Nothing in Slice 1 changes this boundary.
- **Workspace access boundary [Sourced — B11, B12]:** the first
  authorization layer for every table here is "does this user have an
  _active_ `workspace_members` row for this `workspace_id`?" This is the
  literal foundation the rest of the layered model (Space visibility,
  protected writes, privacy levels) builds on in later slices.
- **Owner permissions [Sourced — B6, Amendment Part 4.1]:** invite/revoke,
  remove the Member, permanently delete shared records (out of scope for
  Slice 1's own tables, relevant to later slices), read/write `invitations`
  for their workspace.
- **Member permissions [Sourced — Amendment Part 4.1]:** full ordinary use
  within visibility rules (not yet built in Slice 1); cannot invite, cannot
  remove the Owner; may read (not write) `workspace_members` rows in their
  own workspace (roster visibility).
- **Invitation permissions [Sourced — Amendment Part 4.1, 8.6]:**
  Owner-only for every operation on `invitations`; the invitee has no
  standing permission at all until their account exists.
- **Service-role-only operations [Derived from B3, B8, B13, B14]:** creating
  a `workspaces` row, creating/mutating any `workspace_members` row,
  creating/mutating any `invitations` row — all of these happen only inside
  a protected server-side transaction, never as an ordinary authenticated
  client write. `profiles` and `user_settings` are the exception: their
  _self_-row `UPDATE` (e.g., changing one's own time zone) is intended to
  be an ordinary RLS-scoped client write per `LifeOS-Technical-Handoff.md`'s
  "Client... may make simple single-field edits to a record it owns
  directly."
- **RLS policy intent (not policy syntax):**
  - `profiles`: self-row `SELECT`/`UPDATE`.
  - `workspaces`: member-of-workspace `SELECT`; no client `INSERT`.
  - `workspace_members`: member-of-same-workspace `SELECT`; no client
    `INSERT`/`UPDATE`/`DELETE`.
  - `user_settings`: self-row `SELECT`/`UPDATE`.
  - `invitations`: Owner-of-workspace `SELECT`/`INSERT`/`UPDATE`; no policy
    can reach the invitee pre-acceptance (see Section 7).
- **Operations requiring server-side authorization in addition to RLS
  [Sourced — B11, B13]:** every write to `workspaces`, `workspace_members`,
  and `invitations` — RLS is explicitly "never the sole integrity control"
  (D17) for anything beyond a simple self-row edit, and none of these three
  tables' writes are simple self-row edits. The two-active-member limit
  additionally requires the dual-layer enforcement specified in Decision 11
  and Section 4.3.

## 7. Sign-Up Transaction

**Atomic sequence [Sourced — B3, B4]:**

1. Create the Supabase Auth user.
2. Create the `profiles` row (`id` = the new Auth user's id, per Decision 1).
3. Create the `workspaces` row.
4. Create the owner `workspace_members` row (`workspace_id` = the new
   workspace, `user_id` = the new profile, `role = 'owner'`,
   `status = 'active'`).
5. Create the `user_settings` row with approved defaults (`user_id` = the
   new profile), including an initial `time_zone` (exact defaulting
   strategy left open per Decision 13).

All five steps are one transaction. **[Sourced — B3]** explicitly: "Sign-up
creates, in one transaction: Auth user (Supabase), profile, workspace, one
owner `workspace_members` row, and `user_settings` with approved defaults."

**Invitation-acceptance variant [Sourced — B8]:** identical shape, except
step 3 is replaced by looking up the _existing_ workspace via the
invitation's `workspace_id`, and step 4 either creates a `role = 'member'`,
`status = 'active'` row, or — if this person was previously a member of
this same workspace and was removed — **reactivates their existing
`workspace_members` row** (`status: 'removed' → 'active'`) per Decision 5,
rather than inserting a new one. The `invitations` row's `status`
transitions to `'accepted'` (and `accepted_at` is set) inside the same
transaction, so "a link can never be accepted twice" **[Sourced — B8]**.
The two-active-member limit (Decision 11) is checked as part of this same
transaction, at both the service layer and the database trigger.

**Rollback behavior [Sourced — B4, Derived]:** on any partial failure, the
entire transaction rolls back; the Supabase Auth user is _not_ rolled back
(it's outside the database transaction boundary) but is explicitly
preserved for re-attempt per B4 ("Auth user preserved for re-attempt"). This
means the service must be able to detect "Auth user exists but has no
`profiles` row" and resume from step 2 on retry, rather than erroring on a
duplicate Auth user. This resumability requirement is a **[Derived]**
consequence of B4, not separately spelled out anywhere.

**Idempotency requirements [Derived, not explicitly named as such in any
source]:** the retry path described above implies the sign-up service must
be safely re-callable for the same Auth user without creating a second
workspace or a duplicate `workspace_members` row. This is a reasonable
engineering consequence of B4's stated retry behavior, not a separately
sourced requirement — flagged here so it's designed for deliberately, not
discovered as a bug later.

## 8. Invitation Lifecycle

**Approved states (Decision 8):** `pending`, `accepted`, `revoked`,
`expired`.

- **`pending`** — the invitation exists, has not been accepted, revoked, or
  expired. **[Sourced]** — the natural starting state implied by B7's
  "deliver" step.
- **`accepted`** — the invitee has completed the acceptance transaction
  (Section 7). **[Sourced — B8]** — explicitly named in Amendment Part 7.2
  ("the invitation is consumed atomically"). Terminal.
- **`revoked`** — the Owner cancelled the invitation before acceptance.
  **[Sourced — B7]** — "can be revoked by the Owner at any time before
  acceptance." Terminal. Revoked invitations remain queryable for history
  and auditing, and no longer count toward the one-pending-invitation rule;
  the Owner may issue a new invitation immediately after revoking.
- **`expired`** — the acceptance window elapsed without action.
  **[Sourced — B7]** — "expire automatically after a defined window" (see
  Decision 7 for the 7-day default). Terminal.

**No additional state was added.** A tempting fifth state might have been
something like a distinct "superseded" state for re-invitations, but
Amendment Part 4.2 point 6 ("Re-invite... the Owner may invite again...
always subject to the two-member cap") describes re-inviting as simply
_creating a new invitation_, not mutating an old one — so no state was
added for it, per the review's explicit instruction not to invent
unnecessary states.

**Transitions:**

- `pending` → `accepted` (via the protected acceptance service, Section 7)
- `pending` → `revoked` (via the Owner, protected service, B14)
- `pending` → `expired` (via a background job, analogous in spirit to the
  Trash-expiration job described in B20/Clarification 1, though no document
  explicitly describes an invitation-expiration job's mechanics — this is a
  **[Derived]** analogy, not a sourced job specification)
- No transition exists out of `accepted`, `revoked`, or `expired` — all
  three are terminal, consistent with re-inviting always creating (or
  reactivating, per Decision 5, for a returning removed member) a
  membership row rather than resurrecting an old invitation.

Revocation and acceptance actor attribution beyond `invitations.created_by`
belongs in `audit_events` once that stage-10 table is implemented
(Decision 10).

## 9. Alternatives Considered

This section records the alternatives evaluated during the review, for
historical reference — each was weighed against the approved outcome above.

- **Decision 1 (profiles.id):** Alternative — a separate `profiles.user_id`
  foreign key distinct from `profiles.id`. Not chosen: unnecessary
  complexity with no sourced reason to prefer it; Supabase's own idiomatic
  pattern is the shared-PK approach.
- **Decision 2 (multi-workspace membership):** Alternative — allow a
  `workspace_members` row per user per workspace without a global
  uniqueness constraint, in case a future amendment ever allows one person
  to operate multiple Privately Hosted instances under one Supabase Auth
  identity. Not chosen for Slice 1: nothing in the approved model
  contemplates this; loosening a constraint later is easier than tightening
  one after data already violates it.
- **Decision 3 (owner_user_id column):** Alternative — add
  `workspaces.owner_user_id` as a fast-lookup denormalization of the
  `workspace_members` owner row. Not chosen: creates two sources of truth
  that could disagree, for a performance benefit not needed at two-row
  scale.
- **Decision 5 (removed-member row fate):** Alternative — hard-delete the
  `workspace_members` row on removal. Not chosen: P6-D requires the removal
  to be "audit-recorded," and a hard-deleted row is harder to reason about
  than a row whose `status` simply changed; this was the closest call in
  the entire review, since the audit trail could alternatively live
  entirely in `audit_events`.
- **Decision 6 (token storage):** Alternative — store the raw token in
  plaintext for simpler lookup. Not chosen: a leaked database backup would
  expose every outstanding invitation link directly.
- **Decision 7 (expiration duration):** Alternatives — 24–72 hours (short)
  or 30 days (long). 7 days chosen as a conventional middle default; this
  was explicitly a product/UX judgment call, not an engineering-driven one.
- **Decision 8 (revocation mechanics):** Alternative — hard-delete on
  revocation. Not chosen: inconsistent with the already-drafted state
  machine's `'revoked'` terminal state, and loses Owner-visible history of
  "I revoked this."
- **Decision 9 (Trash/Restore for identity tables):** Alternative — apply
  the uniform D23 30-day retention to these tables too, for consistency
  with "all record types." Not chosen: D23 and Amendment Part 5.4 are both
  written in the vocabulary of content records inside Spaces; a generic
  Restore action here would be meaningless given P6-D already fully
  specifies removal's effects.
- **Decision 10 (created_by/updated_by):** Alternative — omit
  `invitations.created_by` entirely, relying solely on `audit_events`.
  Considered a genuinely close call, given that under the current one-owner
  model the column is fully derivable from `workspace_members`; kept for
  historical durability given the explicit requirement that ownership
  changes must never retroactively corrupt this attribution.
- **Decision 11 (two-member cap enforcement):** Alternative — enforce
  solely at the database level with no service-layer check. Not chosen:
  produces a raw database error instead of the plain-language messaging the
  approved error-handling rules require.
- **Decision 13 (time zone placement):** Alternative — store on `profiles`.
  Not chosen: no document ever groups time zone with `profiles`; Amendment
  Part 3 item 4 groups it with `user_settings`.
- **Decision 14 (display name):** Alternatives — optional field (collect
  later) or required field (collect at sign-up). Required was ruled out
  directly by Amendment Part 7.6's onboarding-step constraint. Optional was
  a closer call, ultimately not chosen in favor of strict schema
  minimalism consistent with the rest of this review.
- **Decision 15 (PK shape):** Alternative — composite `(workspace_id,
user_id)` primary key. Not chosen: inconsistent with every other table's
  surrogate-UUID convention, and more awkward for any future foreign key
  referencing a specific membership row.
- **Decision 16 (constraint mechanism):** Alternative — native Postgres
  `ENUM` types. Not chosen: historically more difficult to alter (adding or
  removing a value) than a `text` + `CHECK` constraint, working against
  this review's consistent preference for ease of future change.
- **Decision 17 (migration granularity):** Alternative — one combined
  migration for all of stage 1. Not chosen: harder to review, coarser
  rollback granularity, and a break from this project's established
  small-PR discipline.

## 10. [Removed — all decisions resolved]

_(This section previously listed 17 open questions. All 17 were reviewed
and approved individually; see Section 5 for the complete record. Nothing
remains open at the schema-design level for Slice 1.)_

## 11. Approval Gate

**All 17 field-level decisions have been reviewed and approved by the
project owner.** This document now reflects the approved schema design for
Slice 1's five tables.

**No migration, SQL, authentication implementation, or application feature
work may begin until the project owner separately approves this finalized
document as a whole** (distinct from having approved each individual
decision during the review) **and explicitly authorizes implementation to
proceed.** Reviewing and approving this document's content is not, by
itself, authorization to begin writing SQL — that remains a distinct,
explicit go-ahead per the project owner's own instruction.
