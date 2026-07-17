# Private-Hosting-and-Two-Person-Access-Amendment

**Document status:** Parts 1–6 (Revision 2) are **approved**, together with the Approval Record's clarifications (automatic Trash expiration, Space archiving authority, decision P6-D, and the Source-of-Truth conforming note) recorded immediately after Part 6. Parts 7–12 are **approved**, including: **P7-A** (standard Supabase Auth email flow for invitations and password resets in v1; no custom email system unless a future requirement demands it), **P8-A** (cross-visibility links allowed; the private end is completely invisible to the other member — no titles, previews, counts, search results, metadata, or hints; the relationship behaves exactly as though it does not exist for anyone without access), **P10-A** (Today's Priority is personal per member, even for shared records; no shared household priority list in v1), and **Part 12 in full** (privately hosted two-member operation with the operator trust boundary documented honestly: application-level privacy guaranteed, infrastructure-level access acknowledged, never hidden). Separately approved in the same review: **D20** (Tiptap), **D21** (FullCalendar), and **D30** (error tracking, with the binding requirement that record content from private records is never transmitted — technical diagnostics only). The governing model is **Space-level Private/Shared visibility**; Revision 1's record-by-record model was reviewed and not approved. Decisions P6-A, P6-B, P6-C (Part 6.6) and P6-D (Approval Record) are approved. Nothing in this document authorizes implementation, code, SQL, migrations, or Supabase configuration.

**Architecture Freeze (in effect as of this approval):** planning is complete. No document may silently change an approved decision; no recommendation becomes an approved rule without explicit user approval; any future architectural change must be presented as an **Architecture Change Request (ACR)** stating why the change is necessary, benefits, drawbacks, scope impact, migration impact, simplicity impact, and a recommendation — and must wait for approval before any approved document is modified.

**Amendment discipline (user-directed, binding on this document):** this amendment *amends* the approved planning documents; it never replaces them. Every rule in Parts 7 onward is tagged either **[Extends …]** (a direct extension of a named approved decision or document) or **[New — requires approval]** (a genuinely new decision). If a conflict with an approved document is discovered at any point, the conflict is flagged and work stops on that point — it is never silently resolved.

**Resolves:** Decision Register item **D31** (Private hosting / invited-member model — previously "Pending / Not Started").

**Governed by:** LifeOS-Source-of-Truth.md, LifeOS-Decision-Register.md, and the non-negotiable Simplicity Standard (D27). Where this amendment is silent, all previously approved documents remain fully in force.

---

## Part 1 — Purpose, Status, and Relationship to the Approved Scope

### 1.1 Why this amendment exists

Every approved LifeOS document assumes a **single-user MVP**. The workspace structure (D18) was deliberately created at sign-up as future-ready plumbing — `workspaces` plus `workspace_members` with exactly one owner row — but no sharing, invitation, or per-member access behavior was ever designed, and the Decision Register explicitly records (D31) that a private-hosting / invited-member model must be raised and approved as a distinct amendment before implementation can treat it as in scope.

This document is that amendment. It defines the **smallest possible multi-person model**: one privately hosted LifeOS instance shared by exactly two people who trust each other in ordinary life (for example, a couple or two household members), where each person signs in with their own account, where **each Space is either Private or Shared**, and where each person therefore keeps genuinely private areas without per-record effort.

### 1.2 What this amendment is not

- It is **not** general multi-user or household/family collaboration. That remains on the deferred roadmap exactly as before. This amendment covers a hard maximum of two members per workspace.
- It is **not** a public or commercial hosting model. The instance remains privately deployed and privately operated for its two members only; there is no public sign-up.
- It is **not** a complex permissions engine. The entire sharing model is one understandable question per Space — **"Is this Space private or shared?"** — plus one optional record-level "Only me" override inside Shared Spaces. There are no per-record access-control lists, no permission matrices, no per-person checklists, and no role hierarchies beyond the two membership roles defined in Part 4.
- It does **not** reopen, weaken, or reinterpret any approved decision. In particular, D17 (protected server-side writes), D18 (workspace anchoring), D9/D10 (privacy levels and intent-based Restricted behavior), and D27 (simplicity standard) all remain binding and are extended — never replaced — by this document.

### 1.3 Position in the planning sequence

This amendment must be explicitly approved (or amended) **before** the first implementation phase begins, because Part 6 places the sharing boundary at the Space-visibility level and that belongs in the very first RLS and protected-write design rather than being retrofitted. It does **not** require reopening the approved logical schema documents; Part 3 confirms the approved schema already anticipates most of what this amendment needs, with a small number of additive elements identified where relevant (notably Space ownership and Space visibility, Part 6).

---

## Part 2 — Definitions and the Target Model

### 2.1 Definitions

