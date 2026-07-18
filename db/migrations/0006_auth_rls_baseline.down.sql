-- Reverses 0006_auth_rls_baseline.up.sql.
drop policy if exists user_settings_select_own on user_settings;
drop policy if exists profiles_select_own on profiles;

alter table invitations disable row level security;
alter table workspace_members disable row level security;
alter table workspaces disable row level security;
alter table user_settings disable row level security;
alter table profiles disable row level security;
