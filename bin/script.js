#!/usr/bin/env node
const { Command } = require('commander');
const { DbClient } = require('./db');
const files = require('./files');
const packageJson = require('../package.json');

const program = new Command();

program.version(packageJson.version);

program
  .command('run-migrations')
  .argument('<pg-connection-string>')
  .action(async (connectionUrl) => {
    const db = await DbClient(connectionUrl);

    await db.initMigrationsTable();

    console.log('\nRUNNING MIGRATIONS\n');

    const migrationNames = await files.getMigrationNames();

    for (migrationName of migrationNames) {
      try {
        const hasRun = await db.hasRunMigration(migrationName);
        if (hasRun) {
          console.log(`SKIPPING MIGRATION (Already Applied): ${migrationName}`);
        } else {
          console.log(`RUNNING MIGRATION (Not Yet Applied): ${migrationName}`);
          const migrationSql = await files.getMigrationSql(migrationName);
          await db.runMigration(migrationName, migrationSql);
        }
      } catch (err) {
        console.error(`\nERROR RUNNING MIGRATION: ${migrationName}\n`);
        console.error(err.message);
        console.log('\nSKIPPING REMAINING MIGRATIONS\n');
        break;
      }
    }
    await db.reloadSchema();
    process.exit(0);
  });

program.parseAsync(process.argv);
