-- Slice 1 / ACR-001 §4.4 — user_settings
--
-- Per-user settings, created with defaults at sign-up/acceptance, owning
-- the user's time zone and governing other personal preferences
-- (ACR-001 §4.4, Sourced B3, B5). Changing a user's time zone never
-- alters profiles (Decision 13) — the two tables stay independent.
--
-- No default for time_zone: ACR-001 leaves the sign-up-time defaulting
-- strategy open, so this column is not null with no default, requiring
-- the future sign-up/acceptance service to supply an explicit value.
create table user_settings (
  user_id uuid primary key references profiles (id) on delete cascade,
  time_zone text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger user_settings_set_updated_at
  before update on user_settings
  for each row
  when (old is distinct from new)
  execute function set_updated_at();
