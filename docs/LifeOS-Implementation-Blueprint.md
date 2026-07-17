# LifeOS Implementation Blueprint

**Purpose:** the single starting point for the Claude Code implementation session. This document references the approved planning documents; it never replaces or restates them at length. Where this blueprint and a planning document differ, **the planning document wins** and the difference must be raised as a finding, never silently resolved.

**Governance (Architecture Freeze, in effect):** planning is frozen. No approved decision may be changed silently. No recommendation becomes a rule without explicit user approval. Any architectural change requires an **Architecture Change Request (ACR)** — why necessary, benefits, drawbacks, scope impact, migration impact, simplicity impact, recommendation — approved *before* any approved document is modified.

**Post-audit status:** all Final Planning Audit findings (F1–F9) were approved and applied in the F7 conforming update pass. The compact package + Private-Hosting amendment + this blueprint are the complete authoritative planning set (F8); the nine original planning documents are historical references only. The mandatory terminology standard (F9) applies to all future documentation and implementation. No open planning items remain.

---

## 1. Executive Summary

LifeOS is a personal operating system — one calm, opinionated, beginner-friendly application replacing separate task, note, calendar, and project tools — built for a student's school-plus-everyday life now, structurally ready for later life stages. v1 ships as a **privately hosted instance for exactly two trusted members**, with **Space-level Private/Shared visibility** as the primary sharing boundary and an optional record-level "Only me" override inside Shared Spaces. The governing, non-negotiable constraint is the **Simplicity Standard (D27)**: far easier than Notion, ten core actions performable by a first-time nontechnical user with no instructions, enforced as release-blocking tests.

Authoritative sources: *LifeOS-Source-of-Truth.md* (specification), *LifeOS-Decision-Register.md* (every decision, with sources), *Private-Hosting-and-Two-Person-Access-Amendment.md* (the two-member model, Parts 1–12, approved).

## 2. Overall Architecture

Reference: *LifeOS-Source-of-Truth.md* ("Core Architecture — Three Layers" and following sections); *LifeOS-Technical-Handoff.md*; amendment Parts 3, 6, 8.

- **Three layers:** Shared Platform Services → Universal Productivity Objects → Specialized Domain Records. Layer 3 records never build private copies of Layer 1 services (D1, D2).
- **Ownership:** every record anchors to the workspace (D18); the word "workspace" never appears in the UI.
- **Sharing model:** Space-level Private/Shared visibility (P6-C) + optional "Only me" override (amendment Part 6.3); visibility is a separate axis from Standard/Sensitive/Restricted privacy levels (D9/D10; amendment Part 6.1).
- **Authorization layers, in order:** workspace membership → Space visibility → protected server-side writes (D17, extended with visibility coherence, amendment 8.4) → privacy-level filtering via the single shared query helper.
- **Data:** PostgreSQL, UUID keys, polymorphic `record_type` + `record_id` for cross-cutting tables (D16), real foreign keys for essential domain links, dates-as-dates, decimal currency.

## 3. Approved Technology Stack

Reference: *LifeOS-Technical-Handoff.md* "Stack"; Decision Register D20/D21/D30 (now approved); amendment P7-A and Part 12.

Next.js (TypeScript, App Router) · Tailwind CSS · shadcn/ui · Supabase (Auth, PostgreSQL, Storage; standard Supabase Auth email flow for invitations and password resets — P7-A) · Vercel · date-fns + date-fns-tz · React Hook Form + Zod · **Tiptap** (D20, approved) · **FullCalendar, free-tier features only** (D21, approved) · Vitest / Playwright / axe-core · **hosted error tracking (e.g., Sentry)** (D30, approved) with the binding constraint that private-record content is never transmitted — technical diagnostics only.

Starting point: the official Vercel `with-supabase` starter (reviewed and recommended earlier in this project) — keep its App Router/auth/cookie-session/shadcn foundation; strip demo content; note that invited-account acceptance (amendment 7.2) modifies the default "new workspace at sign-up" behavior for the second account.

## 4. Folder Structure (implementation guidance — adjustable without an ACR, since it changes no approved decision)

```
/app                    # Next.js App Router routes (auth, dashboard, spaces, calendar, search, settings)
/components             # UI components (shadcn/ui-based); /components/ui reserved for shadcn primitives
/lib/supabase           # Browser + server Supabase clients, middleware helpers (from starter)
/lib/services           # Protected server-side write services — the ONLY home for D17 operations
/lib/queries            # Read helpers, including the single shared visibility/privacy query helper
/lib/validation         # Zod schemas shared by client and server
/lib/dates              # date-fns wrappers; time-zone resolution
/db/migrations          # Numbered, ordered migrations with paired down-migrations (no manual DB changes)
/jobs                   # Supabase Scheduled Function sources (occurrences, reminders, trash, orphan sweep)
/tests/unit             # Vitest
/tests/e2e              # Playwright, including the 13 simplicity acceptance tests
/tests/policies         # Cross-workspace AND cross-visibility access-blocking tests
```

