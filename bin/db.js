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

const INSERT_MIGRATION_SQL = `
INSERT INTO sce_migrations(migration) VALUES ($1);
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
  const hasRunMigration = async (migrationName) => {
    const result = await client.query(MIGRATION_EXISTS_SQL, [migrationName]);
    return result.rows[0]?.exists;
  };
  const runMigration = async (migrationName, migrationSql) => {
    await client.query(migrationSql);
    await client.query(INSERT_MIGRATION_SQL, [migrationName]);
  };
  return {
    initMigrationsTable,
    hasRunMigration,
    runMigration,
  };
};

module.exports = {
  DbClient,
};