- **Private hosting** — the LifeOS application and its Supabase project are deployed and operated by (or for) the two members themselves, on their own accounts (e.g., their own Vercel project and their own Supabase project), with sign-up closed to the public. "Private" describes *who may become a member and who operates the instance*, not a change of technology stack.
- **Workspace Owner** (or simply **Owner**) — the member whose sign-up created the workspace. There is exactly one Owner per workspace, matching the existing D18 owner row.
- **Invited Member** (or simply **Member**) — the one additional person the Owner invites into the shared workspace. They authenticate with their own credentials, have their own profile and settings, and are never a sub-account of the Owner.
- **Workspace** — the single container both members belong to. All Spaces — Private and Shared — live inside it.
- **Space owner** — the member who created a given Space. Every Space has exactly one Space owner. Space ownership is distinct from workspace ownership: the Workspace Owner does not own Member-created Spaces.
- **Private Space** — a Space visible only to its Space owner (Part 6.2).
- **Shared Space** — a Space visible and usable by both members (Part 6.2).
- **"Only me" record** — an optional record-level override, available inside Shared Spaces, limiting a specific record to its creator (Part 6.3).

### 2.2 The target model in one paragraph

One privately hosted LifeOS instance. Two accounts. One workspace containing every Space. **The primary sharing boundary is the Space:** each Space is either Private (its owner only) or Shared (both members), so ordinary privacy is managed once per area of life, not record by record. Inside Shared Spaces, both members can see and use everything by normal record rules, and either member can occasionally mark an individual record "Only me" for the rare private item inside an otherwise shared area. Each member keeps their own settings, their own reminder delivery, and their own sign-in. Nothing about the day-to-day interface becomes more complicated for a user who never thinks about sharing: the Simplicity Standard's ten-action no-instructions test must pass identically in a two-person workspace.

### 2.3 Explicit non-goals of the model

- No permission system beyond the Private/Shared Space setting and the "Only me" record override. No per-record sharing lists, no read-only grants, no per-person capability toggles.
- No "assignment" workflow in v1. The `assigned_to` column remains present and remains unused and invisible (unchanged from the approved scope).
- No activity feeds, presence indicators, commenting-as-collaboration features, or simultaneous-editing guarantees beyond the already-approved "changed elsewhere — reload" conflict behavior.
- No third member, ever, under this amendment. Raising the limit is a future amendment.

---

## Part 3 — What the Approved Architecture Already Provides

This amendment was anticipated structurally. An audit of the approved documents shows the following is already in place and requires **no revision**, only activation:

1. **Workspace anchoring (D18).** Every user-owned record already anchors to a `workspace`, not to a user. A second member row in `workspace_members` is exactly the shape the approved schema was designed to accept.
2. **RLS baseline.** The approved RLS approach is already written in membership terms: "any workspace member may read/insert/update/soft-delete within their own workspace." That statement remains the baseline; this amendment layers the Space-visibility boundary (Part 6) on top of it as the sharing rule, enforced below the interface.
3. **Protected server-side writes (D17).** All polymorphic and multi-step writes already flow through a controlled server path that validates "matching workspace on all sides." That validation is precisely what keeps a two-member workspace coherent, and it is already approved.
4. **Per-user identity separation.** Profiles and `user_settings` are already per-user, not per-workspace, so two members having different time zones, notification preferences, and defaults requires no restructuring.
5. **Audit events.** Every meaningful operation is already recorded with an acting user; in a two-person workspace this becomes genuinely informative (who changed what) with zero new machinery. Audit events remain unexposed in the normal UI (D24, unchanged).
6. **Provenance and creator identity.** Records already carry system metadata including creator identity, which Space ownership and the "Only me" override both depend on.

**What the approved architecture deliberately does not provide** (and what this amendment therefore defines): an invitation flow, a second membership role, **Space ownership and the Private/Shared Space visibility setting**, the meaning of privacy levels when a second human (not just the AI) exists, reminder-delivery targeting when two people exist, and the closed-sign-up hosting posture. Parts 4–6 cover the first four; the remaining topics are addressed in the parts following Part 6.

---

## Part 4 — Membership Roles and the Invitation Lifecycle

### 4.1 Roles

Exactly two membership roles exist:

- **Workspace Owner** — everything a Member can do, plus: send/revoke the invitation, remove the Member, permanently delete shared records (Part 5.4), and (in future parts) operate instance-level maintenance actions. The Owner role is fixed to the account that created the workspace; ownership transfer is out of scope for this amendment.
- **Member** — full ordinary use of the workspace: create their own Spaces (Private or Shared), and create, view, edit, complete, archive, and soft-delete records within Shared Spaces and their own Private Spaces; use Quick Capture, Search, Calendar, Reminders, and Files, identically to the Owner within the same visibility rules. A Member cannot invite anyone (the two-member cap makes this moot) and cannot remove the Owner.

Membership roles are deliberately thin. Day-to-day authority follows **Space ownership** (Part 6.5), not membership role: the Workspace Owner has no special power inside a Member-owned Space and **may not view a Member-owned Private Space through the LifeOS interface at all.**

### 4.2 Invitation lifecycle (planning-level, no implementation detail)

