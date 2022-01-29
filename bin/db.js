const { Client } = require('pg');

const INIT_MIGRATIONS_TABLE_SQL = `
create table if not exists "public"."sce_migrations" (
    "migration" text primary key,
    "created_at" timestamp with time zone default now()
);

alter table "public"."sce_migrations" enable row level security;
`;

const MIGRATION_EXISTS_SQL = `
SELECT EXISTS (SELECT * FROM sce_migrations where migration = $1);
`;

const DbClient = async (connectionString) => {
  const client = new Client({
    connectionString,
  });
  await client.connect();
  const initMigrationsTable = async () => {
    const result = await client.query(INIT_MIGRATIONS_TABLE_SQL);
    return result.rows;
  };
  const hasMigration = async (migrationName) => {
    const result = await client.query(MIGRATION_EXISTS_SQL, [migrationName]);
    return result.rows[0]?.exists;
  };
  return {
    initMigrationsTable,
    hasMigration,
  };
};

module.exports = {
  DbClient,
};
