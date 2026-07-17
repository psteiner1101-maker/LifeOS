# LifeOS Development Rules

These are the binding engineering standards for this repository. They exist
to keep every future implementation session — human or AI — building the
same system the same way. When this file and `/docs` disagree, `/docs`
governs; raise the conflict, don't silently resolve it.

## Architecture Freeze Reminder

Planning is complete and frozen (`LifeOS-Master-Reference.md` §2,
`LifeOS-Implementation-Blueprint.md` governance section). No approved
decision — anything in `LifeOS-Decision-Register.md` or the approved
planning set — may be changed silently, by code, by convenience, or by
"this seemed simpler." No recommendation becomes a rule without the
project owner's explicit approval. This applies equally to a human
contributor and to Claude Code.

## The ACR Process

Any genuinely architectural change — anything that would alter an approved
decision, add a record type, change the sharing model, change the schema
approach, change the stack — must be presented as an **Architecture Change
Request** before any approved document is touched, containing:

1. Why the change is necessary
2. Benefits
3. Drawbacks
4. Scope impact
5. Migration impact
6. Simplicity impact (does it move LifeOS closer to or further from D27?)
7. A recommendation

Implementation may not proceed on the changed basis until the ACR is
approved. A tooling or version choice (which testing library glue package,
which exact patch version) is **not** architectural and does not need an
ACR — see `AI_WORKING_AGREEMENT.md` for where that line is drawn in practice.

## Coding Standards

- TypeScript strict mode everywhere; no `any` escape hatches in services or
  validation code (`LifeOS-Implementation-Blueprint.md` §9).
- One Zod schema per record type, shared between client and server; the
  server always re-validates independently — never trust client validation
  alone.
- Numbered, ordered database migrations only, each with a paired
  down-migration; no manual database changes, ever.
- Feature branches, small commits, PR checkpoints even for solo development;
  `main` is protected — no direct pushes once branch protection is
  configured (see `PROJECT_STATUS.md` open issues).
- **Inspect existing files before changing them.** Never replace a working
  system unnecessarily.
- No approved decision altered in code without an approved ACR.

## Folder Responsibilities

| Folder | Responsibility | Rule |
|---|---|---|
| `/app` | Next.js App Router routes | UI composition and routing only; no protected writes performed inline |
| `/components` | UI components (shadcn/ui-based) | Presentational; `/components/ui` reserved for shadcn primitives only |
| `/lib/supabase` | Browser + server Supabase clients, session middleware | Wiring only — no business logic, no feature-specific auth policy |
| `/lib/services` | Protected server-side write services (D17) | **The only** home for polymorphic/multi-step writes; each a single transaction |
| `/lib/queries` | Read helpers | **The only** home for the shared visibility/privacy query helper; every broad read goes through it |
| `/lib/validation` | Zod schemas | Shared client/server; one schema per record type |
| `/lib/dates` | date-fns wrappers, time-zone resolution | All date-only vs. timestamp handling lives here, not ad hoc in components |
| `/db/migrations` | Numbered SQL migrations | No manual database changes; every migration has a down-migration |
| `/jobs` | Supabase Scheduled Function sources | Background jobs only — occurrence generation, reminder firing, Trash expiration, orphan sweep |
| `/tests/unit` | Vitest | Unit/integration, including protected-write-service tests |
| `/tests/e2e` | Playwright | End-to-end journeys, desktop + mobile viewports, the 13 simplicity acceptance tests |
| `/tests/policies` | Cross-workspace + cross-visibility policy tests | Both families release-blocking for any new table/path |
| `/docs` | The nine authoritative planning documents | **Read-only** during implementation; never edited except through an approved ACR |
| `/project` | This engineering operating system | Kept current at the end of every phase/slice |

## Naming Conventions

- **Mandatory terminology (F9):** Workspace Owner, Space Owner, Private
  Space, Shared Space, Privacy Level, Privately Hosted — used in code,
  comments, commit messages, and UI copy wherever bare "Owner," "private,"
  or "shared" would be ambiguous.
- Database tables/columns: `snake_case`. TypeScript types/interfaces:
  `PascalCase`. Variables/functions: `camelCase`. React components:
  `PascalCase` filenames matching the exported component.
- Protected write services are named as verbs describing the operation
  (`createBillOccurrence`, `recordPayment`, `removeMember`), not generic
  CRUD verbs, so intent is legible in code review.
- Route segments and file names never contain the word "workspace" — that
  concept is invisible in the UI and should stay invisible in URLs.

## Service-Layer Rules (`/lib/services`)

- Every polymorphic write (tags, attachments, relationships, reminders,
  daily_priorities, Inbox conversion) and every multi-step write
  (Appointment+Event, Bill Occurrence generation, invitation
  creation/revocation, member removal, Space visibility changes, permanent
  deletion) is a single transaction living here — never a direct client
  write, never split across the client and an ad hoc API route.
- Each service validates, in this order: record-type allowance, target
  existence, non-deleted state, matching workspace on all sides,
  authorization, **visibility coherence** (amendment 8.4 — the acting member
  can see every record involved), and duplicate/self-reference prevention.
