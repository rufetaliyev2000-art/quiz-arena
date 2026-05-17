const { Client } = require('pg');

async function main() {
  const c = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: { rejectUnauthorized: false },
  });
  await c.connect();
  console.log('--- public.users columns ---');
  const cols = await c.query(
    `SELECT column_name, data_type, column_default, is_nullable
     FROM information_schema.columns
     WHERE table_schema='public' AND table_name='users'
     ORDER BY ordinal_position`,
  );
  console.table(cols.rows);

  console.log('\n--- public.users sətirləri (10) ---');
  const rows = await c.query(
    `SELECT id, username, email, username_set, created_at FROM public.users ORDER BY created_at DESC LIMIT 10`,
  );
  console.table(rows.rows);

  console.log('\n--- auth.users sətirləri (10) ---');
  const auth = await c.query(
    `SELECT id, email, created_at FROM auth.users ORDER BY created_at DESC LIMIT 10`,
  );
  console.table(auth.rows);

  console.log('\n--- on_auth_user_created trigger ---');
  const trg = await c.query(
    `SELECT trigger_name, event_manipulation, action_timing, action_statement
     FROM information_schema.triggers
     WHERE event_object_schema='auth' AND trigger_name='on_auth_user_created'`,
  );
  console.table(trg.rows);

  console.log('\n--- handle_new_user funksiyası ---');
  const fn = await c.query(
    `SELECT proname, prosecdef, pg_get_function_identity_arguments(oid) AS args
     FROM pg_proc WHERE proname='handle_new_user'`,
  );
  console.table(fn.rows);

  console.log('\n--- public.users.id-FK ---');
  const fk = await c.query(
    `SELECT conname, pg_get_constraintdef(oid) AS def
     FROM pg_constraint
     WHERE conrelid = 'public.users'::regclass AND contype='f'`,
  );
  console.table(fk.rows);

  await c.end();
}
main().catch((e) => { console.error('XƏTA:', e.message); process.exit(1); });
