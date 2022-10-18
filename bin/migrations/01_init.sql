create table "public"."sce_comment_reactions" (
    "id" uuid not null default uuid_generate_v4(),
    "created_at" timestamp with time zone default now(),
    "comment_id" uuid not null,
    "user_id" uuid not null,
    "reaction_type" character varying not null
);

create table "public"."sce_comments" (
    "id" uuid not null default uuid_generate_v4(),
    "created_at" timestamp with time zone default now(),
    "topic" character varying not null,
    "comment" character varying not null,
    "user_id" uuid not null,
    "parent_id" uuid,
    "mentioned_user_ids" uuid [] not null default '{}' :: uuid []
);

create table "public"."sce_reactions" (
    "type" character varying not null,
    "created_at" timestamp with time zone default now(),
    "label" character varying not null,
    "url" character varying not null,
    "metadata" jsonb
);

CREATE UNIQUE INDEX sce_comment_reactions_pkey ON public.sce_comment_reactions USING btree (id);

CREATE UNIQUE INDEX sce_comment_reactions_user_id_comment_id_reaction_type_key ON public.sce_comment_reactions USING btree (user_id, comment_id, reaction_type);

CREATE UNIQUE INDEX sce_comments_pkey ON public.sce_comments USING btree (id);

CREATE UNIQUE INDEX sce_reactions_pkey ON public.sce_reactions USING btree (type);

alter table
    "public"."sce_comment_reactions"
add
    constraint "sce_comment_reactions_pkey" PRIMARY KEY using index "sce_comment_reactions_pkey";

alter table
    "public"."sce_comments"
add
    constraint "sce_comments_pkey" PRIMARY KEY using index "sce_comments_pkey";

alter table
    "public"."sce_reactions"
add
    constraint "sce_reactions_pkey" PRIMARY KEY using index "sce_reactions_pkey";

alter table
    "public"."sce_comment_reactions"
add
    constraint "sce_comment_reactions_comment_id_fkey" FOREIGN KEY (comment_id) REFERENCES sce_comments(id) ON DELETE CASCADE;

alter table
    "public"."sce_comment_reactions"
add
    constraint "sce_comment_reactions_reaction_type_fkey" FOREIGN KEY (reaction_type) REFERENCES sce_reactions(type);

alter table
    "public"."sce_comment_reactions"
add
    constraint "sce_comment_reactions_user_id_comment_id_reaction_type_key" UNIQUE using index "sce_comment_reactions_user_id_comment_id_reaction_type_key";

alter table
    "public"."sce_comment_reactions"
add
    constraint "sce_comment_reactions_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table
    "public"."sce_comments"
add
    constraint "sce_comments_parent_id_fkey" FOREIGN KEY (parent_id) REFERENCES sce_comments(id) ON DELETE CASCADE;

alter table
    "public"."sce_comments"
add
    constraint "sce_comments_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

create
or replace view "public"."sce_comment_reactions_metadata" as
SELECT
    sce_comment_reactions.comment_id,
    sce_comment_reactions.reaction_type,
    count(*) AS reaction_count,
    bool_or((sce_comment_reactions.user_id = auth.uid())) AS active_for_user
FROM
    sce_comment_reactions
GROUP BY
    sce_comment_reactions.comment_id,
    sce_comment_reactions.reaction_type
ORDER BY
    sce_comment_reactions.reaction_type;

create
or replace view "public"."sce_comments_with_metadata" as
SELECT
    sce_comments.id,
    sce_comments.created_at,
    sce_comments.topic,
    sce_comments.comment,
    sce_comments.user_id,
    sce_comments.parent_id,
    sce_comments.mentioned_user_ids,
    (
        SELECT
            count(*) AS count
        FROM
            sce_comments c
        WHERE
            (c.parent_id = sce_comments.id)
    ) AS replies_count
FROM
    sce_comments;

-- added twitter handle for those using Twitter Authentication.
create
or replace view "public"."sce_display_users" as
SELECT
    users.id,
    COALESCE(
        (users.raw_user_meta_data ->> 'name' :: text),
        (users.raw_user_meta_data ->> 'full_name' :: text)
    ) AS name,
    COALESCE(users.raw_user_meta_data ->> 'user_name' :: text) AS handle,
    COALESCE(
        (
            users.raw_user_meta_data ->> 'avatar_url' :: text
        ),
        (users.raw_user_meta_data ->> 'avatar' :: text)
    ) AS avatar
FROM
    auth.users;

-- seed some basic reactions
insert into
    sce_reactions(type, label, url)
values
    (
        'heart',
        'Heart',
        'https://emojis.slackmojis.com/emojis/images/1596061862/9845/meow_heart.png?1596061862'
    );

insert into
    sce_reactions(type, label, url)
values
    (
        'like',
        'Like',
        'https://emojis.slackmojis.com/emojis/images/1588108689/8789/fb-like.png?1588108689'
    );

insert into
    sce_reactions(type, label, url)
values
    (
        'party-blob',
        'Party Blob',
        'https://emojis.slackmojis.com/emojis/images/1547582922/5197/party_blob.gif?1547582922'
    );