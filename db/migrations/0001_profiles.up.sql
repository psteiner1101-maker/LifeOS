-- Slice 1 / ACR-001 §4.1 — profiles
--
-- Shared trigger function that keeps every Slice 1 table's `updated_at`
-- column current on any row update (ACR-001 Decision 12). Lives in this,
-- the earliest Slice 1 migration with no unmet dependency (ACR-001
-- Decision 17) — reused unchanged by every later Slice 1 migration.
create function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- The per-user identity record created at sign-up, holding personal
-- identity distinct from the workspace (ACR-001 §4.1). `id` equals
-- `auth.users.id` directly — a shared primary key, not a separate
-- `profiles.user_id` column (ACR-001 Decision 1).
create table profiles (
  id uuid primary key references auth.users (id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger profiles_set_updated_at
  before update on profiles
  for each row
  when (old is distinct from new)
  execute function set_updated_at();