- RLS is the baseline, never the sole integrity control for a polymorphic
  reference (D17). A service must not assume RLS alone makes a write safe.
- No service silently swallows a partial failure; failed multi-step writes
  roll back completely and surface a plain-language retry message.

## Query-Layer Rules (`/lib/queries`)

- There is exactly **one** shared query-building helper enforcing Space
  visibility and Privacy Level filtering. Every list, detail fetch, search,
  count, calendar feed, preview, and suggestion goes through it — never
  per-screen filtering logic (amendment 6.7, 8.2).
- No query path may leak another member's Private-Space or "Only me"
  content — not in a count, not in a preview, not in an error message.
- Restricted records are excluded from every broad view unless the current
  request is a deliberate, intentional access to that specific record
  (D10) — enforced in the helper, not re-implemented per feature.

## UI Standards

- No technical terms in the interface, ever: database, schema, entity,
  polymorphic, foreign key, junction table, query, workspace, role,
  permission (MVP Scope "Explicitly Prohibited").
- Nothing enters a primary v1 flow unless the majority of users need it
  there (the complexity budget rule, D27). Advanced fields live behind
  "More options."
- Completing a Task, recording a payment, and changing an Assignment status
  are each one tap with Undo — never a confirmation dialog.
- The only two sharing-related UI controls that may ever exist: the
  per-Space "Is this Space private or shared?" question, and the optional
  "Only me" lock option. Nothing else, anywhere (amendment 10.5).
- Every screen must be usable keyboard-only and clean under axe-core
  (WCAG 2.1 AA practices) before it ships.

## Testing Expectations

- Vitest covers services and validation, including failure/rollback paths.
- Every new polymorphic table or cross-visibility path ships **both**
  release-blocking policy-test families: cross-workspace access blocked,
  and cross-visibility access blocked (amendment 8.7).
- Playwright covers the primary journey on desktop **and** mobile viewports
  for every UI phase.
- The 13 simplicity acceptance criteria (`LifeOS-Source-of-Truth.md`) are
  release-blocking Playwright tests, not optional polish.
- axe-core runs clean on every screen; manual keyboard passes are required
  for primary journeys.
- No feature is Done with a passing test suite that was weakened to pass —
  fix the code, not the assertion.

## Documentation Expectations

- `/project/PROJECT_STATUS.md` is updated at the end of every phase/slice —
  infra, deployment, and phase-completion state must never go stale by more
  than one slice.
- `/project/NEXT_STEPS.md` is re-sliced whenever the roadmap changes.
- Every PR description explains *why*, not just *what* — link back to the
  Decision Register ID or planning-document section a change implements.
- `/docs` is never edited during implementation. A discovered
  inconsistency in `/docs` is recorded as a note (in `PROJECT_STATUS.md` or
  the PR description) and raised to the project owner, never silently
  patched.

## Security Rules

- Manual permanent deletion: Workspace-Owner-only for shared records,
  creator-only for private records. The Trash-expiration job is the only
  automatic caller of the protected deletion service.
- Files are served only via server-checked, short-lived signed URLs — never
  a public URL.
- Closed sign-up; the second account exists only through a valid,
  unexpired, unrevoked invitation, consumed atomically.
- Never store full account/card numbers, security codes, or passwords in
  any field. Never use payment-sending language ("Pay," "Send,"
  "Transfer") — LifeOS records payments, it never sends them.
- No AI-initiated write of any kind without explicit user confirmation
  first.
- Error tracking (once added, D30) transmits technical diagnostics only —
  never private-record content.
- Every protected write validates visibility coherence — a member can never
  touch a record they cannot see, even by guessing its identifier.

## Environment Variable Rules

- No real Supabase keys, database URLs, service-role keys, tokens, or
  passwords are ever committed — not in code, not in `.env.example`, not in
  a test fixture, not in a comment.
- `.env.example` documents variable **names** with placeholder values only,
  and is kept in sync with what the code actually reads.
- Real secrets live in `.env.local` (already git-ignored) or in the hosting
  platform's own environment-variable store (Vercel project settings,
  Supabase project settings) — never in the repository.
- A service-role or other elevated Supabase key, once it's needed, is used
  only from server-side code inside `/lib/services` — never exposed to the
  client, never prefixed `NEXT_PUBLIC_`.
- If a secret is ever accidentally committed, it is treated as compromised:
  rotate it at the provider, do not just delete it from a future commit.

## Git Commit Standards

- Feature branches only; no direct commits to `main` once branch
  protection is configured.
- Small, single-purpose commits with descriptive messages explaining why,
  matching this repository's existing commit style.
- Never `--amend` a commit that has already been pushed/reviewed; never
  force-push over shared history without explicit, scoped permission.
- Never skip hooks (`--no-verify`) or bypass signing.
- Numbered migrations are committed as their own commit(s), never squashed
  together with unrelated feature code.
- Every PR passes lint, typecheck, unit tests, and build before it's
  proposed as ready for review — these are not "cleanup later" items.
