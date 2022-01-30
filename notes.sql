
-- get replies count
drop view sce_comments_with_metadata;
create view sce_comments_with_metadata as select *, (select count(*) from sce_comments as c where c.parent_id = sce_comments.id) as replies_count from sce_comments;

-- unique constraint on comment_reactions
ALTER TABLE sce_comment_reactions ADD UNIQUE (user_id, comment_id, reaction_type);

-- aggregate metadata for comment reactions
create or replace view sce_comment_reactions_metadata as SELECT comment_id, reaction_type, COUNT(*) as reaction_count, BOOL_OR(user_id = auth.uid()) as active_for_user FROM sce_comment_reactions GROUP BY (comment_id, reaction_type) ORDER BY reaction_type;

-- display_users view for user avatars
create or replace view sce_display_users as select 
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


-- cascade deletes for comments to delete replies when parent deleted
alter table public.sce_comments
drop constraint sce_comments_parent_id_fkey;
alter table public.sce_comments
add constraint sce_comments_parent_id_fkey
   foreign key (parent_id)
   references public.sce_comments (id)
   on delete cascade;

-- add some basic reactions
insert into sce_reactions(type, label, url) values ('heart', 'Heart', 'https://emojis.slackmojis.com/emojis/images/1596061862/9845/meow_heart.png?1596061862');
insert into sce_reactions(type, label, url) values ('like', 'Like', 'https://emojis.slackmojis.com/emojis/images/1588108689/8789/fb-like.png?1588108689');
insert into sce_reactions(type, label, url) values ('party-blob', 'Party Blob', 'https://emojis.slackmojis.com/emojis/images/1547582922/5197/party_blob.gif?1547582922');

  





-- GENERATED FROM MIGRA
create table "public"."comment_reactions" (
    "id" uuid not null default uuid_generate_v4(),
    "created_at" timestamp with time zone default now(),
    "comment_id" uuid not null,
    "user_id" uuid not null,
    "reaction_type" character varying not null
);


create table "public"."comments" (
    "id" uuid not null default uuid_generate_v4(),
    "created_at" timestamp with time zone default now(),
    "topic" character varying not null,
    "comment" character varying not null,
    "user_id" uuid not null,
    "parent_id" uuid,
    "mentioned_user_ids" uuid[] not null default '{}'::uuid[]
);


create table "public"."profiles" (
    "id" uuid not null,
    "created_at" timestamp with time zone default now(),
    "name" character varying,
    "avatar" character varying
);


create table "public"."reactions" (
    "type" character varying not null,
    "created_at" timestamp with time zone default now(),
    "metadata" jsonb
);


CREATE UNIQUE INDEX comment_reactions_pkey ON public.comment_reactions USING btree (id);

CREATE UNIQUE INDEX comment_reactions_user_id_comment_id_reaction_type_key ON public.comment_reactions USING btree (user_id, comment_id, reaction_type);

CREATE UNIQUE INDEX comments_pkey ON public.comments USING btree (id);

CREATE UNIQUE INDEX profiles_pkey ON public.profiles USING btree (id);

CREATE UNIQUE INDEX reactions_pkey ON public.reactions USING btree (type);

alter table "public"."comment_reactions" add constraint "comment_reactions_pkey" PRIMARY KEY using index "comment_reactions_pkey";

alter table "public"."comments" add constraint "comments_pkey" PRIMARY KEY using index "comments_pkey";

alter table "public"."profiles" add constraint "profiles_pkey" PRIMARY KEY using index "profiles_pkey";

alter table "public"."reactions" add constraint "reactions_pkey" PRIMARY KEY using index "reactions_pkey";

alter table "public"."comment_reactions" add constraint "comment_reactions_comment_id_fkey" FOREIGN KEY (comment_id) REFERENCES comments(id);

alter table "public"."comment_reactions" add constraint "comment_reactions_reaction_type_fkey" FOREIGN KEY (reaction_type) REFERENCES reactions(type);

alter table "public"."comment_reactions" add constraint "comment_reactions_user_id_comment_id_reaction_type_key" UNIQUE using index "comment_reactions_user_id_comment_id_reaction_type_key";

alter table "public"."comment_reactions" add constraint "comment_reactions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id);

alter table "public"."comments" add constraint "comments_parent_id_fkey" FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE;

alter table "public"."comments" add constraint "comments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id);

alter table "public"."profiles" add constraint "profiles_id_fkey" FOREIGN KEY (id) REFERENCES auth.users(id);

set check_function_bodies = off;

create or replace view "public"."comment_reactions_metadata" as  SELECT comment_reactions.comment_id,
    comment_reactions.reaction_type,
    count(*) AS reaction_count,
    bool_or((comment_reactions.user_id = auth.uid())) AS active_for_user
   FROM comment_reactions
  GROUP BY comment_reactions.comment_id, comment_reactions.reaction_type;


create or replace view "public"."comment_reactions_metadata_two" as  SELECT comment_reactions.comment_id,
    comment_reactions.reaction_type,
    count(*) AS reaction_count
   FROM comment_reactions
  GROUP BY comment_reactions.comment_id, comment_reactions.reaction_type;


