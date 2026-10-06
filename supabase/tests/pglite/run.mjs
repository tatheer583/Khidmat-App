import { readFile, readdir } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';
import { pgtap } from '@electric-sql/pglite-pgtap';

// Real PostgreSQL/pgTAP with minimal Supabase-owned schemas. This checks our
// migration and RLS; it does not emulate Auth, HTTP Storage, or Realtime servers.
const database = new PGlite({ extensions: { pgtap } });
try {
  await database.exec(`
    create role anon;
    create role authenticated;
    create schema auth;
    create schema storage;
    create schema extensions;
    grant usage on schema public, auth, storage, extensions to anon, authenticated;
    create table auth.users (
      id uuid primary key, email text, raw_user_meta_data jsonb
    );
    create function auth.uid() returns uuid language sql stable as $$
      select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
    $$;
    create table storage.buckets (
      id text primary key, name text not null, public boolean,
      file_size_limit bigint, allowed_mime_types text[]
    );
    create table storage.objects (
      id uuid primary key default gen_random_uuid(), bucket_id text,
      name text not null, unique(bucket_id, name)
    );
    alter table storage.objects enable row level security;
    grant select, insert, delete on storage.objects to authenticated;
    create function storage.foldername(path text) returns text[]
    language sql immutable as $$
      select (string_to_array(path, '/'))[1:array_length(string_to_array(path, '/'), 1)-1]
    $$;
    create publication supabase_realtime;
  `);
  const migrationsDirectory = new URL('../../migrations/', import.meta.url);
  const migrations = (await readdir(migrationsDirectory)).filter(name => name.endsWith('.sql')).sort();
  for (const name of migrations) {
    await database.exec(await readFile(new URL(name, migrationsDirectory), 'utf8'));
  }
  const tests = await readFile(new URL('../database/booking_security_test.sql', import.meta.url), 'utf8');
  const results = await database.exec(tests);
  const lines = results.flatMap(result => result.rows.flatMap(row => Object.values(row)))
    .filter(value => typeof value === 'string' && /^(?:ok |not ok |1\.\.|#)/.test(value));
  for (const line of lines) console.log(line);
  const plan = lines.find(line => line.startsWith('1..'));
  const assertions = lines.filter(line => /^(?:ok |not ok )/.test(line));
  if (!plan || assertions.length !== Number(plan.slice(3)) || lines.some(line => line.startsWith('not ok '))) {
    throw new Error('Database assertions failed or did not complete.');
  }
  console.log(`Passed ${assertions.length} database assertions in local PostgreSQL (PGlite).`);
} finally {
  await database.close();
}
