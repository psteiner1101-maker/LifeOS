# Definition of Done

This is the release gate for every LifeOS feature, slice, or fix from the
foundation feature slice onward. A feature is not "basically done" or "done
except for tests" — it is either Done, meeting every item below, or it is
not merged. This expands `LifeOS-Implementation-Blueprint.md` §14 into a
concrete checklist; where the two differ, the Blueprint governs.

## Checklist

A feature is Done only when **all** of the following are true:

- [ ] **Implementation** matches its approved-document behavior exactly, with
      no deviation — or an approved ACR exists documenting and authorizing
      the deviation.
- [ ] **Unit tests** (Vitest) cover the feature's services and validation,
      including failure and rollback paths — not just the happy path.
- [ ] **Policy tests** (when applicable — i.e., the feature touches a
      polymorphic table, a new visibility path, or workspace-scoped data)
      prove both release-blocking families: cross-workspace access blocked,
      and cross-visibility access blocked (amendment 8.7).
- [ ] **Playwright tests** cover the feature's primary user journey on both
      desktop and mobile viewports.
- [ ] **Accessibility verification**: axe-core reports zero violations on
      every new/changed screen, and a manual keyboard-only pass completes
      the journey without a mouse.
- [ ] **TypeScript clean**: `npm run typecheck` passes with zero errors, no
      new `any` in services or validation code.
- [ ] **ESLint clean**: `npm run lint` passes with zero errors.
- [ ] **Production build passes**: `npm run build` succeeds.
- [ ] **Documentation updated**: `/project/PROJECT_STATUS.md` reflects the
      new state (phase completion, infra, open issues); `/project/NEXT_STEPS.md`
      re-sliced if the roadmap shifted; any new service/table documented
      inline (folder README or code comments) where its purpose isn't
      obvious from naming.
- [ ] **No architectural violations**: nothing on the Deferred or Prohibited
      lists was built; every protected write lives in `/lib/services`; every
      broad read goes through the shared query helper in `/lib/queries`; no
      approved decision was changed without an ACR.
- [ ] **No prohibited terminology**: a manual or scripted sweep of new UI
      copy, code comments, and commit messages confirms none of "database,"
      "schema," "entity," "polymorphic," "foreign key," "junction table,"
      "query," "workspace," bare "owner/private/shared" (where ambiguous),
      or payment-sending language ("Pay," "Send," "Transfer") leaked into
      anything user-facing.
- [ ] **Pull request created**, passing all of the above in CI (once CI
      exists) or verified manually and stated as such in the PR description,
      referencing the Decision Register ID(s) or planning-document
      section(s) implemented.

## Notes

- "When applicable" for policy tests means: skipped only for changes with
  no new table, no new visibility path, and no workspace-scoped data —
  which will be rare after the foundation slice. Default to writing them;
  justify skipping them in the PR description if you don't.
- A weakened test that passes is worse than a failing test that's honest.
  Never adjust an assertion to make a broken feature look Done.
- This checklist applies identically whether the author is a human
  contributor or Claude Code.