1. **Invite.** The Owner, from Settings, enters the invitee's email address. At most one invitation may exist at a time, and only while the workspace has one member.
2. **Deliver.** The invitee receives an invitation with a time-limited acceptance link. The invitation states plainly whose LifeOS they are joining.
3. **Accept.** The invitee creates their own account (own email, own password) and, in the same flow, is joined to the existing workspace as Member — replacing, for this invited account only, the normal "create a fresh workspace at sign-up" behavior. Acceptance is a single transaction: Auth user, profile, member row, and personal `user_settings` with approved defaults, mirroring the approved sign-up transaction shape.
4. **Expire / revoke.** Un-accepted invitations expire automatically after a defined window and can be revoked by the Owner at any time before acceptance. Expired or revoked links fail with a plain-language message.
5. **Remove.** The Owner may remove the Member. Removal ends the Member's access immediately but **destroys no data**: shared records the Member created remain in the workspace, fully intact and attributed to them — removing a member never deletes shared records they created. The removed Member's private records (their Private Spaces and their "Only me" records) are handled per approved decision **P6-A** (Part 6.6): preserved and invisible.
6. **Re-invite.** After removal or expiry, the Owner may invite again (the same person or someone else), always subject to the two-member cap.

### 4.3 Simplicity constraints on this lifecycle

- The entire invitation feature surfaces in exactly **one place**: a single Settings section. Nothing about invitations appears in onboarding, primary navigation, dashboards, or any creation form.
- The Private/Shared Space setting surfaces in exactly one place per Space: that Space's own settings, phrased as the single plain question "Is this Space private or shared?"
- A workspace whose Owner never opens the invitation Settings section behaves indistinguishably from the approved single-user MVP.
- All lifecycle language is plain ("Invite someone," "Remove access," "Private," "Shared") — never "membership," "role," "workspace," "permission," or any other prohibited technical term.

---

## Part 5 — Access, Ownership, and Editing Model

### 5.1 The sharing boundary is the Space

Access follows Part 6's visibility model, summarized here:

- **Private Space** → only its Space owner sees it or anything in it, anywhere.
- **Shared Space** → both members have identical ordinary capabilities over its records, regardless of who created them: view, edit, complete, change status, record payments, reschedule, archive individual records, soft-delete, and restore. A Bill in a Shared Space is the household's Bill no matter who typed it in.
- **"Only me" record in a Shared Space** → its creator only (Part 6.3).

LifeOS deliberately avoids "your records vs. my records" friction *inside* Shared Spaces; the place to keep things separate is a Private Space, chosen once, not a per-record decision repeated forever.

### 5.2 Attribution without gatekeeping

Creator identity and last-editor identity are recorded as system metadata (already approved) but are **not** surfaced as badges, filters, or blame indicators in ordinary v1 flows. The audit trail exists; the interface stays calm.

### 5.3 Concurrency

The approved conflict behavior is unchanged and sufficient: a stale edit surfaces "changed elsewhere — reload," and failed saves never destroy entered content. No live co-editing is promised or built. (Concurrent editing can only occur in Shared Spaces by definition.)

### 5.4 Destructive and irreversible actions

- **Soft deletion:** both members may soft-delete shared records.
- **Restore:** both members may restore shared records from Trash during the uniform 30-day retention window (D23, unchanged).
- **Permanent deletion of shared records:** **Workspace-Owner-only.** A Member sees no permanent-delete action on shared Trash items.
- **Permanent deletion of private records:** each member may permanently delete their own private records — their "Only me" records and records in their own Private Spaces. A member can never permanently delete (or see, or restore) the other person's private records.
- **Automatic Trash expiration** (the approved daily 30-day job) continues to permanently remove expired items of all kinds as a system action; the Owner-only rule governs *manual* permanent deletion, not the approved retention job.
- **Space-level settings** (Private/Shared visibility, archiving the Space itself): Space-owner-only (Part 6.5). Archiving remains zero-rewrite (D11, unchanged).

### 5.5 Reminders in a two-person workspace

Reminder *definitions* stay exactly as approved (one shared Reminder system, materialized `next_fire_at`, D13–D15 unchanged). What becomes new is **delivery targeting**:

