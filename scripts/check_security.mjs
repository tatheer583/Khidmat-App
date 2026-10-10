import { spawnSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import assert from 'node:assert/strict';

// Scan source and local additions, excluding ignored credentials/build caches.
// Report file names only; never print a matched credential.
const result = spawnSync('git', ['ls-files', '-c', '-o', '--exclude-standard', '-z'], { encoding: 'utf8' });
assert.equal(result.status, 0, 'Run the security check from the project Git checkout.');
const files = [...new Set(result.stdout.split('\0').filter(Boolean))];
const problems = [];
const secretFile = /(?:^|\/)(?:key\.properties|google-services\.json|GoogleService-Info\.plist|signing-password\.txt|\.env(?:\..*)?)$|\.(?:jks|keystore|p8|p12|mobileprovision)$/i;
for (const file of files) {
  if (secretFile.test(file) && !file.endsWith('.env.example')) problems.push(`${file}: private configuration must be ignored`);
  if (!/\.(?:dart|json|toml|yaml|yml|sql|mjs|ts|ps1|py|md|xml|plist|entitlements|kts|xcconfig|pem)$/.test(file)) continue;
  const source = readFileSync(file, 'utf8');
  if (/sb_secret_[A-Za-z0-9_-]{20,}/.test(source) ||
      /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----(?:\r?\n|(?:\\r)?\\n)[A-Za-z0-9+/=\\rn\r\n]{64,}/.test(source) ||
      /"private_key"\s*:\s*"-----BEGIN (?:RSA |EC )?PRIVATE KEY-----/.test(source)) {
    problems.push(`${file}: potential private credential`);
  }
  if (file.startsWith('lib/') && /String\.fromEnvironment\(['"](?:SUPABASE_SERVICE_ROLE_KEY|FCM_SERVICE_ACCOUNT|(?:PUSH_)?DISPATCH_SECRET)/.test(source)) {
    problems.push(`${file}: server credentials must never be compiled into the app`);
  }
  for (const token of source.matchAll(/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g)) {
    try {
      if (JSON.parse(Buffer.from(token[0].split('.')[1], 'base64url')).role === 'service_role') {
        problems.push(`${file}: embedded service-role JWT`);
      }
    } catch { /* A documentation pattern is not a credential. */ }
  }
}
const android = readFileSync('android/app/src/main/AndroidManifest.xml', 'utf8');
assert.match(android, /android\.permission\.INTERNET/, 'Marketplace needs Internet permission.');
assert.doesNotMatch(android, /ACCESS_BACKGROUND_LOCATION/, 'Background location is prohibited.');
assert.match(android, /android:allowBackup="false"/, 'Private data must be excluded from Android cloud backup.');
assert.match(android, /android:dataExtractionRules="@xml\/data_extraction_rules"/, 'Modern device transfers must have explicit privacy rules.');
const extractionRules = readFileSync('android/app/src/main/res/xml/data_extraction_rules.xml', 'utf8');
assert.match(extractionRules, /<device-transfer>[\s\S]*<exclude domain="sharedpref" path="\."/, 'Device-bound session preferences must not transfer to another phone.');
assert.doesNotMatch(android, /usesCleartextTraffic="true"/, 'Production cleartext traffic is prohibited.');
const localStore = readFileSync('lib/services/local_store.dart', 'utf8');
assert.doesNotMatch(localStore, /preferences\.remove|sb-.*auth-token/, 'Offline startup must preserve online sessions.');
const secureStorage = readFileSync('lib/marketplace/services/secure_auth_storage.dart', 'utf8');
assert.match(secureStorage, /resetOnError:\s*false/, 'A decryption failure must not silently reset saved credentials.');
assert.match(secureStorage, /migrateWithBackup:\s*true/, 'Secure storage algorithm migration must retain a recoverable encrypted backup.');
const gradle = readFileSync('android/app/build.gradle.kts', 'utf8');
assert.match(gradle, /khidmatTestBuild/, 'Test signing must require explicit opt-in.');
assert.doesNotMatch(gradle, /else signingConfigs\.getByName\("debug"\)/, 'Production must not silently use debug signing.');
if (problems.length) throw new Error(problems.join('\n'));
console.log(`Security source/configuration checks passed (${files.length} files inspected).`);
