// Optional server-only dispatcher. No provider credential is shipped in Flutter.
// Uses FCM HTTP v1; jobs/notifications remain usable when push is unconfigured.
type ServiceAccount = { project_id: string; client_email: string; private_key: string };
type Lease = {id: string; lease_token: string; notification_id: string; job_id: string | null;
  user_id: string; title: string; body: string; tokens: string[]};
let cachedAccess: {token: string; expires: number} | undefined;

function base64url(bytes: Uint8Array): string {
  return btoa(Array.from(bytes, x => String.fromCharCode(x)).join('')).replace(/=/g,'').replace(/\+/g,'-').replace(/\//g,'_');
}
function encode(value: unknown): string { return base64url(new TextEncoder().encode(JSON.stringify(value))); }
async function sameSecret(a: string,b: string): Promise<boolean> {
  const digests = await Promise.all([a,b].map(x=>crypto.subtle.digest('SHA-256',new TextEncoder().encode(x))));
  const left=new Uint8Array(digests[0]), right=new Uint8Array(digests[1]);
  let difference=0; for(let i=0;i<left.length;i++) difference |= left[i]^right[i];
  return difference===0;
}
async function accessToken(account: ServiceAccount): Promise<string> {
  if(cachedAccess && cachedAccess.expires>Date.now()+60000) return cachedAccess.token;
  const now=Math.floor(Date.now()/1000);
  const unsigned=encode({alg:'RS256',typ:'JWT'})+'.'+encode({iss:account.client_email,
    scope:'https://www.googleapis.com/auth/firebase.messaging',aud:'https://oauth2.googleapis.com/token',iat:now,exp:now+3600});
  const pem=account.private_key.replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g,'');
  const key=await crypto.subtle.importKey('pkcs8',Uint8Array.from(atob(pem),c=>c.charCodeAt(0)),
    {name:'RSASSA-PKCS1-v1_5',hash:'SHA-256'},false,['sign']);
  const signature=await crypto.subtle.sign('RSASSA-PKCS1-v1_5',key,new TextEncoder().encode(unsigned));
  const response=await fetch('https://oauth2.googleapis.com/token',{method:'POST',signal:AbortSignal.timeout(10000),
    headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams({
      grant_type:'urn:ietf:params:oauth:grant-type:jwt-bearer',assertion:unsigned+'.'+base64url(new Uint8Array(signature))})});
  if(!response.ok) throw new Error('Google access-token exchange failed');
  const data=await response.json();
  if(typeof data.access_token!=='string') throw new Error('Invalid access-token response');
  cachedAccess={token:data.access_token,expires:Date.now()+Math.min(Number(data.expires_in)||3600,3600)*1000};
  return cachedAccess.token;
}

export async function handleRequest(request: Request): Promise<Response> {
  if(request.method!=='POST') return new Response('Method not allowed',{status:405,headers:{Allow:'POST'}});
  const secret=Deno.env.get('PUSH_DISPATCH_SECRET');
  if(!secret || secret.length<32) return new Response('Push dispatcher is not configured',{status:503});
  if(!await sameSecret(request.headers.get('X-Dispatch-Secret')??'',secret)) return new Response('Unauthorized',{status:401});
  const accountJson=Deno.env.get('FCM_SERVICE_ACCOUNT_JSON');
  const url=Deno.env.get('SUPABASE_URL'); const serviceKey=Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if(!accountJson||!url||!serviceKey) return new Response('Push provider is not configured',{status:503});
  let account:ServiceAccount;
  try {
    account=JSON.parse(accountJson);
    if(!/^[a-z0-9-]+$/.test(account.project_id)||!account.client_email||!account.private_key) throw new Error('Invalid service account');
  } catch { return new Response('Push provider configuration is invalid',{status:503}); }
  const backendHeaders={apikey:serviceKey,Authorization:`Bearer ${serviceKey}`,'Content-Type':'application/json'};
  async function rpc(name:string,params:Record<string,unknown>):Promise<unknown> {
    const result=await fetch(`${url}/rest/v1/rpc/${name}`,{method:'POST',signal:AbortSignal.timeout(10000),
      headers:backendHeaders,body:JSON.stringify(params)});
    if(!result.ok) throw new Error(`Database operation ${name} failed (${result.status})`);
    const text=await result.text(); return text ? JSON.parse(text) : null;
  }
  let delivered=0,retried=0;
  try {
    // Mint before claiming, so a provider configuration failure does not lease jobs.
    const token=await accessToken(account);
    // At most 25 concurrent provider calls (five accounts, five devices each),
    // safely below the two-minute lease even when provider requests time out.
    const leases=await rpc('claim_push_batch',{p_limit:5}) as Lease[];
    await Promise.all(leases.map(async lease => {
      let success=true; const invalid:string[]=[];
      await Promise.all(lease.tokens.map(async deviceToken => {
        try {
          const response=await fetch(`https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`,{
            method:'POST',signal:AbortSignal.timeout(10000),headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json'},
            body:JSON.stringify({message:{token:deviceToken,notification:{title:lease.title,body:lease.body},
              data:{notification_id:lease.notification_id,...(lease.job_id?{job_id:lease.job_id}:{})},
              android:{collapse_key:lease.notification_id,notification:{tag:lease.notification_id}},
              apns:{headers:{'apns-collapse-id':lease.notification_id}}}})});
          const result=await response.json();
          // Only the explicit FCM token error permanently removes a registration.
          const expired=!response.ok && result?.error?.details?.some((d:{errorCode?:string})=>d.errorCode==='UNREGISTERED');
          if(response.ok||expired) {
            await rpc('record_push_delivery',{p_id:lease.id,p_lease_token:lease.lease_token,p_token:deviceToken,p_outcome:expired?'invalid':'sent'});
            if(expired) invalid.push(deviceToken);
          } else success=false;
        } catch { success=false; }
      }));
      await rpc('finish_push',{p_id:lease.id,p_lease_token:lease.lease_token,p_success:success,
        p_invalid_tokens:invalid,p_error:success?'':'FCM delivery failed; retry scheduled'});
      if(success) delivered++; else retried++;
    }));
    return Response.json({delivered,retried});
  } catch {
    // Never log a service account, registration token, job address or provider body.
    return new Response('Dispatch failed; leased items will become eligible for retry',{status:502});
  }
}
if(import.meta.main) Deno.serve(handleRequest);
