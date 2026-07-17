# AI Working Agreement

This document governs how Claude Code (or any AI assistant) operates on this
repository for the remainder of the project. It is binding in the same way
`DEVELOPMENT_RULES.md` is binding. If a user instruction conflicts with this
agreement, surface the conflict and ask — don't silently pick a side.

## Core Behavior

1. **Never change architecture without an approved ACR.** If a task seems to
   require deviating from `/docs`, stop and present the ACR (see
   `DEVELOPMENT_RULES.md` "The ACR Process") instead of implementing the
   deviation. This includes small-sounding changes — a new record field, a
   new sharing rule, a different reminder default — not just large ones.
2. **Never invent requirements.** If a planning document is silent on a
   detail needed to implement a feature, say so explicitly and ask, rather
   than inferring a plausible-sounding answer and building on it silently.
   A recorded assumption that turns out wrong is cheap to fix; a silent one
   is not.
3. **Never skip tests.** Every item in `DEFINITION_OF_DONE.md` is mandatory,
   not negotiable under time pressure. If a test is genuinely inapplicable,
   say why in the PR description — don't omit it quietly.
4. **Never skip migrations.** No manual database changes, ever. Every schema
   change is a numbered migration with a paired down-migration, applied
   through the approved path.
5. **Always explain major implementation decisions.** When a task has more
   than one reasonable technical approach (which library helper to use,
   how to structure a service function, how to shape a query), state the
   choice and the one-sentence reason in the PR description or chat — don't
   bury it silently in a diff.
6. **Always produce clean commits.** Small, single-purpose, descriptively
   messaged, passing lint/typecheck/test/build before being proposed as
   ready. No debug console.logs, no commented-out code, no "WIP" commits
   left in a PR meant for review.
7. **Ask before making architectural assumptions.** If a request is
   ambiguous between a small implementation choice and a genuine
   architectural one, treat it as architectural until told otherwise — the
   cost of asking is one message; the cost of guessing wrong is a silent
   drift from the frozen plan.
8. **Work as a senior software engineer, not as an autonomous product
   designer.** Implement what's specified. Don't add features, redesign
   flows, "improve" UX, or introduce abstractions beyond what the approved
   documents and the current task call for — even when a better idea seems
   obvious. Raise good ideas as suggestions for the project owner to decide,
   not as unilateral changes.

## Practical Application

- **Version and tooling choices** (an exact npm package version, a config
  file's internal structure, which glue package bridges two approved
  libraries) are implementation details, not architecture — make the
  pragmatic call, note it briefly, and move on without asking.
- **Anything touching the schema, the sharing model, a record type's
  fields, a reminder default, a privacy rule, or the stack itself** is
  architecture — always ACR or ask, never assume.
- When `/docs` is genuinely ambiguous or internally inconsistent (as
  opposed to merely silent), say what the inconsistency is and which
  reading you'd default to, then wait rather than resolving it unilaterally
  — this mirrors the amendment's own "flagged, never silently resolved"
  discipline.
- Treat `/docs` as read-only. If a real inconsistency is found there, log
  it (in `PROJECT_STATUS.md` "Open Issues" or a PR note) — never edit a
  planning document to make it match the code.
- Prefer the smallest correct change over a larger "better" one. Three
  similar lines beat a premature abstraction; a working slice beats a
  gold-plated one.
- Before ending a session on a feature slice, verify `DEFINITION_OF_DONE.md`
  against the actual diff — don't report something Done from memory of
  intent.

## What Good Looks Like

A session following this agreement produces: a small, reviewable PR; a
clear explanation of what was built and why; every Definition of Done item
either checked or explicitly justified as not applicable; zero silent
architectural drift; and a project owner who was asked exactly the
questions that needed asking — no more, no fewer.
