-- Reverses 0002_workspaces.up.sql.
--
-- Does not touch the shared set_updated_at() function — that is only
-- dropped in 0001's down-migration, after every table depending on it
-- (this one included) has already been rolled back.
drop trigger if exists workspaces_set_updated_at on workspaces;

drop table if exists workspaces;
