-- Slice 1 / ACR-001 §4.5 — invitations
--
-- The record of an outstanding or resolved invitation from the Workspace
-- Owner to a prospective Member (ACR-001 §4.5, Sourced B6, B7, B8, B9).
--
-- token_hash stores only a deterministic HMAC-SHA-256 digest of the
-- invitation token (ACR-001 Decision 6). Computing that digest with a
-- server-only secret is application/service-layer logic (Slice 16) --
-- this migration only provides the storage column; no plaintext token is
-- ever stored here, and no database-side hashing is performed.
--
-- expires_at's default relies on now() being transaction-stable (the same
-- value for every call within one transaction, unlike clock_timestamp()),
-- so a single INSERT's created_at and expires_at defaults resolve from
-- the same instant, keeping expires_at exactly 7 days after created_at
-- for any row that uses both defaults as-is. A caller that explicitly
-- overrides created_at while leaving expires_at on its default will not
-- get this alignment -- per instruction, no trigger, generated column, or
-- cross-column constraint is added to address that; the future service
-- layer is responsible for supplying consistent values if it ever departs
-- from the defaults.
create table invitations (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces (id),
  invited_email text not null,
  token_hash text not null,
  status text not null default 'pending',
  created_by uuid not null references profiles (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days'),
  accepted_at timestamptz,
  constraint invitations_status_check check (status in ('pending', 'accepted', 'revoked', 'expired')),
  constraint invitations_token_hash_unique unique (token_hash)
);

-- Derived from B7: "At most one invitation may exist at a time." A
-- partial index, so accepted/revoked/expired rows fall outside its scope
-- and never block a new pending invitation for the same workspace.
create unique index invitations_one_pending_per_workspace
  on invitations (workspace_id)
  where status = 'pending';

-- Standalone, non-partial index: the pending-only index above doesn't
-- cover accepted/revoked/expired rows, and general workspace_id lookups
-- need all statuses.
create index invitations_workspace_id_idx on invitations (workspace_id);

create trigger invitations_set_updated_at
  before update on invitations
  for each row
  when (old is distinct from new)
  execute function set_updated_at();
