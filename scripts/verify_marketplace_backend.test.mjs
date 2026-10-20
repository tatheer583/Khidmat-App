import test from 'node:test';
import assert from 'node:assert/strict';
import {verifyMarketplaceBackend,validatePublicConfiguration,formatReport} from './verify_marketplace_backend.mjs';

const publicKey='sb_publishable_test_public_value_only';
const origin='https://redacted-project.supabase.co';
const config={SUPABASE_URL:origin,SUPABASE_PUBLISHABLE_KEY:publicKey,KHIDMAT_SUPPORT_EMAIL:'help@khidmat.pk'};
const read=object=>async()=>JSON.stringify(object);
const jwt=payload=>`${Buffer.from('{"alg":"HS256"}').toString('base64url')}.${Buffer.from(JSON.stringify(payload)).toString('base64url')}.test_signature`;
const catalog=[{id:'10000000-0000-4000-8000-000000000001',name:'Mazdoor',category:'Construction',active:true,skills:['General Labourer'],questions:[]}];
function mock({settings={external:{phone:true},phone_autoconfirm:false,disable_signup:false},professions=catalog,workers=[],errorPath,errorCode='PGRST202',status=404}={}) {
  const calls=[];
  const fetchImpl=async(url,options)=>{
    calls.push({url,options});
    if(errorPath && url.includes(errorPath)) return Response.json({code:errorCode,message:`Private endpoint ${origin} with ${publicKey}`},{status});
    if(url.endsWith('/auth/v1/settings')) return Response.json(settings);
    if(url.includes('/professions?')) return Response.json(professions);
    if(url.endsWith('/rpc/search_workers')) return Response.json(workers);
    assert.fail('Unexpected request; the preflight must not call write/provider APIs.');
  };
  return {fetchImpl,calls};
}
const run=options=>verifyMarketplaceBackend({readFileImpl:read(config),...options});

