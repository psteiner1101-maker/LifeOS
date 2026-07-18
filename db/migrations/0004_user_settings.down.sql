-- Reverses 0004_user_settings.up.sql.
--
-- Does not touch profiles, workspaces, workspace_members, or the shared
-- set_updated_at() function.
drop trigger if exists user_settings_set_updated_at on user_settings;

drop table if exists user_settings;
