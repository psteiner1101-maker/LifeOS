-- Slice 1 / ACR-001 §4.2 — workspaces
--
-- The single invisible container anchoring every Space and record for one
-- Privately Hosted instance (ACR-001 §4.2, Sourced B1, B2). Ownership is
-- represented only via workspace_members.role = 'owner' — deliberately no
-- owner_user_id column here (ACR-001 Decision 3), and no name field, since
-- "workspace" never appears in the UI.
create table workspaces (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger workspaces_set_updated_at
  before update on workspaces
  for each row
  when (old is distinct from new)
  execute function set_updated_at();
