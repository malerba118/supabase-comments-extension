alter table "public"."sce_comment_reactions" enable row level security;

alter table "public"."sce_comments" enable row level security;

alter table "public"."sce_reactions" enable row level security;

create policy "Enable access to all users"
on "public"."sce_comment_reactions"
as permissive
for select
to public
using (true);


create policy "Enable delete for users based on user_id"
on "public"."sce_comment_reactions"
as permissive
for delete
to public
using ((auth.uid() = user_id));


create policy "Enable insert for authenticated users only"
on "public"."sce_comment_reactions"
as permissive
for insert
to public
with check ((auth.role() = 'authenticated'::text) AND (user_id = auth.uid()));


create policy "Enable update for users based on user_id"
on "public"."sce_comment_reactions"
as permissive
for update
to public
using ((auth.uid() = user_id))
with check (auth.uid() = user_id);


create policy "Enable access to all users"
on "public"."sce_comments"
as permissive
for select
to public
using (true);


create policy "Enable delete for users based on user_id"
on "public"."sce_comments"
as permissive
for delete
to public
using ((auth.uid() = user_id));


create policy "Enable insert for authenticated users only"
on "public"."sce_comments"
as permissive
for insert
to public
with check ((auth.role() = 'authenticated'::text) AND (user_id = auth.uid()));


create policy "Enable update for users based on id"
on "public"."sce_comments"
as permissive
for update
to public
using ((auth.uid() = user_id))
with check (auth.uid() = user_id);


create policy "Enable access to all users"
on "public"."sce_reactions"
as permissive
for select
to public
using (true);
