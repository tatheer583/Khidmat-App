import {handleRequest} from './index.ts';
function assert(value:unknown,message='Assertion failed'): asserts value { if(!value) throw new Error(message); }
const secret='test-only-dispatch-secret-over-32-characters';
const envKeys=['PUSH_DISPATCH_SECRET','FCM_SERVICE_ACCOUNT_JSON','SUPABASE_URL','SUPABASE_SERVICE_ROLE_KEY'];
function clear(){for(const key of envKeys) Deno.env.delete(key);}
function request(authorized=true){return new Request('https://edge.example/dispatch-push',{method:'POST',headers:authorized?{'X-Dispatch-Secret':secret}:{}});}

Deno.test('dispatcher rejects non-POST requests',async()=>{
  assert((await handleRequest(new Request('https://edge.example/dispatch-push'))).status===405);
});
Deno.test('dispatcher fails closed without secret',async()=>{
  clear(); assert((await handleRequest(request())).status===503);
});
Deno.test('a user bearer token cannot substitute for scheduler secret',async()=>{
  clear(); Deno.env.set('PUSH_DISPATCH_SECRET',secret);
  const r=new Request('https://edge.example/dispatch-push',{method:'POST',headers:{Authorization:'Bearer user-token'}});
  assert((await handleRequest(r)).status===401); clear();
});
Deno.test('unconfigured provider is reported honestly',async()=>{
  clear(); Deno.env.set('PUSH_DISPATCH_SECRET',secret);
  assert((await handleRequest(request())).status===503); clear();
});
Deno.test('invalid service-account configuration fails before network calls',async()=>{
  clear(); Deno.env.set('PUSH_DISPATCH_SECRET',secret); Deno.env.set('FCM_SERVICE_ACCOUNT_JSON','{}');
  Deno.env.set('SUPABASE_URL','https://db.example'); Deno.env.set('SUPABASE_SERVICE_ROLE_KEY','test-server-only-key');
  assert((await handleRequest(request())).status===503); clear();
});

async function dispatchFixture(providerResult:Record<string,unknown>,status:number){
  clear(); Deno.env.set('PUSH_DISPATCH_SECRET',secret);
  const pair=await crypto.subtle.generateKey({name:'RSASSA-PKCS1-v1_5',modulusLength:2048,publicExponent:new Uint8Array([1,0,1]),hash:'SHA-256'},true,['sign','verify']);
  const exported=new Uint8Array(await crypto.subtle.exportKey('pkcs8',pair.privateKey));
  const pem='-----BEGIN PRIVATE KEY-----\n'+btoa(Array.from(exported,x=>String.fromCharCode(x)).join(''))+'\n-----END PRIVATE KEY-----';
  Deno.env.set('FCM_SERVICE_ACCOUNT_JSON',JSON.stringify({project_id:'test-project',client_email:'test@test-project.iam.gserviceaccount.com',private_key:pem}));
  Deno.env.set('SUPABASE_URL','https://db.example'); Deno.env.set('SUPABASE_SERVICE_ROLE_KEY','test-server-only-key');
  const calls:{url:string;body:Record<string,unknown>}[]=[];
  const original=globalThis.fetch;
  globalThis.fetch=((input:RequestInfo|URL,init?:RequestInit)=>{
    const url=String(input),body=url.includes('oauth2')?{}:JSON.parse(String(init?.body??'{}'));
    calls.push({url,body});
    if(url.includes('oauth2.googleapis.com'))return Promise.resolve(Response.json({access_token:'test-oauth-token',expires_in:3600}));
    if(url.includes('claim_push_batch'))return Promise.resolve(Response.json([{id:'outbox-1',lease_token:'lease-1',notification_id:'notification-1',job_id:'job-1',user_id:'user-1',title:'Khidmat update',body:'Open Khidmat to view your latest job update.',tokens:['test-device-token']} ]));
    if(url.includes('fcm.googleapis.com'))return Promise.resolve(Response.json(providerResult,{status}));
    return Promise.resolve(Response.json(null));
  }) as typeof fetch;
  try {
    const response=await handleRequest(request()); const text=await response.text();
    assert(response.status===200,text); assert(!text.includes('test-server-only-key')&&!text.includes('PRIVATE KEY'));
    return {result:JSON.parse(text),calls};
  } finally {globalThis.fetch=original;clear();}
}
Deno.test('successful FCM delivery records per-device receipt before acknowledging lease',async()=>{
  const {result,calls}=await dispatchFixture({name:'projects/test-project/messages/1'},200);
  assert(result.delivered===1&&result.retried===0);
  const record=calls.findIndex(c=>c.url.includes('record_push_delivery'));
  const finish=calls.findIndex(c=>c.url.includes('finish_push'));
  assert(record>=0&&finish>record); assert(calls[record].body.p_outcome==='sent');
  const message=calls.find(c=>c.url.includes('fcm.googleapis.com'))?.body.message as Record<string,unknown>;
  assert(!JSON.stringify(message).includes('address')); assert(JSON.stringify(message).includes('notification-1'));
});
Deno.test('transient FCM failure schedules retry without invalidating token',async()=>{
  const {result,calls}=await dispatchFixture({error:{status:'UNAVAILABLE'}},503);
  assert(result.retried===1&&result.delivered===0);
  const finish=calls.find(c=>c.url.includes('finish_push'))!.body;
  assert(finish.p_success===false); assert((finish.p_invalid_tokens as string[]).length===0);
});
Deno.test('only explicit UNREGISTERED errors invalidate a device token',async()=>{
  const {result,calls}=await dispatchFixture({error:{details:[{errorCode:'UNREGISTERED'}]}},404);
  assert(result.delivered===1); assert(calls.find(c=>c.url.includes('record_push_delivery'))?.body.p_outcome==='invalid');
  assert((calls.find(c=>c.url.includes('finish_push'))!.body.p_invalid_tokens as string[])[0]==='test-device-token');
});
