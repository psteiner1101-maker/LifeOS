-- Reverses 0001_profiles.up.sql.
--
-- Drops the shared `set_updated_at()` function here, last, since
-- down-migrations run in reverse dependency order (invitations →
-- user_settings → workspace_members → workspaces → profiles) and every
-- other table's trigger referencing this function is already gone by the
-- time this file runs (ACR-001 Decision 17).
drop trigger if exists profiles_set_updated_at on profiles;

drop table if exists profiles;

drop function if exists set_updated_at();
