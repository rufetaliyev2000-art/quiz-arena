// Bir-dəfəlik SQL faylı tətbiq edir. Komand:
//   node scripts/apply-migration.js sql/02_username_set_flag.sql
// DATABASE_URL env-də ya da arqumentdə ola bilər.
const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

async function main() {
  const file = process.argv[2];
  if (!file) {
    console.error('Usage: node apply-migration.js <sql-file>');
    process.exit(1);
  }
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    console.error('DATABASE_URL env tələb olunur');
    process.exit(1);
  }
  const sql = fs.readFileSync(path.resolve(file), 'utf8');
  const client = new Client({ connectionString, ssl: { rejectUnauthorized: false } });
  await client.connect();
  console.log('Bağlantı OK, SQL icra olunur...');
  try {
    await client.query(sql);
    console.log('Migration uğurla tətbiq olundu:', file);
  } catch (e) {
    console.error('SQL xətası:', e.message);
    process.exitCode = 2;
  } finally {
    await client.end();
  }
}
main();
