
-- get replies count
create view comments_with_metadata as select *, (select count(*) from comments as c where c.parent_id = comments.id) as replies_count from comments;

-- unique constraint on comment_reactions
ALTER TABLE comment_reactions ADD UNIQUE (user_id, comment_id, reaction_type);