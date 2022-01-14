
-- get replies count
create view comments_with_metadata as select *, (select count(*) from comments as c where c.parent_id = comments.id) as replies_count from comments;
