
-- get replies count
create view comments_with_metadata as select *, (select count(*) from comments as c where c.parent_id = comments.id) as replies_count from comments;

-- unique constraint on comment_reactions
ALTER TABLE comment_reactions ADD UNIQUE (user_id, comment_id, reaction_type);

-- aggregate metadata for comment reactions
create view comment_reactions_metadata as SELECT comment_id, reaction_type, COUNT(*) as reaction_count, BOOL_OR(user_id = auth.uid()) as active_for_user FROM comment_reactions GROUP BY (comment_id, reaction_type);

-- display_users view for user avatars
create or replace view display_users as select 
  id, 
  coalesce(raw_user_meta_data ->> 'name', raw_user_meta_data ->> 'full_name', raw_user_meta_data ->> 'user_name') as name, 
  coalesce(raw_user_meta_data ->> 'avatar_url', raw_user_meta_data ->> 'avatar') as avatar 
from auth.users;

-- RELOADING SCHEMA CACHE
-- Create an event trigger function
CREATE OR REPLACE FUNCTION public.pgrst_watch() RETURNS event_trigger
  LANGUAGE plpgsql
  AS $$
BEGIN
  NOTIFY pgrst, 'reload schema';
END;
$$;

-- This event trigger will fire after every ddl_command_end event
CREATE EVENT TRIGGER pgrst_watch
  ON ddl_command_end
  EXECUTE PROCEDURE public.pgrst_watch();

-- works but likely a bad idea cause of privacy
SELECT split_part(email, '@', 1) as display_name from auth.users;

