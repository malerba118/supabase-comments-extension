#!/usr/bin/env node
const { Command } = require('commander');
const { DbClient } = require('./db');
const { getMigrationNames, getMigrationSql } = require('./files');

getMigrationSql('01_init.sql').then(console.log);

const program = new Command();

program.version('0.0.0');

program
  .command('run-migrations')
  .argument('<pg-connection-string>')
  .action(async (connectionUrl) => {
    console.log({ connectionUrl });

    const db = await DbClient(
      'postgresql://postgres:postgres@localhost:54322/postgres'
    );

    await db.initMigrationsTable();

    await db.hasMigration('01_init.sql').then(console.log);

    console.log('\n\nMADE IT\n\n');

    // await db.initMigrationTable();

    // const migrations = await fs.getMigrations();

    // for (migration of migrations) {
    //   const hasRun = await db.hasMigration(migration.id);
    //   if (!hasRun) {
    //     await db.runMigration(migration);
    //   }
    process.exit(0);
    // }
  });

program.parseAsync(process.argv);
