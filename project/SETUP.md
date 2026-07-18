# Setup — Cold Start

This document walks through everything needed to get this repository running
from a fresh clone, including the parts that aren't automated yet. It
complements `RECOVERY.md` (the "what is this, where do I start" document) —
this file is purely mechanical: the exact commands and configuration steps.

No real secrets appear anywhere in this file. Wherever a real value is
needed, it's described, never provided.

## 1. Clone and install

```
git clone <this repository's URL>
cd LifeOS
npm install
```

No special flags, no private registries, no post-install scripts beyond the
standard `npm install`.

## 2. Environment variables

Copy `.env.example` to `.env.local` and fill in real values. **Never commit
`.env.local`** — it's already git-ignored.

As of the current implementation state (Slice 1 complete, Slice 2 not yet
implemented), `.env.example` documents exactly two variables:

- `NEXT_PUBLIC_SUPABASE_URL` — your Supabase project's API URL.
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` — your Supabase project's
  publishable/anon key.

Both are found in your Supabase project's dashboard under **Project
Settings → API**.

**Once Slice 2 is implemented, two more variables will be required** (see
`NEXT_STEPS.md`'s Slice 2 plan): `SUPABASE_SERVICE_ROLE_KEY` (server-only,
from the same API settings page — treat this one as highly sensitive, it
bypasses all database access control) and `NEXT_PUBLIC_SITE_URL` (this
app's own base URL, for constructing auth email redirect links). This file
will be updated when that lands.

## 3. Create and configure a Supabase project

**This is a manual step — no automation or CLI scripting exists in this
repository for it yet.**

1. Create a new project at [supabase.com](https://supabase.com) (or use an
   existing one dedicated to this app — never share a Supabase project
   across unrelated applications).
2. Copy the Project URL and publishable/anon key into `.env.local` (step 2
   above).
3. **Auth settings** (Authentication → Providers / Settings in the Supabase
   dashboard) — needed once Slice 2 lands, worth setting up now if you're
   provisioning fresh:
   - Email provider enabled (the standard Supabase Auth email flow — no
     custom email system is planned, per the approved architecture).
   - "Confirm email" **enabled** — Slice 2's onboarding transaction is
     designed to run only after email confirmation, not at initial sign-up.
   - After the first (Owner) account is created, manually disable "Allow
     new users to sign up" in this same settings panel. This is a
     secondary, manual safeguard alongside the application's own
     closed-sign-up enforcement — not a substitute for it.
4. No Supabase Storage buckets, Edge Functions, or scheduled functions are
   needed yet — none of the current or planned-next slices use them.

## 4. Apply the database migrations

**This is currently a manual step.** No migration-runner tool, no Supabase
CLI configuration, and no CI database service exist in this repository yet
— every migration so far has only been verified against a local scratch
PostgreSQL instance via direct `psql`, never applied to a real Supabase
project through automation.

To apply the five existing migrations (`db/migrations/0001` through `0005`)
to a real Supabase project:

1. Open your Supabase project's **SQL Editor**.
2. Run each `*.up.sql` file in `db/migrations/`, **in numeric order**
   (`0001_profiles.up.sql` → `0005_invitations.up.sql`). Each is a small,
   independent, already-reviewed migration — see `db/migrations/README.md`
   for what each one does.
3. Do not run the `.down.sql` files unless you specifically intend to roll
   back — and if you do, run them in **reverse** numeric order
   (`0005` → `0001`).

There is currently no automated way to verify the applied schema matches
what's in this repository beyond visual comparison in the SQL Editor's
table view — the clean-room verification described in `PROJECT_STATUS.md`
was performed against a local scratch database, not this step.

## 5. Run the application

```
npm run dev
```

Starts the Next.js dev server. With only Slice 1 (schema) complete and no
Slice 2 (auth) implementation yet, the running app is still the empty
Phase 1 placeholder shell — there's no sign-up/sign-in surface to exercise
yet.

## 6. Run tests

```
npm run lint          # ESLint
npm run typecheck     # tsc --noEmit
npm run test          # Vitest (unit)
npm run test:e2e      # Playwright (end-to-end)
npm run format        # Prettier, check only
```

**What this does and does not cover:** these commands exercise application
code, not the database layer. There is no automated migration test suite —
migration verification (structure, constraints, triggers, rollback,
concurrency) has so far been done manually against a local PostgreSQL 16
instance for each migration individually, plus one combined clean-room
pass; see `PROJECT_STATUS.md`'s "Database Schema Status (Slice 1)" section
for exactly what was checked and how. Reproducing that locally requires a
PostgreSQL 16 instance and manual `psql` commands — there's no `npm run`
script for it yet.

## 7. What's still manual / not automated (summary)

- Supabase project creation and Auth configuration (step 3).
- Applying migrations to a real Supabase project (step 4).
- Database-layer verification (step 6) — no automated equivalent to the
  manual clean-room process exists yet.
- CI (`.github/workflows/ci.yml`) runs lint/typecheck/test/build only — it
  has no database service and cannot apply or verify migrations.

None of this is a defect to silently work around — each has been a
deliberate, explained deferral at the point it came up (see
`project/NEXT_STEPS.md`'s Slice 1 "Testing Strategy" section and Risk #2
for the original reasoning). This file exists so that reasoning doesn't
have to be rediscovered by whoever picks this project up next.
