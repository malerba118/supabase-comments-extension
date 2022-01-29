#!/usr/bin/env node
const { Command } = require('commander');

const program = new Command();

program.version('0.0.0');

program
  .command('run-migrations')
  .argument('<pg-connection-string>')
  .action(async (connectionUrl) => {
    console.log({ connectionUrl });

    // await db.initMigrationTable();

    // const migrations = await fs.getMigrations();

    // for (migration of migrations) {
    //   const hasRun = await db.hasMigration(migration.id);
    //   if (!hasRun) {
    //     await db.runMigration(migration);
    //   }
    // }
  });

program.parseAsync(process.argv);