## 5. Development Phases

Reference: *LifeOS-Technical-Handoff.md* "Implementation Phases"; amendment 1.3 (visibility must be in the first RLS design).

1. **Foundation slice:** sign-up (auto profile/workspace/settings) → sign-in → Dashboard shell → Spaces (including the `Private/Shared` visibility setting and Space ownership from day one) → title-only Tasks → soft deletion → baseline RLS **with visibility enforcement structures**, verified by policy tests.
2. Quick Capture → 3. Notes → 4. Classes & Assignments → 5. Bills → 6. Calendar & Appointments → 7. Reminders (with per-member delivery targeting) → 8. Search → 9. Files → 10. Privacy levels → 11. **Invitation & two-member flows** (closed sign-up posture, invitation lifecycle, member removal/P6-D) → 12. Final UX/accessibility/mobile refinement.

Each phase ends with a working, testable slice. Phase 11's placement is approved (F1): visibility structures land in the foundation slice, the invitation feature is its own late phase, and unrelated phases are unchanged.

## 6. Build Order (database)

Reference: *LifeOS-Technical-Handoff.md* "Migration Order" (13 stages, now carrying the approved F2 placements): invitations with stage 1; Space ownership and Private/Shared visibility with stage 2; reminder delivery targeting with stage 8; per-member daily-priorities scoping with stage 10. The approved migration philosophy — numbered, ordered, paired down-migrations, no manual database changes — is unchanged.

## 7. Testing Milestones

Reference: *LifeOS-Technical-Handoff.md* "Testing Strategy"; amendment 8.7.

- Every phase: Vitest unit/integration for its services; protected-write-service tests.
- Foundation exit: cross-workspace **and** cross-visibility policy tests pass (both families release-blocking).
- Each UI phase: Playwright coverage on desktop + mobile viewports; axe-core clean.
- Pre-release: all **13 simplicity acceptance criteria** pass as Playwright tests (release-blocking, per D27); closed-sign-up posture verified by test (amendment 12.2).

## 8. Release Milestones

- **Alpha (internal):** Foundation slice complete; policy tests green.
- **Beta (single-user complete):** phases 1–10 done; all MVP Scope "Must Have" checkboxes verifiably done for one user.
- **v1.0:** phase 11 done; two-member model working end-to-end; every release-blocking test green; prohibited-terms sweep clean.
- **v1.1:** Calendar Agenda view (D22) — first post-release item.

## 9. Coding Standards

- TypeScript strict mode; no `any` escape hatches in services or validation.
- One Zod schema per record type, shared client/server; server always re-validates (Technical Handoff, client/server split).
- All D17 operations live in `/lib/services`, each a single transaction; no polymorphic writes anywhere else, ever.
- Numbered migrations only, each with a down-migration; never manual database changes; backups before production schema changes (approved Git workflow).
- Feature branches, small commits, PR checkpoints even solo; protected main; tests required to merge.
- **Inspect existing files before changing them; never replace working systems unnecessarily** (approved Git workflow — binding on Claude Code).
- No approved decision altered in code without an approved ACR.
- Approved terminology standard (F9) in all code, comments, documentation, and UI copy: **Workspace Owner, Space Owner, Private Space, Shared Space, Privacy Level, Privately Hosted** — never bare "Owner"/"private"/"shared" where context leaves them ambiguous.

## 10. Simplicity Rules Developers Must Never Violate

Reference: D27 and *LifeOS-Source-of-Truth.md* "Approved Simplicity Acceptance Criteria" (the full binding list). Highlights: Task creation with only a title, one screen; Quick Capture opens in one tap and saves with zero categorization; complexity budget — nothing enters a primary flow unless the majority of users need it there; advanced fields behind "More options"; Projects/Folders/Tags soft-hidden per D19; one-tap-with-Undo (never confirmation dialogs) for completing Tasks, recording payments, changing Assignment status; sharing surfaces are exactly two — the per-Space Private/Shared question and the optional "Only me" lock option — and nothing else (amendment 10.5); the 10-action no-instructions test gates release.

## 11. Security Rules

Reference: *LifeOS-Technical-Handoff.md* "RLS Approach"; amendment Parts 8 and 12; MVP Scope "Explicitly Prohibited."

