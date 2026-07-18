create or replace function complete_onboarding(
  p_user_id uuid,
  p_time_zone text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_workspace_id uuid;
  v_time_zone text := coalesce(nullif(p_time_zone, ''), 'UTC');
  v_existing_role text;
  v_existing_status text;
begin
  insert into profiles (id)
  values (p_user_id)
  on conflict (id) do nothing;

  perform 1 from profiles where id = p_user_id for update;

  select wm.role, wm.status, wm.workspace_id
    into v_existing_role, v_existing_status, v_workspace_id
  from workspace_members wm
  where wm.user_id = p_user_id
  order by wm.created_at
  limit 1;

  if v_existing_role = 'owner' and v_existing_status = 'active' then
    return v_workspace_id;
  end if;

  if v_existing_role = 'member' then
    raise exception using
      errcode = 'LI002',
      message = 'complete_onboarding called for a user who is already a workspace member',
      constraint = 'onboarding_not_for_existing_member';
  end if;

  if v_existing_role = 'owner' and v_existing_status = 'removed' then
    raise exception using
      errcode = 'LI003',
      message = 'complete_onboarding called for a user with a removed owner membership; no approved recovery path exists',
      constraint = 'onboarding_no_removed_owner_path';
  end if;

  insert into workspaces default values
  returning id into v_workspace_id;

  insert into workspace_members (workspace_id, user_id, role, status)
  values (v_workspace_id, p_user_id, 'owner', 'active');

  insert into user_settings (user_id, time_zone)
  values (p_user_id, v_time_zone)
  on conflict (user_id) do nothing;

  return v_workspace_id;
end;
$$;

revoke all on function complete_onboarding(uuid, text) from public, anon, authenticated;
grant execute on function complete_onboarding(uuid, text) to service_role;
