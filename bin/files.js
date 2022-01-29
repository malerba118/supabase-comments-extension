const fs = require('fs/promises');
const path = require('path');

const getMigrationNames = async () => {
  return fs.readdir(path.join(__dirname, './migrations'));
};

const getMigrationSql = async (migrationName) => {
  return fs.readFile(path.join(__dirname, './migrations', migrationName), {
    encoding: 'utf-8',
  });
};

module.exports = {
  getMigrationNames,
  getMigrationSql,
};