- RLS is the baseline, never the sole integrity control for polymorphic references (D17).
- Visibility enforced at the row-visibility layer via the single shared query helper — never per-screen filtering (amendment 6.7, 8.2); zero leakage of the other member's private content through any path, including counts, previews, suggestions, exports, file URLs, and error reports.
- Visibility coherence validated in every protected write (amendment 8.4); P8-A links are invisible from the shared side, behaving as though they do not exist.
- Manual permanent deletion: Workspace-Owner-only for shared records, creator-only for private; the Trash-expiration job is the only automatic caller of the protected deletion service (Clarification 1).
- Closed sign-up; invitation-only second account; invitations consumed atomically (amendment Part 7).
- Files served only via server-checked short-lived signed URLs; never public URLs.
- Never store full account/card numbers, security codes, or passwords in fields; no payment-sending language; no AI writes without explicit confirmation; no technical terms in the UI (Prohibited list — verbatim binding).
- Error tracking transmits technical diagnostics only; never private-record content (D30 as approved).
- Structural references on Shared records target only records visible to both members; invalid selections never offered (P8-B). An Appointment and its Event share one Space and identical visibility; moving one moves the other (P8-C). Inbox captures are author-only until conversion (P10-B). Attaching a File to a Shared record is a deliberate sharing action for that File (F6).

## 12. Performance Goals (blueprint-level targets; not previously approved metrics — tune with judgment, raise an ACR only if meeting them would change architecture)

- Dashboard and primary lists feel instant at household scale: interactive under ~1s on ordinary broadband after warm load.
- Calendar range fetches and the reminder scheduler each resolve with single indexed queries per the approved designs (`next_fire_at ≤ now`; per-visible-range fetches).
- Search returns within ~1s at single-household data volumes; no unified index table until proven necessary (approved Search architecture).
- Quick Capture save is never blocked by parsing (approved Quick Capture architecture).

## 13. Accessibility Requirements

Reference: *LifeOS-Technical-Handoff.md* "Testing Strategy."

- axe-core automated checks clean on every screen; manual keyboard-only passes for all primary journeys.
- Target WCAG 2.1 AA-level practices (focus visibility, labels, contrast, touch targets); mobile Quick Capture button never overlaps other controls (approved criterion).
- Accessibility failures on primary flows are treated as release-blocking alongside the simplicity criteria.

## 14. Definition of Done (per feature/phase)

A slice is Done only when: (1) its approved-document behavior is implemented without deviation, or a deviation has an approved ACR; (2) unit/integration tests cover its services, including failure/rollback paths; (3) policy tests prove cross-workspace and cross-visibility isolation for any new tables/paths; (4) Playwright covers its primary journey on desktop and mobile viewports; (5) axe-core is clean and keyboard use works; (6) no prohibited term or prohibited behavior appears; (7) relevant simplicity criteria pass; (8) migrations are numbered with working down-migrations; (9) failed saves preserve user input per the approved error-handling rules; (10) the change is merged via PR with tests green.

## 15. Approved Planning Documents Claude Code Must Reference

**The compact package (in this project):**
1. LifeOS-Source-of-Truth.md — condensed specification (read first)
2. LifeOS-MVP-Scope.md — must-have / soft-hidden / deferred / prohibited checklist
3. LifeOS-Technical-Handoff.md — condensed technical design
4. LifeOS-Decision-Register.md — every decision with sources and status
5. LifeOS-Current-Status-and-Next-Step.md — conformed (F7); reflects planning completion and the exact next step
6. LifeOS-Document-Index.md — map of all documents (conformed, F7)

**The amendment (in this project's outputs):**
7. Private-Hosting-and-Two-Person-Access-Amendment.md — Parts 1–12, approved, including P6-A–D, P7-A, P8-A, P10-A, Part 12, and the Architecture Freeze record

**The nine original planning documents** (Core-Domain-Architecture-v2, Product-Vision-and-Scope, User-Experience-and-Wireframes, Information-Architecture-and-Screen-Specifications, Architecture-Final-Review-and-Amendments, Database-Schema-Design, Database-Schema-Final-Audit-and-Simplicity-Amendment, Technical-Architecture-and-Implementation-Plan, plus the superseded v1) are, per approved F8, **historical references only**: Claude Code uses the compact package, the amendment, this blueprint, and LifeOS-Master-Reference.md, consulting the originals solely when a historical decision must be researched.

**Reading order for Claude Code:** Source of Truth → MVP Scope → Technical Handoff → Amendment → Decision Register (as needed) → this blueprint's phases and rules.
