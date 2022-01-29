const getInitMigrationsTableSql = () => `
create table "public"."sce_migrations" (
    "migration" text not null,
    "created_at" timestamp with time zone default now()
);

alter table "public"."sce_migrations" enable row level security;

CREATE UNIQUE INDEX sce_migrations_pkey ON public.sce_migrations USING btree (migration);

alter table "public"."sce_migrations" add constraint "sce_migrations_pkey" PRIMARY KEY using index "sce_migrations_pkey";
`;

const getMigrationExistsSql = ({ migration }) => `
SELECT EXISTS (SELECT * FROM sce_migrations where migration = '${migration}');
`;

module.exports = {};
