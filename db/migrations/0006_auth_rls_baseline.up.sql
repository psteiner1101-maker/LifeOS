alter table profiles enable row level security;
alter table user_settings enable row level security;
alter table workspaces enable row level security;
alter table workspace_members enable row level security;
alter table invitations enable row level security;

create policy profiles_select_own
  on profiles for select
  to authenticated
  using (auth.uid() = id);

create policy user_settings_select_own
  on user_settings for select
  to authenticated
  using (auth.uid() = user_id);
