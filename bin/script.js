#!/usr/bin/env node
const { Command } = require('commander');

const program = new Command();

program.version('0.0.0');

program
  .command('migrate')
  .argument('<connection-url>')
  .action((connectionUrl) => {
    console.log({ connectionUrl });
  });

program.parse(process.argv);
