const fs = require('fs/promises');
const path = require('path');

const getMigrationNames = async () => {
  const migrationNames = await fs.readdir(path.join(__dirname, './migrations'));
  return migrationNames.sort();
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
