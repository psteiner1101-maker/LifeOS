-- Reverses 0003_workspace_members.up.sql.
--
-- Constraints and indexes defined inline on the table (unique, check,
-- both plain indexes, the partial unique index) drop automatically with
-- the table itself.
drop trigger if exists workspace_members_enforce_limit on workspace_members;

drop function if exists enforce_workspace_member_limit();

drop trigger if exists workspace_members_set_updated_at on workspace_members;

drop table if exists workspace_members;
