-- Slice 1 / ACR-001 §4.3 — workspace_members
--
-- The join table expressing who belongs to a workspace, in what role, and
-- their current standing (active or removed) (ACR-001 §4.3, Sourced B1,
-- B2, B3, B6).
create table workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces (id),
  user_id uuid not null references profiles (id),
  role text not null,
  status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint workspace_members_role_check check (role in ('owner', 'member')),
  constraint workspace_members_status_check check (status in ('active', 'removed')),
  -- Decision 5: exactly one row ever exists per (workspace_id, user_id)
  -- pair, for the lifetime of that relationship; re-inviting a previously
  -- removed person reactivates this same row rather than inserting a new
  -- one.
  constraint workspace_members_workspace_user_unique unique (workspace_id, user_id)
);

-- Decisions 2 & 5: a user may have at most one active workspace membership
-- at a time, globally.
create unique index workspace_members_one_active_per_user
  on workspace_members (user_id)
  where status = 'active';

-- "The hottest lookup path in the schema" (ACR-001 §4.3) — every future
-- RLS policy and membership query joins through this table.
create index workspace_members_workspace_id_idx on workspace_members (workspace_id);
create index workspace_members_user_id_idx on workspace_members (user_id);

create trigger workspace_members_set_updated_at
  before update on workspace_members
  for each row
  when (old is distinct from new)
  execute function set_updated_at();

-- Two-active-members-per-workspace backstop (ACR-001 Decision 11).
--
-- Concurrency strategy (reviewed and approved separately): locks the
-- parent `workspaces` row(s) via SELECT ... FOR UPDATE before counting,
-- rather than an advisory lock or SERIALIZABLE isolation. Only runs when
-- the resulting row is active — an active -> removed update is always
-- allowed and never locks or counts.
--
-- workspace_id is not immutable at the schema level (no immutability
-- trigger/constraint has been added), so an UPDATE can in principle move
-- a membership row from one workspace to another. When it does, both the
-- old and new workspace rows are locked, in a deterministic order
-- (ascending uuid comparison), to prevent a deadlock between two
-- transactions moving members between the same two workspaces in
-- opposite directions. The active-member count is enforced only against
-- the destination (NEW.workspace_id) — leaving a workspace never
-- increases its own count.
--
-- Stable error identification for the service layer to catch:
--   SQLSTATE:   LI001
--   CONSTRAINT: workspace_members_active_limit
--   MESSAGE:    workspace_members active-member limit exceeded
create function enforce_workspace_member_limit()
returns trigger
language plpgsql
as $$
declare
  active_count integer;
begin
  if new.status <> 'active' then
    return new;
  end if;

  if tg_op = 'INSERT' then
    perform 1 from workspaces where id = new.workspace_id for update;
  elsif old.workspace_id is distinct from new.workspace_id then
    if old.workspace_id < new.workspace_id then
      perform 1 from workspaces where id = old.workspace_id for update;
      perform 1 from workspaces where id = new.workspace_id for update;
    else
      perform 1 from workspaces where id = new.workspace_id for update;
      perform 1 from workspaces where id = old.workspace_id for update;
    end if;
  else
    perform 1 from workspaces where id = new.workspace_id for update;
  end if;

  select count(*) into active_count
  from workspace_members
  where workspace_id = new.workspace_id
    and status = 'active'
    and id <> new.id;

  if active_count >= 2 then
    raise exception using
      errcode = 'LI001',
      message = 'workspace_members active-member limit exceeded',
      constraint = 'workspace_members_active_limit',
      detail = format(
        'workspace_id %s already has %s active member(s)',
        new.workspace_id,
        active_count
      );
  end if;

  return new;
end;
$$;

create trigger workspace_members_enforce_limit
  before insert or update on workspace_members
  for each row
  execute function enforce_workspace_member_limit();
