import assert from 'node:assert/strict';
import { mkdirSync, writeFileSync } from 'node:fs';

// Only public client configuration is accepted. Provider credentials belong on
// Supabase/FCM, and production signing is handled separately by the workflow.
const config = Object.fromEntries([
  'SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'KHIDMAT_SUPPORT_EMAIL',
  'FIREBASE_API_KEY', 'FIREBASE_APP_ID', 'FIREBASE_MESSAGING_SENDER_ID',
  'FIREBASE_PROJECT_ID', 'FIREBASE_IOS_BUNDLE_ID',
].map(name => [name, (process.env[name] ?? '').trim()]));
let endpoint;
try { endpoint = new URL(config.SUPABASE_URL); }
catch { throw new Error('Set a valid HTTPS Supabase URL.'); }
assert(endpoint.protocol === 'https:' && endpoint.hostname && !endpoint.username &&
  !endpoint.password && !endpoint.search && !endpoint.hash, 'Set a valid HTTPS Supabase URL.');
const key = config.SUPABASE_PUBLISHABLE_KEY;
let publicKey = key.startsWith('sb_publishable_') && key.length > 20;
if (key.split('.').length === 3) {
  try { publicKey = JSON.parse(Buffer.from(key.split('.')[1], 'base64url')).role === 'anon'; }
  catch { publicKey = false; }
}
assert(publicKey, 'Set a Supabase publishable/anon key. Server keys are prohibited.');
assert(/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(config.KHIDMAT_SUPPORT_EMAIL),
  'Set an operational support email before distributing a release.');
config.ENABLE_PUSH = process.env.ENABLE_PUSH === 'true' ? 'true' : 'false';
if (config.ENABLE_PUSH === 'true') {
  for (const name of ['FIREBASE_API_KEY', 'FIREBASE_APP_ID', 'FIREBASE_MESSAGING_SENDER_ID', 'FIREBASE_PROJECT_ID']) {
    assert(config[name], `Push requires public ${name} configuration.`);
  }
}
config.FIREBASE_IOS_BUNDLE_ID ||= 'com.khidmat.khidmat';
mkdirSync('config', { recursive: true });
writeFileSync('config/marketplace.json', JSON.stringify(config, null, 2) + '\n', { mode: 0o600 });
console.log('Public release configuration validated and written. Values are not logged.');
