# LifeOS

Personal operating system for school-plus-everyday life. Planning is complete
and frozen — see [`/docs`](./docs) for the nine authoritative planning
documents (start with `LifeOS-Master-Reference.md`).

## Project state

**Phase 1 (project foundation) and Slice 1 (database schema) are complete.**
The five identity/workspace-ownership migrations (`profiles`, `workspaces`,
`workspace_members`, `user_settings`, `invitations`) are implemented,
verified, and merged. No LifeOS feature, authentication, or RLS beyond a
minimal planned baseline exists yet — see `project/PROJECT_STATUS.md` for
the current, verified state of the repository, and
`project/NEXT_STEPS.md` for the full roadmap and the next slice's
fully-planned (not yet implemented) design. New to this repository? Start
at `project/RECOVERY.md`; for local setup, see `project/SETUP.md`.

## Stack

Next.js (TypeScript, App Router) · Tailwind CSS · shadcn/ui · Supabase
(Auth, PostgreSQL, Storage) · Vercel · date-fns / date-fns-tz ·
React Hook Form + Zod · Tiptap · FullCalendar (free tier) · Vitest ·
Playwright · axe-core.

## Getting started

1. Copy `.env.example` to `.env.local` and fill in your own Supabase project's
   URL and publishable/anon key. Never commit `.env.local`.
2. `npm install`
3. `npm run dev`

## Scripts

| Script                 | Purpose                       |
| ---------------------- | ----------------------------- |
| `npm run dev`          | Start the Next.js dev server  |
| `npm run build`        | Production build              |
| `npm run start`        | Run the production build      |
| `npm run lint`         | ESLint                        |
| `npm run typecheck`    | `tsc --noEmit`                |
| `npm run test`         | Unit tests (Vitest)           |
| `npm run test:e2e`     | End-to-end tests (Playwright) |
| `npm run format`       | Check formatting (Prettier)   |
| `npm run format:write` | Apply formatting (Prettier)   |

## Project structure

```
/app                    Next.js App Router routes
/components             UI components (shadcn/ui-based)
/components/ui          shadcn/ui primitives
/lib/supabase           Browser + server Supabase clients, session middleware
/lib/services           Protected server-side write services (future)
/lib/queries            Read helpers, incl. shared visibility/privacy query helper (future)
/lib/validation         Zod schemas shared by client and server (future)
/lib/dates              date-fns wrappers, time-zone resolution (future)
/db/migrations          Numbered, ordered SQL migrations (Slice 1 schema implemented)
/jobs                   Supabase Scheduled Function sources (future)
/tests/unit             Vitest
/tests/e2e              Playwright
/tests/policies         Cross-workspace / cross-visibility access tests (future)
/docs                   The nine authoritative planning documents
```
