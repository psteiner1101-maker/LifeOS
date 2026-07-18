# Recovery — Start Here

This is the cold-start entry point for a new developer, or a new AI
assistant session, picking up this project with no prior context. Read
this file first; it tells you what to read next and in what order, rather
than repeating what those files already say.

If anything in this file conflicts with the files it points to, **those
files win** — this document is a map, not a new source of truth.

## What this project is

LifeOS: a personal operating system for school-plus-everyday life,
Privately Hosted for exactly two members. Full product/architecture
context: `docs/LifeOS-Master-Reference.md` (single-document overview) and
the rest of `/docs` (the nine authoritative, frozen planning documents —
read-only during implementation, see `DEVELOPMENT_RULES.md`).

## Recommended reading order

1. **This file**, for orientation.
2. **`project/PROJECT_STATUS.md`** — the authoritative, current snapshot
   of what's actually built, with every fact tagged by how it was verified
   (repository evidence / GitHub metadata / user-reported). This is the
   single most important file for "what state is this repo in right now."
3. **`project/NEXT_STEPS.md`** — the full slice-by-slice roadmap. Slice 0
   and Slice 1 are complete and described as such; Slice 2 is planned and
   security-reviewed in full detail but **not yet implemented** — its
   section is a complete implementation plan, not a status report.
4. **`project/DEVELOPMENT_RULES.md`** and **`project/AI_WORKING_AGREEMENT.md`**
   — binding engineering standards and, specifically for an AI assistant
   continuing this work, the behavioral rules this project has been run
   under throughout (ACR process, never inventing requirements, always
   asking before architectural assumptions, small approved increments).
5. **`project/architecture/ACR-001-Slice-1-Identity-and-Workspace-Schema.md`**
   — the full, approved field-level schema decision record for the five
   Slice 1 tables, including the reasoning for every column, constraint,
   and the two-member-limit trigger design.
6. **`project/SETUP.md`** — when you're ready to actually run this
   project: clone, install, environment variables, Supabase provisioning,
   applying migrations, running the app and tests.
7. **`project/DEFINITION_OF_DONE.md`** and **`project/PROJECT_HEALTH.md`**
   — the release-gate checklist and a scored infrastructure/readiness
   assessment, useful context but not required reading to get started.

## What is complete

- **Phase 1 (project foundation scaffold):** Next.js/TypeScript/Tailwind/
  shadcn/ui scaffold, Supabase SSR client wiring (no auth enforcement yet),
  approved folder structure, tooling (ESLint, `tsc`, Vitest, Playwright,
  axe-core, Prettier), CI (`.github/workflows/ci.yml`).
- **Slice 0 (Infrastructure Provisioning):** Supabase + Vercel projects
  provisioned and connected, CI green, repository public. One residual
  item: the CI check isn't yet attached as a _required_ status check on
  `main`'s branch protection rule — see `PROJECT_STATUS.md` Open Issue #1.
- **Slice 1 (Database Schema):** all five identity/workspace migrations
  (`profiles`, `workspaces`, `workspace_members`, `user_settings`,
  `invitations`) implemented, individually reviewed and manually verified,
  then passed a full clean-room verification (fresh apply, 26 combined
  behavioral checks, full rollback leaving zero trace, identical
  reapplication, no discrepancies) — see `PROJECT_STATUS.md`'s "Database
  Schema Status (Slice 1)" section for the complete detail. **Not yet
  confirmed applied to any real Supabase project** — only verified locally.

## What is not yet implemented

- **Authentication** — no sign-up/sign-in/session logic exists in
  application code yet. Fully planned (see `NEXT_STEPS.md` Slice 2) and
  security-reviewed, but zero lines of it are written.
- **RLS** — currently zero policies exist anywhere (Slice 1 shipped
  without any, by explicit decision). Slice 2's plan adds a narrow,
  approved baseline (self-row read on `profiles`/`user_settings` only);
  full RLS hardening is its own later slice (Slice 6).
- **Service layer** — `/lib/services` is empty.
- **Everything from Slice 2 onward** — see `NEXT_STEPS.md` for the full
  17-slice remainder of the roadmap. Nothing beyond schema exists.

## Where authoritative decisions live

- **Product/architecture decisions:** `docs/LifeOS-Decision-Register.md`
  (D1–D31 plus the amendment decisions), sourced back to the relevant
  `/docs` document. `/docs` is frozen — any change requires an Architecture
  Change Request (ACR) reviewed and approved before any approved document
  is touched (`DEVELOPMENT_RULES.md` "The ACR Process").
- **Slice 1 field-level schema decisions:** `project/architecture/ACR-001-...md`
  — the schema wasn't in `/docs` (the original field-level document is
  permanently unavailable; see ACR-001 §2 for the full audit trail), so it
  was reconstructed and approved decision-by-decision as this ACR.
- **Slice 2 security/design decisions:** currently recorded in
  `project/NEXT_STEPS.md`'s Slice 2 section (RLS baseline, RPC design,
  idempotency states, `/app` gating placement, exact error messages,
  environment variables, commit boundaries) — approved in full, not yet
  implemented.
- **Process/engineering standards:** `project/DEVELOPMENT_RULES.md` and
  `project/AI_WORKING_AGREEMENT.md`.

## How to restore the project

1. Clone the repository (`main` is the default branch; it contains
   everything through Slice 1 plus this documentation).
2. Follow `project/SETUP.md` end to end.
3. Confirm your local state against `project/PROJECT_STATUS.md` — if
   anything disagrees, `PROJECT_STATUS.md` describes what's actually true
   about the repository; this file and `SETUP.md` describe process, not
   current state.
4. For a full point-in-time backup of the git history itself (all
   branches/commits, no working files, no secrets), see the git-bundle
   process referenced in `PROJECT_STATUS.md`'s Open Issues once it exists
   — as of this writing, the repository's durability rests on its GitHub
   remote (`main` branch-protected) plus ordinary local clones.

## How to resume at Slice 2

Slice 2's complete, security-reviewed implementation plan lives in
`project/NEXT_STEPS.md` under its own heading — read that section in full
before writing any code. It includes the exact migrations (0006, 0007 —
full SQL already written out, not just described), the RPC's caller
security model and full 8-state idempotency table, the RLS access matrix,
every route/file to create, exact error-message copy, required environment
variables, and a 13-step implementation order with commit boundaries.

**Before implementing:** confirm with the project owner that the plan as
written in `NEXT_STEPS.md` is still current and still approved — plans can
go stale between sessions. If anything about the approach seems like it
should change, that's a new decision requiring the same review discipline
every other decision in this project has gone through, not something to
resolve unilaterally (`AI_WORKING_AGREEMENT.md`).

**Implementation discipline to follow, matching Slice 1's precedent:** one
piece at a time (per the 13-step order in `NEXT_STEPS.md`), show the exact
diff, verify manually, wait for approval, commit only that piece, wait for
push approval, before starting the next piece. Do not batch multiple steps
into one unreviewed change.