create or replace view "public"."comments_with_metadata" as  SELECT comments.id,
    comments.created_at,
    comments.topic,
    comments.comment,
    comments.user_id,
    comments.parent_id,
    comments.mentioned_user_ids,
    ( SELECT count(*) AS count
           FROM comments c
          WHERE (c.parent_id = comments.id)) AS replies_count
   FROM comments;


create or replace view "public"."display_users" as  SELECT users.id,
    COALESCE((users.raw_user_meta_data ->> 'name'::text), (users.raw_user_meta_data ->> 'full_name'::text), (users.raw_user_meta_data ->> 'user_name'::text)) AS name,
    COALESCE((users.raw_user_meta_data ->> 'avatar_url'::text), (users.raw_user_meta_data ->> 'avatar'::text)) AS avatar
   FROM auth.users;











-- MIGRA DIFF TWO
create table "public"."comment_reactions" (
    "id" uuid not null default uuid_generate_v4(),
    "created_at" timestamp with time zone default now(),
    "comment_id" uuid not null,
    "user_id" uuid not null,
    "reaction_type" character varying not null
);


create table "public"."comments" (
    "id" uuid not null default uuid_generate_v4(),
    "created_at" timestamp with time zone default now(),
    "topic" character varying not null,
    "comment" character varying not null,
    "user_id" uuid not null,
    "parent_id" uuid,
    "mentioned_user_ids" uuid[] not null default '{}'::uuid[]
);


create table "public"."reactions" (
    "type" character varying not null,
    "created_at" timestamp with time zone default now(),
    "metadata" jsonb,
    "label" character varying not null,
    "url" character varying not null
);


CREATE UNIQUE INDEX comment_reactions_pkey ON public.comment_reactions USING btree (id);

CREATE UNIQUE INDEX comment_reactions_user_id_comment_id_reaction_type_key ON public.comment_reactions USING btree (user_id, comment_id, reaction_type);

CREATE UNIQUE INDEX comments_pkey ON public.comments USING btree (id);

CREATE UNIQUE INDEX reactions_pkey ON public.reactions USING btree (type);

alter table "public"."comment_reactions" add constraint "comment_reactions_pkey" PRIMARY KEY using index "comment_reactions_pkey";

alter table "public"."comments" add constraint "comments_pkey" PRIMARY KEY using index "comments_pkey";

alter table "public"."reactions" add constraint "reactions_pkey" PRIMARY KEY using index "reactions_pkey";

alter table "public"."comment_reactions" add constraint "comment_reactions_comment_id_fkey" FOREIGN KEY (comment_id) REFERENCES comments(id);

alter table "public"."comment_reactions" add constraint "comment_reactions_reaction_type_fkey" FOREIGN KEY (reaction_type) REFERENCES reactions(type);

alter table "public"."comment_reactions" add constraint "comment_reactions_user_id_comment_id_reaction_type_key" UNIQUE using index "comment_reactions_user_id_comment_id_reaction_type_key";

alter table "public"."comment_reactions" add constraint "comment_reactions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id);

alter table "public"."comments" add constraint "comments_parent_id_fkey" FOREIGN KEY (parent_id) REFERENCES comments(id) ON DELETE CASCADE;

alter table "public"."comments" add constraint "comments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id);

set check_function_bodies = off;

create or replace view "public"."comment_reactions_metadata" as  SELECT comment_reactions.comment_id,
    comment_reactions.reaction_type,
    count(*) AS reaction_count,
    bool_or((comment_reactions.user_id = auth.uid())) AS active_for_user
   FROM comment_reactions
  GROUP BY comment_reactions.comment_id, comment_reactions.reaction_type
  ORDER BY comment_reactions.reaction_type;


create or replace view "public"."comment_reactions_metadata_two" as  SELECT comment_reactions.comment_id,
    comment_reactions.reaction_type,
    count(*) AS reaction_count
   FROM comment_reactions
  GROUP BY comment_reactions.comment_id, comment_reactions.reaction_type;


create or replace view "public"."comments_with_metadata" as  SELECT comments.id,
    comments.created_at,
    comments.topic,
    comments.comment,
    comments.user_id,
    comments.parent_id,
    comments.mentioned_user_ids,
    ( SELECT count(*) AS count
           FROM comments c
          WHERE (c.parent_id = comments.id)) AS replies_count
   FROM comments;


create or replace view "public"."display_users" as  SELECT users.id,
    COALESCE((users.raw_user_meta_data ->> 'name'::text), (users.raw_user_meta_data ->> 'full_name'::text), (users.raw_user_meta_data ->> 'user_name'::text)) AS name,
    COALESCE((users.raw_user_meta_data ->> 'avatar_url'::text), (users.raw_user_meta_data ->> 'avatar'::text)) AS avatar
   FROM auth.users;


CREATE OR REPLACE FUNCTION public.pgrst_watch()
 RETURNS event_trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
  NOTIFY pgrst, 'reload schema';
END;
$function$
;

