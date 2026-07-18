# db/migrations

Numbered, ordered SQL migrations, each with a paired down-migration,
following the 13-stage migration order in `LifeOS-Technical-Handoff.md`. No
manual database changes.

**Slice 1 (migration stage 1 — identity/ownership) is implemented:**

- `0001_profiles` — per-user identity record, shared primary key with
  `auth.users`.
- `0002_workspaces` — the single invisible container anchoring every Space
  and record.
- `0003_workspace_members` — membership, role, and standing, including the
  two-active-member-per-workspace database backstop.
- `0004_user_settings` — per-user settings, owning `time_zone`.
- `0005_invitations` — outstanding/resolved invitation records.

These five migrations implement the schema approved in
`project/architecture/ACR-001-Slice-1-Identity-and-Workspace-Schema.md` and
passed a full clean-room verification (fresh apply, rollback, and
reapplication against PostgreSQL 16, plus a combined behavioral test
suite) before being committed.

**Not included in these migrations:** any application-layer behavior (no
services, no sign-up/invitation logic), Row-Level Security (no
`ENABLE ROW LEVEL SECURITY`, no policies — deferred in full to a future
slice), or any migration beyond stage 1. See `project/NEXT_STEPS.md` for
the full roadmap.