test('missing ignored configuration prevents all network requests',async()=>{
  let calls=0;
  const report=await run({readFileImpl:async()=>{throw new Error('ENOENT includes private filename');},fetchImpl:()=>calls++});
  assert.equal(report.ok,false); assert.equal(report.networkAttempted,false); assert.equal(calls,0);
  assert.doesNotMatch(JSON.stringify(report),/private filename/);
});
test('invalid JSON is reported without logging raw configuration',async()=>{
  const report=await run({readFileImpl:async()=>`{broken ${publicKey}`});
  assert.equal(report.ok,false); assert.doesNotMatch(JSON.stringify(report),new RegExp(publicKey));
});
test('HTTP endpoints, embedded credentials, paths and URL queries are rejected',()=>{
  for(const url of ['http://project.example','https://user:pass@project.example','https://project.example/rest/v1','https://project.example/?secret=value'])
    assert.throws(()=>validatePublicConfiguration({...config,SUPABASE_URL:url}));
});
test('server secrets and service-role/session JWTs are rejected before network access',async()=>{
  for(const key of ['sb_secret_'+'x'.repeat(24),jwt({role:'service_role'}),jwt({role:'authenticated',sub:'user-1'}),jwt({role:'anon',sub:'user-1'})]) {
    const report=await run({readFileImpl:read({...config,SUPABASE_PUBLISHABLE_KEY:key}),fetchImpl:()=>assert.fail('Network forbidden')});
    assert.equal(report.ok,false); assert.doesNotMatch(JSON.stringify(report),new RegExp(key.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')));
  }
  assert.throws(()=>validatePublicConfiguration({...config,SUPABASE_SERVICE_ROLE_KEY:'present-but-never-logged'}));
});
test('static mode validates only config and never claims a live backend',async()=>{
  const report=await run({staticOnly:true,fetchImpl:()=>assert.fail('Network forbidden')});
  assert.equal(report.ok,true); assert.equal(report.deploymentVerified,false); assert.equal(report.networkAttempted,false);
});
test('live checks use only settings, app-compatible catalog and anonymous bounded search',async()=>{
  const fixture=mock(); const report=await run(fixture);
  assert.equal(report.ok,true); assert.equal(report.deploymentVerified,true); assert.equal(fixture.calls.length,3);
  for(const {options} of fixture.calls) {
    assert.equal(options.headers.apikey,publicKey); assert.equal(options.headers.Authorization,undefined); assert.equal(options.redirect,'error');
  }
  const query=fixture.calls.find(c=>c.url.endsWith('/rpc/search_workers'));
  assert.equal(query.options.method,'POST'); assert.equal(JSON.parse(query.options.body).p_limit,1);
  assert.equal(JSON.parse(query.options.body).p_city,'Lahore');
  assert.doesNotMatch(JSON.stringify(report),new RegExp(publicKey)); assert.doesNotMatch(formatReport(report),/redacted-project/);
});
test('legacy anonymous JWT is supported without accepting user sessions',async()=>{
  const key=jwt({role:'anon'}); const fixture=mock();
  const legacyConfig={...config,SUPABASE_ANON_KEY:key}; delete legacyConfig.SUPABASE_PUBLISHABLE_KEY;
  const report=await run({...fixture,readFileImpl:read(legacyConfig)});
  assert.equal(report.ok,true); assert.equal(fixture.calls[0].options.headers.Authorization,`Bearer ${key}`);
});
test('an explicitly blank primary key matches Flutter and cannot pass via fallback',async()=>{
  const report=await run({readFileImpl:read({...config,SUPABASE_PUBLISHABLE_KEY:'',SUPABASE_ANON_KEY:jwt({role:'anon'})}),fetchImpl:()=>assert.fail('Network forbidden')});
  assert.equal(report.ok,false); assert.equal(report.networkAttempted,false);
});
test('whitespace rejected by Flutter cannot falsely pass the preflight',()=>{
  assert.throws(()=>validatePublicConfiguration({...config,SUPABASE_URL:` ${origin}`}));
  assert.throws(()=>validatePublicConfiguration({...config,SUPABASE_PUBLISHABLE_KEY:`${publicKey} `}));
});
test('phone disabled is a real blocker and settings do not prove SMS delivery',async()=>{
  const report=await run(mock({settings:{external:{phone:false}}}));
  assert.equal(report.ok,false); assert.equal(report.deploymentVerified,false);
  assert.equal(report.checks.find(c=>c.id==='auth_settings').status,'fail');
  assert.match(report.limitations.join(' '),/Does not send an OTP/);
});
test('phone auto-confirm and disabled new signups are reported separately',async()=>{
  const report=await run(mock({settings:{external:{phone:true},phone_autoconfirm:true,disable_signup:true}}));
  assert.equal(report.ok,false); assert.equal(report.checks.find(c=>c.id==='phone_confirmation').status,'fail');
  assert.equal(report.checks.find(c=>c.id==='signup').status,'fail');
  assert.equal(report.deploymentVerified,false);
});
test('missing schema/function gives actionable redacted guidance',async()=>{
  for(const [errorPath,errorCode] of [['/professions?','PGRST205'],['/rpc/search_workers','PGRST202'],['/professions?','42P01']]) {
    const report=await run(mock({errorPath,errorCode})); assert.equal(report.ok,false);
    assert.match(formatReport(report),/deployment inventory/); assert.doesNotMatch(JSON.stringify(report),new RegExp(publicKey));
    assert.doesNotMatch(JSON.stringify(report),/redacted-project/);
  }
});
test('RLS/grant failures never recommend disabling RLS',async()=>{
  const report=await run(mock({errorPath:'/professions?',errorCode:'42501',status:403}));
  assert.equal(report.ok,false); assert.match(formatReport(report),/do not disable RLS/);
});
test('bad keys, rate limits and backend downtime produce bounded generic output',async()=>{
  for(const status of [401,429,503]) {
    const report=await run(mock({errorPath:'/professions?',status,errorCode:'unknown_private_error'}));
    assert.equal(report.ok,false); assert.doesNotMatch(JSON.stringify(report),/unknown_private_error|redacted-project/);
  }
});
test('empty catalog blocks worker onboarding; empty search is legitimate',async()=>{
  const emptyCatalog=await run(mock({professions:[]})); assert.equal(emptyCatalog.ok,false);
  const noWorkers=await run(mock({workers:[]})); assert.equal(noWorkers.ok,true);
  assert.equal(noWorkers.checks.find(c=>c.id==='worker_population').status,'manual');
});
test('private coordinates or contacts in worker results fail the safety contract',async()=>{
  const row={id:'worker-1',profession_id:'profession-1',city:'Lahore',availability:'available_later',distance_km:null};
  assert.equal((await run(mock({workers:[row]}))).ok,true);
  for(const field of ['phone','latitude','longitude','location','home_address']) {
    const report=await run(mock({workers:[{...row,[field]:'must-not-be-printed'}]}));
    assert.equal(report.ok,false); assert.doesNotMatch(JSON.stringify(report),/must-not-be-printed/);
  }
});
test('transport exceptions, redirects and malformed HTTP bodies never expose hosts or tokens',async()=>{
  const network=await run({fetchImpl:async()=>{throw new Error(`${origin} ${publicKey}`);}});
  assert.equal(network.ok,false); assert.doesNotMatch(formatReport(network),/redacted-project|sb_publishable_test/);
  const malformed=await run({fetchImpl:async()=>new Response(`${origin} ${publicKey}`)});
  assert.equal(malformed.ok,false); assert.doesNotMatch(formatReport(malformed),/redacted-project|sb_publishable_test/);
});
test('missing support contact warns while optional push does not block basic service',async()=>{
  const report=await run({...mock(),readFileImpl:read({...config,KHIDMAT_SUPPORT_EMAIL:'',ENABLE_PUSH:'false'})});
  assert.equal(report.ok,true); assert.equal(report.checks.find(c=>c.id==='support').status,'warn');
  assert.equal(report.checks.find(c=>c.id==='push').status,'info');
});
test('oversized HTTP responses are bounded before parsing or printing',async()=>{
  const report=await run({fetchImpl:async()=>new Response('x'.repeat(300000))});
  assert.equal(report.ok,false); assert.match(formatReport(report),/bounded preflight size/);
});
