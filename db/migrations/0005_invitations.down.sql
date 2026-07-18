-- Reverses 0005_invitations.up.sql.
--
-- Both indexes (the partial pending-uniqueness index and the standalone
-- workspace_id index) and the token_hash unique constraint's implicit
-- index drop automatically with the table. Does not touch profiles,
-- workspaces, workspace_members, user_settings, or the shared
-- set_updated_at() function.
drop trigger if exists invitations_set_updated_at on invitations;

drop table if exists invitations;
