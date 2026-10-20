import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { copyFileSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const project = resolve(dirname(fileURLToPath(import.meta.url)), '..');
function fixture(t) {
  const parent = resolve(tmpdir());
  const directory = mkdtempSync(join(parent, 'khidmat-security-fixture-'));
  t.after(() => {
    // Delete only the temporary directory this test created, never a derived
    // project/config path. Validate the absolute parent before recursive cleanup.
    assert.equal(dirname(resolve(directory)), parent);
    assert(directory.startsWith(join(parent, 'khidmat-security-fixture-')));
    rmSync(directory, { recursive: true, force: true });
  });
  return directory;
}
function run(script, directory, env = {}) {
  return spawnSync(process.execPath, [join(project, 'scripts', script)], {
    cwd: directory, env: { ...process.env, ...env }, encoding: 'utf8',
  });
}
test('source scanner rejects PEM and escaped JSON private keys without printing values', t => {
  const directory = fixture(t);
  assert.equal(spawnSync('git', ['init', '--quiet'], { cwd: directory }).status, 0);
  for (const file of ['android/app/src/main/AndroidManifest.xml', 'android/app/build.gradle.kts', 'lib/services/local_store.dart',
    'lib/marketplace/services/secure_auth_storage.dart', 'android/app/src/main/res/xml/data_extraction_rules.xml']) {
    mkdirSync(dirname(join(directory, file)), { recursive: true });
    copyFileSync(join(project, file), join(directory, file));
  }
  assert.equal(run('check_security.mjs', directory).status, 0);
  const key = ['-----BEGIN PRIVATE KEY-----', 'A'.repeat(80), '-----END PRIVATE KEY-----'].join('\n');
  for (const [name, value] of [['private.pem', key], ['private.json', JSON.stringify({ private_key: key })]]) {
    writeFileSync(join(directory, name), value);
    const result = run('check_security.mjs', directory);
    assert.notEqual(result.status, 0);
    assert(result.stderr.includes(name));
    assert(!result.stderr.includes('A'.repeat(80)));
    rmSync(join(directory, name));
  }
});
test('release configuration rejects server keys and missing push settings without replacing valid configuration', t => {
  const directory = fixture(t);
  const env = {
    SUPABASE_URL: 'https://staging-fixture.supabase.co',
    SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_public_fixture_only',
    KHIDMAT_SUPPORT_EMAIL: 'qa@example.com', ENABLE_PUSH: 'false',
  };
  assert.equal(run('configure_release.mjs', directory, env).status, 0);
  const file = join(directory, 'config/marketplace.json');
  const before = readFileSync(file, 'utf8');
  const serverJwt = [Buffer.from('{}').toString('base64url'),
    Buffer.from(JSON.stringify({ role: 'service_role' })).toString('base64url'), 'fixture'].join('.');
  for (const key of ['sb_' + 'secret_fixture_key_do_not_compile', serverJwt]) {
    const result = run('configure_release.mjs', directory, { ...env, SUPABASE_PUBLISHABLE_KEY: key });
    assert.notEqual(result.status, 0);
    assert.equal(readFileSync(file, 'utf8'), before);
    assert(!result.stderr.includes(key));
  }
  const result = run('configure_release.mjs', directory, { ...env, ENABLE_PUSH: 'true',
    FIREBASE_API_KEY: '', FIREBASE_APP_ID: '', FIREBASE_PROJECT_ID: '', FIREBASE_MESSAGING_SENDER_ID: '' });
  assert.notEqual(result.status, 0);
  assert.equal(readFileSync(file, 'utf8'), before);
});