- A reminder defaults to delivery **only to the person who creates it**.
- On records in Shared Spaces, the reminder's own editing surface may offer one simple optional control — **"Remind both of us"** — never surfaced in default creation flows.
- Reminder delivery preferences remain personal (each member's own settings govern their own delivery).
- One member snoozing or dismissing their reminder never snoozes or dismisses the other member's reminder.
- Reminders on private records (Private Spaces, "Only me") can only ever deliver to their creator.

This preserves the complexity budget: a user who never touches the option gets exactly the approved single-user behavior.

### 5.6 Files

File access follows Space and record visibility: a File attached only to private records (a Private Space's records, or "Only me" records) is served — and previewed — only to that member; Files attached to shared records are shared. Download authorization continues to run through the approved server-checked signed-URL path with no exceptions.

---

## Part 6 — Space Visibility: the Governing Sharing Rule

This is the heart of the amendment. The approved privacy model (D9/D10) was designed against two audiences: the system's AI features and the user's own broad views (Search, Dashboard, previews). A second **human** audience changes what "private" must mean. **The governing rule: every Space has one simple visibility setting — Private or Shared — and this Space-level setting is the primary sharing boundary in LifeOS.** The interface answers one understandable question: *"Is this Space private or shared?"* No complex permission rules are introduced.

### 6.1 Two distinct axes, kept separate

- **Visibility** (new axis, this amendment): *who can see it* — Private Space / Shared Space / "Only me" override.
- **Privacy level** (approved axis, D9/D10, unchanged): *how it behaves within your own experience* — Standard / Sensitive / Restricted, governing AI eligibility and broad-view exposure exactly as approved.

A record always has both: e.g., a Restricted record can live in a Shared Space (deliberate-access-only for both members) or in a Private Space (its owner only, deliberate-access-only even for them). The approved intent-based rule (D10) carries over unchanged within each member's own experience.

### 6.2 Private and Shared Spaces

**A Private Space:**

- Is visible only to its Space owner.
- Does not appear in the other member's navigation.
- Does not appear in the other member's Dashboard.
- Does not appear in the other member's Search.
- Does not contribute to the other member's counts.
- Does not show Calendar information to the other member — not even a "Busy" block.
- Does not expose record titles, previews, files, reminders, or metadata to the other member in any surface, suggestion, or aggregate.
- May be changed to Shared only through a deliberate action by its Space owner, with confirmation (6.5).

Records created inside a Private Space **inherit Private visibility automatically**. The user never needs to mark individual records "Only me" for ordinary private organization — choosing the Space once is the whole job.

**A Shared Space:**

- Is visible to both members.
- Allows both members to use and update ordinary records (Part 5.1).
- Appears on both members' Dashboard, Search, and Calendar according to normal record rules (including the approved Restricted-record and archived-Space exclusions).

Records created inside a Shared Space **inherit Shared visibility automatically**.

### 6.3 Record-level "Only me" — the optional override

"Only me" remains available, but only as an **occasional override inside Shared Spaces** — for the rare private record inside an otherwise shared area (a gift note in the household Space, a private journal entry in a shared Personal Space). It is never required for ordinary private organization; that is what Private Spaces are for.

A record marked "Only me":

- Is visible only to its creator.
- Is excluded from the other member's lists, Dashboard, Search, previews, suggestions, and counts.
- Displays as a generic **"Busy"** block to the other member **only when it represents scheduled time** — unless a later approved decision changes this. (Note the deliberate asymmetry: Private-Space scheduled items show nothing at all, 6.2; "Only me" items in Shared Spaces show a Busy block, because the member chose to keep the item inside a shared area.)

Interface rule (D27/D28 applied): the existing quiet lock control gains at most one new option — "Only me" — one tap, plain words, hidden from default creation flows, no stacked controls.

### 6.4 Visibility inheritance and movement

Default behavior:

- **Private Space → new records are Private.**
- **Shared Space → new records are Shared.**
- **Shared Space + "Only me" override → creator only.**

A record inside a Private Space **cannot be changed to Shared while remaining in that Private Space**. To share it, the user must deliberately move (or copy) it into a Shared Space. This avoids the confusing exception of a supposedly Private Space containing shared records; a Private Space's contents are private, without asterisks.

Quick Capture interaction (D28 extended): a capture taken in a Private Space's context inherits Private visibility; conversion continues to raise, never lower, protection — a private capture never converts into a Shared-Space record without the creator explicitly choosing the destination.

### 6.5 Space ownership and management

- Each Space has exactly one owner: **Owner-created Spaces belong to the Workspace Owner; Member-created Spaces belong to the Member.**
- The Space owner chooses whether their Space is Private or Shared, and only the Space owner may change that setting.
- Changing **Shared → Private** requires confirmation, because it removes the other member's access to an area they could previously use.
- Changing **Private → Shared** requires confirmation, because it grants the other member access to everything inside.
- The Workspace Owner may **not** view a Member-owned Private Space through the LifeOS interface. Workspace ownership confers no visibility.
- Both members may use records inside a Shared Space regardless of who owns the Space; Space ownership governs the Space's settings, not its records' ordinary use.
- No per-person checklists or permission matrices exist anywhere — there are only two people and one question per Space.

### 6.6 Approved decisions (recorded for the Decision Register)

- **P6-A — Removed Member's private records. Approved.** A removed Member's private records (their Private Spaces and their "Only me" records) remain preserved and invisible. They are not transferred, not exposed, and not automatically deleted. A future secure export or account-restoration process may address them.
- **P6-B — Zero-leak to the Workspace Owner. Approved.** The Owner sees no aggregate counts, titles, previews, storage details, or any other hints about the Member's private records through the LifeOS interface.
- **P6-C — Space-level visibility. Approved.** Entire Spaces may be Private or Shared. **This is the primary sharing model of LifeOS**, superseding this document's Revision 1, which had proposed record-level-only privacy and deferred Space-level control.

### 6.7 Enforcement posture

Private-Space and "Only me" invisibility is enforced at the **row-visibility level** (the same layer as RLS and the approved single shared query-building helper), never by per-screen filtering. The shared helper that already excludes Restricted content from broad queries is extended to also exclude, for each requesting member, the other member's Private-Space records and "Only me" records from *all* queries — lists, search, counts, previews, calendar feeds, and suggestions alike. This is the reason (Part 1.3) the amendment precedes RLS design. No implementation is specified here; the planning requirement is only that the guarantee lives below the interface, in one place.

### 6.8 Trust boundary stated honestly

This model protects against **ordinary-life visibility**, not against a hostile co-member or the instance operator. Whoever administers the private Supabase project can, by definition of operating the database, technically access stored data outside the application. LifeOS's obligation is that the *application* never leaks Private-Space or "Only me" content to the other member through any surface, and that this limitation is documented plainly rather than implied away. Encryption-at-rest and platform security continue to apply as approved; per-record end-to-end encryption is explicitly out of scope for v1.

---

## Approval Record — Parts 1–6 and Final Clarifications

**Parts 1–6 (Revision 2) are approved as written**, subject to the following clarifications, which are themselves approved and take effect as if written into the relevant parts. Parts 1–6 above are preserved verbatim; these clarifications are the authoritative gloss.

### Clarification 1 — Automatic Trash expiration (glosses Part 5.4) [Extends D23, D17]

The Owner-only permanent-deletion rule applies to **manual user actions** only. The trusted automatic 30-day Trash-expiration job may permanently delete eligible expired records as a **system action**, and must: follow the approved 30-day retention rule; delete only records whose recovery period has expired; run through the protected permanent-deletion service; preserve required audit information; clean polymorphic references and attachments correctly; and never provide a path by which an ordinary Member can trigger early permanent deletion of shared records.

### Clarification 2 — Space archiving authority (glosses Parts 5.4 and 6.5) [Extends D11]

Only the **Space owner** may archive their Space, reopen their Space, or change it between Private and Shared. Both members may continue to create, edit, complete, soft-delete, and restore ordinary shared records inside a Shared Space. Archiving and visibility are Space-level management actions, not ordinary record actions.

### Approved Decision P6-D — Removed Member's Spaces [New decision — approved]

When the invited Member is removed:

**Member-owned Shared Spaces:** ownership automatically transfers to the Workspace Owner; the Space remains Shared unless the Workspace Owner later changes it; all records remain intact; record creator and modifier history remain unchanged; the ownership transfer is recorded in audit history; no records are deleted or duplicated.

**Member-owned Private Spaces:** remain preserved and invisible; do not transfer to the Workspace Owner; never appear in the Owner's navigation, Dashboard, Search, Calendar, counts, previews, storage summaries, or suggestions; follow approved decision P6-A; may be addressed later through a secure account-restoration or export process.

**Member-created records in Owner-owned Shared Spaces:** remain in those Spaces; remain available to the Workspace Owner; retain their original creator attribution; are not deleted when the Member is removed.

### Recorded Future Conforming Amendment — Source-of-Truth Dashboard Wording [Recorded, not yet applied]

Where LifeOS-Source-of-Truth.md says the Dashboard shows "all active Spaces together," upon final approval of this full amendment it shall be conformed to mean: **all Shared Spaces available to the current member, plus that member's own active Private Spaces, never the other member's Private Spaces.** The compact Source-of-Truth package is deliberately **not** edited yet; this is a required update after the full Private-Hosting amendment is approved.

---

## Part 7 — Authentication and Invited-User Account Setup

### 7.1 Closed sign-up posture [New — requires approval]

In a privately hosted instance, public self-service sign-up is **closed**. Exactly two account-creation paths exist:

1. **First account (Owner):** the instance's first sign-up proceeds exactly as approved (Auth user, profile, workspace, owner membership row, default `user_settings`, in one transaction). After the first workspace exists, the open sign-up path is disabled.
2. **Second account (Member):** created only through a valid, unexpired, unrevoked invitation link (Part 4.2). No other registration is possible.

Anyone reaching the sign-up surface without a valid invitation sees a plain-language message ("This LifeOS is private. Ask its owner for an invitation."), never a technical error.

### 7.2 Invitation acceptance transaction [Extends the approved sign-up transaction, Technical Handoff "Authentication & Workspace Setup"]

Acceptance mirrors the approved sign-up shape with one substitution: instead of creating a fresh workspace plus owner row, the transaction creates the Auth user, profile, a **Member** row in the existing `workspace_members`, and personal `user_settings` with approved defaults — all in one transaction. Partial failure follows the approved pattern exactly: plain-language retry, Auth user preserved for re-attempt, monitored error logged. The invitation is consumed atomically in the same transaction so a link can never be accepted twice.

### 7.3 Sessions, sign-in, and route protection [Extends approved architecture — unchanged]

Sessions remain Supabase httpOnly cookies; route protection remains the shared middleware; sign-in, sign-out, and password reset behave identically for both members. No member-specific session logic exists — the session identifies the user, and all visibility flows from Part 6's rules applied server-side, never from anything stored client-side.

### 7.4 Password reset and account recovery [Extends approved authentication scope]

Each member resets their own password through the standard flow. Neither member can reset, change, or recover the other's credentials through the LifeOS interface — including the Workspace Owner. (The honest trust-boundary statement in Part 6.8 still applies at the infrastructure level.)

### 7.5 Email delivery dependency [New — requires approval, flagged as open item P7-A]

Invitations and password resets both require outbound email. A privately hosted instance must therefore have a working email path (Supabase's built-in auth email service, or a configured SMTP provider). **This is an operational decision, not an architecture change**, but it must be decided before the invitation feature can be planned into an implementation phase. Flagged as **P7-A**; a recommendation belongs in Part 12's operational posture, with the choice left to the user.

### 7.6 Simplicity constraints [Extends D27]

Invited-account creation must meet the same onboarding bar as the approved flow: the invitee reaches a useful Dashboard in 3 or fewer steps after opening the invitation link (create credentials → confirm → Dashboard). No workspace concept, role names, or technical terms appear anywhere in the flow.

---

## Part 8 — Row-Level Security and Authorization Changes

*Planning-level only. This part states what the authorization layer must guarantee; it contains no policy syntax, SQL, or implementation.*

### 8.1 Layered model restated [Extends D17, D18, approved RLS approach]

Authorization remains layered exactly as approved, with one added layer:

1. **Workspace membership (unchanged baseline):** only members of the workspace can touch anything in it.
2. **Space visibility (new layer, per approved Part 6):** within the workspace, reads and ordinary writes are additionally constrained by Private/Shared Space visibility and the "Only me" override.
3. **Protected server-side writes (unchanged):** all polymorphic and multi-step writes still flow only through the controlled server path (D17).
4. **Privacy levels (unchanged):** Standard/Sensitive/Restricted continue to govern AI eligibility and broad-view exposure per D9/D10, enforced by the single shared query helper.

### 8.2 Read rules [Extends approved RLS approach; gives effect to approved Part 6]

For any requesting member, readable content is exactly: records in Shared Spaces (minus the other member's "Only me" records), plus records in that member's own Private Spaces. Everything else in the workspace is invisible — not filtered at the screen, but excluded at the row-visibility layer (approved Part 6.7). This exclusion applies uniformly to lists, detail fetches, search, counts, calendar feeds, previews, suggestions, exports, and file access.

### 8.3 Ordinary write rules [Extends approved RLS approach and Clarification 2]

- Both members may create, edit, complete, soft-delete, and restore ordinary records in Shared Spaces.
- Each member may do all of those things in their own Private Spaces; neither may write into the other's Private Spaces (they cannot even see them).
- "Only me" records accept writes only from their creator.
- Space-level management writes (visibility change, archive, reopen) are Space-owner-only (Clarification 2).
- Manual permanent deletion: Workspace-Owner-only for shared records; creator-only for private records (approved Part 5.4). Both run through the protected permanent-deletion service; the automatic expiration job is the only other caller of that service (Clarification 1).

### 8.4 Protected-write validation extended [Extends D17]

Every protected server-side write already validates record-type allowance, target existence, non-deleted state, matching workspace, authorization, and duplicate/self-reference prevention. This amendment adds one validation to the same list: **visibility coherence** — the acting member must be able to see every record involved in the operation. A member can never tag, attach, remind, relate, convert into, or otherwise touch a record they cannot see, even by guessing its identifier.

### 8.5 Cross-visibility links [New — requires approval, flagged as open item P8-A]

A genuinely new question arises: may a member create a typed relationship or shared-File attachment between a record they can see in a Shared Space and one of their *own private* records? Proposed rule, chosen for minimum cognitive load: **allowed, but the link itself follows the private end** — the other member never sees the relationship, the attachment row, or any hint of the private record from the shared side; the shared record simply shows nothing there for them. The alternative (forbidding cross-visibility links entirely) is simpler to enforce but forces users to duplicate content. Recommendation: the proposed rule. **Awaiting approval as P8-A.**

### 8.6 Invitation records and membership rows [Extends D17]

Invitation creation/revocation and member removal are protected server-side operations (they are membership-mutating and audit-relevant), Owner-only, each a single transaction, each audit-recorded — including the P6-D ownership transfers, which occur atomically within the removal transaction.

### 8.7 Testing obligation [Extends approved Testing Strategy]

The approved policy tests ("cross-workspace access is blocked") gain a sibling family that is equally release-blocking: **cross-visibility access is blocked** — one member can never read, write, count, search, or enumerate the other member's Private-Space or "Only me" content through any path, including the protected services, file URLs, and search.

---

## Part 9 — Bills and Other Sensitive Record Behavior

### 9.1 Bills follow Space visibility like everything else [Extends approved Bills model, D5, D14]

No Bill-specific sharing machinery exists. A Bill in a Shared Space is the household's Bill; a Bill in a Private Space is invisible to the other member, including its Occurrences, reminders, payment history, attachments, and any presence in Upcoming Bills, Search, Calendar chips, or counts.

### 9.2 Shared-Bill capabilities [Extends approved payment-recording rules]

Either member may edit a shared Bill, record a payment ("Mark Paid" / "Record Payment" — never "Pay," unchanged), and adjust its Occurrences per approved rules. Who recorded a payment is captured in audit history and record metadata (Part 5.2) but is not surfaced as a badge in ordinary flows. No notification is sent to the other member when one member records a payment — no activity feed exists (approved Part 2.3); the shared state simply updates.

### 9.3 Occurrence generation and reminders [Extends D5, D13–D15, approved Part 5.5]

The rolling 90-day Occurrence generation job is unchanged and visibility-neutral (it acts on data, not on member views). Reminder instances on each Occurrence follow the approved delivery-targeting rule: delivered to their creator by default, with the optional "Remind both of us" control available on shared Bills; paying an Occurrence cancels its pending reminder instances **for both members** — a paid bill stops reminding everyone. One member snoozing their own reminder never affects the other's (approved Part 5.5).

### 9.4 Recurrence changes [Extends D5]

Historical Occurrences are never rewritten (unchanged). Either member may change a shared Bill's recurrence, with the approved confirmation step; the change is audit-recorded with the acting member.

### 9.5 Privacy levels on financial and other sensitive records [Extends D9/D10; approved Part 6.1]

The two axes stay separate, worked through concretely:

- **Sensitive Bill in a Shared Space:** both members see and use it normally; AI features are excluded by default (unchanged D9).
- **Restricted Bill in a Shared Space:** excluded from *both* members' broad views (Dashboard sections including Upcoming Bills, Search previews, aggregate counts) exactly per the approved Restricted rule, applied per member; either member may deliberately open it (D10 intent rule, per member).
- **Any Bill in a Private Space:** the other member's experience is total absence — stricter than Restricted, because Restricted governs *broad views for people who have access*, while Private-Space visibility removes access altogether.

The same worked logic applies to every other record type (Assignments, Notes, Appointments, Contacts, Files): Space visibility decides *who*, privacy level decides *how it behaves for those who can see it*.

### 9.6 Prohibited items unchanged [Extends approved Explicitly Prohibited list]

Nothing in this amendment relaxes any prohibition: no full account/card numbers or passwords stored anywhere, no payment-sending language, no AI writes without confirmation, and no technical terms in the interface — in either member's experience.

---

## Part 10 — Dashboard and Search Visibility

### 10.1 Dashboard is per-member composition, unchanged behavior [Extends approved Dashboard rules + the recorded Source-of-Truth conforming note]

Each member's Dashboard is composed from: all Shared Spaces, plus that member's own active Private Spaces — never the other member's Private Spaces (per the recorded conforming amendment). Within that composition, every approved rule applies unchanged: urgency-ordered across Spaces (never grouped by Space), Restricted records excluded from all sections and counts, archived-Space content never shown, zero-setup usefulness, and the approved default/togglable section list.

### 10.2 Section-by-section effect [Extends approved Dashboard rules; gives effect to P6-B]

Today's Schedule, Overdue, Due Today, Due Soon, and Upcoming Bills each show the union of shared items and the viewing member's own private items — and nothing of the other member's private content, including in counts (P6-B). Quick Capture remains personal at the point of capture (a capture belongs to its author and follows Part 6.4 inheritance at conversion). Recent Notes and Recently Completed follow the same composition rule.

### 10.3 Today's Priority in a two-person workspace [New — requires approval, flagged as open item P10-A]

D26's `daily_priorities` table was designed for one user. Proposed rule, minimizing decisions and interface complexity: **Today's Priority is personal** — each member has their own day-scoped list; starring an item (shared or private-to-you) affects only your own Dashboard, and members never see each other's stars. The alternative (a shared household priority list) invites negotiation-by-interface and cross-member noise. Recommendation: personal. **Awaiting approval as P10-A.** No schema reopening is implied either way; this is a behavior decision.

### 10.4 Search [Extends D12 and approved Search architecture]

Search behavior is unchanged in ranking and mechanics (exact → trigram → full-text; archived excluded by default with an explicit toggle; deleted always excluded; Restricted never previewed in broad results, per member). The single shared query helper — already the enforcement point for privacy/archive/deletion filters — additionally applies the Part 8.2 visibility rule, so the other member's private content can never appear in results, suggestions, or result counts, regardless of query. No search feature is added, removed, or re-ranked by this amendment.

### 10.5 No sharing indicators in ordinary flows [Extends D27]

Dashboards and search results do not badge items as "shared" or "private" — an item's location already tells the story, and both members see only what they can use. The only visibility affordances in the entire interface remain: the one Space-level question, and the one optional "Only me" lock option.

---

## Part 11 — Calendar Sharing Behavior

### 11.1 Composition [Extends approved Calendar architecture]

Each member sees exactly one calendar: scheduled items and deadline chips from all Shared Spaces plus their own Private Spaces, fetched per visible range, rendered in that member's stored time zone, type-labeled per approved rules. There is no separate "household calendar," no per-person calendar toggle, and no overlay system — one calendar per member, composed by the same visibility rule as everything else.

### 11.2 What the other member sees, by case [Extends approved Part 6.2/6.3; approved Restricted "Busy" rule]

- **Shared-Space scheduled item (Standard/Sensitive):** fully visible to both, normal rendering.
- **Shared-Space scheduled item (Restricted):** generic "Busy" block for each member in broad calendar view, per the approved Restricted rule, applied per member; deliberate open reveals it (D10).
- **"Only me" scheduled item in a Shared Space:** generic "Busy" block for the other member (approved Part 6.3), normal rendering for its creator.
- **Private-Space scheduled item:** nothing at all for the other member — no Busy block, no gap-with-a-label, no count contribution (approved Part 6.2).

"Busy" blocks are non-interactive for the non-owning member: not clickable-through, not draggable, no tooltip content beyond "Busy."

### 11.3 Editing from the Calendar [Extends approved drag rules]

Either member may drag a *shared* scheduled Event to reschedule it, with the approved direct-update-plus-Undo behavior; the action is audit-recorded with the acting member. Deadline chips keep the approved intercept-into-confirm-and-edit behavior for whichever member drags them. Private and "Only me" items are only ever draggable by their owner/creator (the other member has no interactive representation of them).

### 11.4 Class meeting times and generated blocks [Extends approved Calendar architecture]

Class meeting schedules continue to expand into virtual blocks at query time, never persisted as Events (unchanged); the virtual blocks inherit the Class's Space visibility. Task/Assignment/Bill deadline chips inherit their record's visibility. Nothing about the approved never-duplicate-due-dates-as-Events rule changes.

### 11.5 External calendar sync [Extends approved deferral — unchanged]

External calendar sync remains deferred exactly as approved. This amendment adds one forward-looking planning note only: when sync is eventually designed, each member's external sync must export only what that member can see (their Part 8.2 set), and "Busy" blocks must sync as opaque busy time, not as titled events. No sync work is authorized now.

---

## Part 12 — Private Application Operation

### 12.1 Operating posture [New — requires approval as a whole; consistent with Part 2.1]

The instance consists of exactly one privately owned Vercel project and one privately owned Supabase project (plus the approved environment separation for development/preview/production). The Workspace Owner — or whoever the two members designate — is the **instance operator**: the person holding the Vercel/Supabase/GitHub credentials. LifeOS's planning documents treat operator duties as real responsibilities, stated plainly, never hidden.

### 12.2 Operator responsibilities (planning-level checklist) [Extends approved Git workflow, environments, and backup rules]

- Keep sign-up closed (Part 7.1) — verified by a release-blocking test, not by trust.
- Apply migrations only through the approved numbered-migration path; never manual database changes; backups before any production schema change (all unchanged from the approved Git workflow).
- Maintain the email path chosen under P7-A so invitations and password resets keep working.
- Hold rollback capability as approved: down-migrations for the database, Vercel instant rollback for the app.
- Keep the error-tracking service (D30 — still pending approval) scoped so that it never receives record *content* from private records; error reports carry technical context, not user data. **If D30 is approved, this content-scrubbing constraint rides along as part of it.**

### 12.3 Local development vs. private production [Extends approved environments; clarifies scope]

"Private operation" means privately *hosted* — it does not mean the application runs only on a local machine. Local development (including a locally running Supabase) remains a development-environment concern exactly as approved. Fully offline operation and offline synchronization remain deferred, unchanged. The production instance is the hosted, private, two-member deployment described in 12.1.

### 12.4 Data ownership and exit [Extends approved export deferral; consistent with P6-A]

Both members' data lives in the members' own Supabase project — there is no third-party product operator. Import/Export remains a Layer 1 platform service in the approved architecture; a *secure per-member export* (the mechanism P6-A anticipates for a removed Member's private records) is recorded here as the natural future home for that need, but is **not** added to v1 scope by this amendment.

### 12.5 Trust boundary, restated once [Extends approved Part 6.8 — unchanged]

The application guarantees zero interface-level leakage between members (Parts 6, 8, 10, 11). The instance operator can, by definition of operating the database, technically access stored data outside the application. This is stated honestly in planning and, at implementation time, should be stated honestly to both members in plain language once, at invitation acceptance — one sentence, not a legal document. *(That single disclosure sentence is a new interface element and is included in what Part 12 submits for approval.)*

### 12.6 What Part 12 deliberately does not decide

Hosting-account topology (whose Vercel/Supabase accounts), the P7-A email provider, custom-domain choice, and backup cadence beyond the approved pre-schema-change rule are operational choices for the members, to be settled before the relevant implementation phase — none of them alters the plan.

---

*End of Parts 7–12 (draft). Parts 13–19 intentionally not begun. Document stops here pending review.*
