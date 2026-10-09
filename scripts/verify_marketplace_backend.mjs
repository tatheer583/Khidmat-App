import { readFile } from 'node:fs/promises';
import { resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const defaultConfig = new URL('../config/marketplace.json', import.meta.url);
const migrationHelp = 'Review the deployment inventory and the three migrations in docs/GO_LIVE_CHECKLIST.md. Do not reset an existing database.';
const knownCodes = new Set(['PGRST002','PGRST106','PGRST202','PGRST203','PGRST205','42P01','42883','42703','42501']);
const isObject = value => value !== null && typeof value === 'object' && !Array.isArray(value);

export function validatePublicConfiguration(input) {
  if (!isObject(input)) throw new Error('Configuration must be a JSON object.');
  const secretNames = ['SUPABASE_SECRET_KEY','SUPABASE_SERVICE_ROLE_KEY','FCM_SERVICE_ACCOUNT_JSON',
    'PUSH_DISPATCH_SECRET','TWILIO_AUTH_TOKEN','private_key'];
  if (secretNames.some(name => input[name])) {
    throw new Error('Remove server/provider credentials from mobile configuration. Only public client configuration is accepted.');
  }
  const endpoint = typeof input.SUPABASE_URL === 'string' ? input.SUPABASE_URL.trim() : '';
  if (typeof input.SUPABASE_URL==='string' && input.SUPABASE_URL!==endpoint) {
    throw new Error('Remove surrounding whitespace from the project URL so Flutter reads the same value.');
  }
  let url;
  try { url = new URL(endpoint); } catch { throw new Error('Set SUPABASE_URL to the HTTPS project URL from Supabase Connect.'); }
  if (url.protocol !== 'https:' || !url.hostname || url.username || url.password || url.search || url.hash ||
      !['','/'].includes(url.pathname)) {
    throw new Error('Use the HTTPS project origin without credentials, an API path, query or fragment.');
  }
  // Match String.fromEnvironment: an explicitly defined empty primary value
  // does not fall back to the legacy variable in Flutter.
  const selectedKey = Object.hasOwn(input,'SUPABASE_PUBLISHABLE_KEY') ? input.SUPABASE_PUBLISHABLE_KEY : input.SUPABASE_ANON_KEY;
  const key = typeof selectedKey === 'string' ? selectedKey.trim() : '';
  if (typeof selectedKey==='string' && selectedKey!==key) {
    throw new Error('Remove surrounding whitespace from the public key so Flutter reads the same value.');
  }
  if (!key) throw new Error('Set SUPABASE_PUBLISHABLE_KEY to the public publishable key from this project.');
  if (key.startsWith('sb_secret_')) throw new Error('Server keys are prohibited. Use a public publishable key.');
  let legacy = false;
  if (!/^sb_publishable_[A-Za-z0-9_-]{8,}$/.test(key)) {
    try {
      const parts = key.split('.');
      if (parts.length !== 3 || parts.some(part => !/^[A-Za-z0-9_-]+$/.test(part))) throw new Error();
      const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
      if (!isObject(payload) || payload.role !== 'anon' || payload.sub) throw new Error();
      legacy = true;
    } catch { throw new Error('Use a public publishable or legacy anon key. User-session and administrative tokens are prohibited.'); }
  }
  if (key.length > 4096) throw new Error('The public API key format is invalid.');
  const support = typeof input.KHIDMAT_SUPPORT_EMAIL === 'string' ? input.KHIDMAT_SUPPORT_EMAIL.trim() : '';
  return { origin: url.origin, key, legacy, supportConfigured: /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(support) &&
    !/@(?:example\.(?:com|org|net)|[^@]+\.example)$/i.test(support) };
}

function failureAdvice(status, data) {
  // Never echo HTTP bodies, provider text, endpoint names, headers or credentials.
  const code = isObject(data) && knownCodes.has(data.code) ? data.code : null;
  if (status === 401) return 'The project rejected the public key. Copy the URL and publishable key from the same active project.';
  if (code === '42501' || status === 403) return 'Public access was denied. Review the migration grants/RLS and Data API settings; do not disable RLS.';
  if (code === 'PGRST106') return 'The public API schema is not exposed. Enable public in Project Settings → Data API; keep khidmat_private unexposed.';
  if (code === 'PGRST002') return 'PostgREST could not load its schema. Check active Data API schemas and database health in the dashboard.';
  if (['PGRST202','PGRST203','PGRST205','42P01','42883','42703'].includes(code)) return `${migrationHelp} If deployed, refresh the PostgREST schema cache.`;
  if (status === 429) return 'The API is rate limited. Wait and check project abuse/rate-limit settings.';
  if (status >= 500) return 'The backend is unavailable. Check project status and API/database logs in the dashboard.';
  return 'The API response did not match the app contract. Check project configuration, deployment inventory and dashboard logs.';
}

async function probe(fetchImpl, config, path, options, timeoutMs) {
  const headers = { apikey: config.key, Accept: 'application/json', ...options.headers };
  // New publishable keys are not JWTs and must not be placed in a Bearer header.
  if (config.legacy) headers.Authorization = `Bearer ${config.key}`;
  try {
    const response = await fetchImpl(`${config.origin}${path}`, {
      ...options, headers, redirect: 'error', signal: AbortSignal.timeout(timeoutMs),
    });
    const chunks=[]; let bytes=0;
    if(response.body) {
      const reader=response.body.getReader();
      while(true) {
        const {value,done}=await reader.read(); if(done) break;
        bytes+=value.byteLength;
        if(bytes>262144) {await reader.cancel(); return {error:'The API response exceeded this bounded preflight size.'};}
        chunks.push(value);
      }
    }
    const joined=new Uint8Array(bytes); let offset=0;
    for(const chunk of chunks) {joined.set(chunk,offset);offset+=chunk.byteLength;}
    const text=new TextDecoder().decode(joined);
    let data;
    try { data = JSON.parse(text); } catch { return { error: 'The API returned an unexpected non-JSON response. Check the project URL and dashboard.' }; }
    if (!response.ok) return { error: failureAdvice(response.status, data), status: response.status,
      ...(isObject(data) && knownCodes.has(data.code) ? { code: data.code } : {}) };
    return { data };
  } catch {
    return { error: 'The HTTPS request failed, timed out or was redirected. Check connectivity, project status and the project URL. Error details were redacted.' };
  }
}

export async function verifyMarketplaceBackend({ configPath = defaultConfig, fetchImpl = globalThis.fetch,
  readFileImpl = readFile, staticOnly = false, city = 'Lahore', timeoutMs = 8000 } = {}) {
  const report = { mode: staticOnly ? 'static' : 'live', networkAttempted: false, checks: [],
    limitations: ['Does not send an OTP or verify SMS credentials/delivery.',
      'Does not migrate data, create accounts, upload photos, dispatch push or test authenticated bookings/Realtime.',
      'An empty worker search is valid; real workers must register and publish their own profiles.'] };
  const add = (id, status, message, extra = {}) => report.checks.push({ id, status, message, ...extra });
  const finish = () => ({ ...report, ok: !report.checks.some(check => check.status === 'fail'),
    deploymentVerified: !staticOnly && report.networkAttempted && !report.checks.some(check=>check.status==='fail') &&
      ['auth_settings','profession_catalog','worker_search'].every(id => report.checks.some(check => check.id === id && check.status === 'pass')) });
  let config;
  let raw;
  try { raw = await readFileImpl(configPath, 'utf8'); }
  catch {
    add('configuration','fail','Public configuration is missing or unreadable. Create ignored config/marketplace.json from its example without overwriting an existing file.');
    return finish();
  }
  try {
    if (raw.length > 65536) throw new Error('Public configuration is unexpectedly large.');
    let parsed;
    try { parsed = JSON.parse(raw); } catch { throw new Error('Public configuration is invalid JSON. Correct config/marketplace.json.'); }
    config = validatePublicConfiguration(parsed);
    add('configuration','pass','HTTPS project origin and public client key format validated. Values are not printed.');
  } catch (error) {
    // Only our own fixed validation messages reach the output.
    add('configuration','fail',error.message);
    return finish();
  }
  add('support',config.supportConfigured ? 'pass' : 'warn',config.supportConfigured ?
    'Support email has a non-placeholder format; inbox ownership/delivery still require operator verification.' :
    'Set KHIDMAT_SUPPORT_EMAIL to an inbox you operate before public distribution.');
  add('push','info','Firebase push is optional. In-app notifications and bookings do not require FCM setup.');
  if (staticOnly) {
    add('live_checks','skip','Static configuration check only. No backend, schema or SMS provider has been verified.');
    return finish();
  }
  if (typeof city !== 'string' || city.trim().length < 2 || city.trim().length > 80) {
    add('worker_search','fail','Choose a city name containing 2–80 characters.'); return finish();
  }
  report.networkAttempted = true;
  const probes = await Promise.all([
    probe(fetchImpl,config,'/auth/v1/settings',{ method:'GET' },timeoutMs),
    probe(fetchImpl,config,'/rest/v1/professions?select=*&active=eq.true&order=sort_order.asc,name.asc&limit=100',
      { method:'GET',headers:{'Accept-Profile':'public'} },timeoutMs),
    // PostgREST requires POST for this VOLATILE RPC. With an anon key and no
    // session/sub, the checked-in function takes only the SELECT branch, never
    // the authenticated throttle-writing branch. No mutation RPC is called.
    probe(fetchImpl,config,'/rest/v1/rpc/search_workers',{ method:'POST',
      headers:{'Content-Type':'application/json','Content-Profile':'public'},
      body:JSON.stringify({p_query:'',p_city:city.trim(),p_neighbourhood:null,p_limit:1,p_offset:0,
        p_available_only:false,p_sort:'distance'}) },timeoutMs),
  ]);
  for (let i=0;i<probes.length;i++) {
    const id=['auth_settings','profession_catalog','worker_search'][i];
    const result=probes[i];
    if (result.error) { add(id,'fail',result.error,{...(result.status?{httpStatus:result.status}:{}),...(result.code?{code:result.code}:{})}); continue; }
    const data=result.data;
    if (id==='auth_settings') {
      if (!isObject(data) || data.external?.phone !== true) {
        add(id,'fail','Phone sign-in is disabled or was not confirmed by Auth settings. Enable Phone in Authentication → Sign In / Providers.');
      } else {
        add(id,'pass','Live Auth settings report phone sign-in enabled. SMS provider credentials and delivery are not verified.');
      }
      if (isObject(data) && data.phone_autoconfirm === true) add('phone_confirmation','fail','Phone auto-confirmation is enabled. Require phone verification in Auth before production.');
      if (isObject(data) && data.disable_signup === true) add('signup','fail','New-account signup is disabled. Enable registration if new customers/workers should join.');
      add('sms_delivery','manual','In the SMS provider dashboard, confirm Pakistan delivery/sender/billing setup; then test OTP on a real phone yourself.');
    } else if (id==='profession_catalog') {
      const valid = Array.isArray(data) && data.length>0 && data.every(row => isObject(row) &&
        typeof row.id==='string' && typeof row.name==='string' && typeof row.category==='string' && row.active===true &&
        Array.isArray(row.skills) && row.skills.every(skill=>typeof skill==='string') && Array.isArray(row.questions));
      add(id,valid?'pass':'fail',valid ? `Live public profession catalog matches the app (${data.length} rows checked).` :
        `The public profession catalog is empty or incompatible. ${migrationHelp}`);
    } else {
      const privateFields=['phone','whatsapp','latitude','longitude','location','coordinates','home_address'];
      const safe=Array.isArray(data) && data.length<=1 && data.every(row=>isObject(row) &&
        typeof row.id==='string' && typeof row.profession_id==='string' && typeof row.city==='string' &&
        typeof row.availability==='string' && !privateFields.some(key=>Object.hasOwn(row,key)) &&
        (row.distance_km===null || (Number.isFinite(row.distance_km)&&row.distance_km>=0)));
      add(id,safe?'pass':'fail',safe ?
        'Live anonymous worker search succeeded with a bounded public result. No account or availability was changed.' :
        'Worker search returned an incompatible or unsafe result. Review the deployed RPC before distributing the app.');
      if (safe && data.length===0) add('worker_population','manual','No matching published worker was returned in the test city. Recruit real workers; do not insert fake workers or distances.');
    }
  }
  return finish();
}

export function formatReport(report) {
  const mode=report.mode==='live'&&!report.networkAttempted?'live requested; no network attempted':report.mode;
  const lines=[`Khidmat backend preflight (${mode}; credentials and project hosts redacted)`];
  for (const check of report.checks) lines.push(`[${check.status.toUpperCase()}] ${check.id}: ${check.message}${check.code?` (${check.code})`:''}`);
  lines.push(report.deploymentVerified ?
    'Public backend probes passed. Complete the real-phone/SMS/Storage/booking checks before launch.' :
    'Backend deployment is not verified. Follow docs/GO_LIVE_CHECKLIST.md.');
  return lines.join('\n');
}

async function main(args) {
  const options={}; let json=false;
  for(let i=0;i<args.length;i++) {
    if(args[i]==='--static') options.staticOnly=true;
    else if(args[i]==='--json') json=true;
    else if(args[i]==='--config' && args[i+1]) options.configPath=resolve(args[++i]);
    else if(args[i]==='--city' && args[i+1]) options.city=args[++i];
    else if(args[i]==='--help') {
      console.log('Usage: node scripts/verify_marketplace_backend.mjs [--static] [--json] [--config path] [--city Lahore]'); return;
    } else { console.error('Unknown or incomplete option. Use --help. Values are not echoed.'); process.exitCode=2; return; }
  }
  const report=await verifyMarketplaceBackend(options);
  console.log(json?JSON.stringify(report,null,2):formatReport(report));
  if(!report.ok) process.exitCode=1;
}
if(process.argv[1] && resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).catch(()=>{
    console.error('Preflight could not complete. Error details were redacted; no account or database mutations were requested.');
    process.exitCode=1;
  });
}
