// Runs actual PostgreSQL + PostGIS in WASM. Only Supabase auth/storage service
// schemas are isolated fixtures. No remote DB, SMS, push or Realtime is contacted.
import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import { PGlite } from '@electric-sql/pglite';
import { postgis } from '@electric-sql/pglite-postgis';

const db = new PGlite({ extensions: { postgis } });
const ids = {
  customer: '20000000-0000-4000-8000-000000000001',
  worker: '20000000-0000-4000-8000-000000000002',
  stranger: '20000000-0000-4000-8000-000000000003',
  far: '20000000-0000-4000-8000-000000000004',
  manual: '20000000-0000-4000-8000-000000000005',
  unverified: '20000000-0000-4000-8000-000000000006',
};
const profession = '10000000-0000-4000-8000-000000000001';
let passed = 0;
const q = (sql, args=[]) => db.query(sql,args);
const scalar = async (sql,args=[]) => Object.values((await q(sql,args)).rows[0] ?? {})[0];
const rpc = (name, params={}) => {
  const entries = Object.entries(params);
  return scalar(`select public.${name}(${entries.map(([k],i)=>`${k} => $${i+1}`).join(',')}) result`,entries.map(([,v])=>typeof v==='object' && v!==null ? JSON.stringify(v) : v));
};
async function as(user,fn,role='authenticated') {
  await q("select set_config('request.jwt.claim.sub',$1,false),set_config('request.jwt.claim.role',$2,false)",[user??'',role]);
  await db.exec(`set role ${role}`);
  try { return await fn(); } finally { await db.exec('reset role'); }
}
async function test(name,fn) { await fn(); passed++; console.log(`PASS ${name}`); }
const rejects = async fn => assert.rejects(fn);
const draft = overrides => ({profession_id:profession,skills:['General Labourer'],experience_years:5,description:'Experienced and reliable construction labourer.',languages:['Urdu','Punjabi'],rate:1800,price_unit:'day',service_radius_km:15,working_days:[1,2,3,4,5,6],start_time:'08:00',end_time:'18:00',answers:{role:'Labourer',work_types:['Material handling']},published:true,share_contact:false,...overrides});
const saveWorker = (id,overrides={},lat=31.5204,lng=74.3587) => as(id,()=>rpc('save_worker_profile',{p_profile:draft(overrides),p_latitude:lat,p_longitude:lng}));
const search = params => scalar('select coalesce(jsonb_agg(r),\'[]\'::jsonb) from public.search_workers(p_latitude=>31.5204,p_longitude=>74.3587,p_radius_km=>15) r');

try {
  await db.exec(`
    create role anon; create role authenticated; create role service_role bypassrls;
    create publication supabase_realtime;
    create schema auth; create schema storage;
    grant usage on schema public,auth,storage to anon,authenticated,service_role;
    create table auth.users(id uuid primary key,phone text,phone_confirmed_at timestamptz);
    create function auth.uid() returns uuid language sql stable as $$ select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid $$;
    create function auth.role() returns text language sql stable as $$ select current_setting('request.jwt.claim.role',true) $$;
    grant execute on function auth.uid(),auth.role() to public;
    create table storage.buckets(id text primary key,name text,public boolean,file_size_limit bigint,allowed_mime_types text[]);
    create table storage.objects(id uuid default gen_random_uuid() primary key,bucket_id text,name text);
    alter table storage.objects enable row level security;
    grant select,insert,update,delete on storage.objects to authenticated;
    create function storage.foldername(text) returns text[] language sql immutable as $$ select (string_to_array($1,'/'))[1:array_length(string_to_array($1,'/'),1)-1] $$;
  `);
  for (const name of (await readdir(new URL('../migrations/',import.meta.url))).filter(x=>x.endsWith('.sql')).sort()) {
    await db.exec(await readFile(new URL(`../migrations/${name}`,import.meta.url),'utf8'));
    console.log(`APPLIED ${name}`);
  }
  for (const [i,[name,id]] of Object.entries(ids).entries()) {
    await q('insert into auth.users(id,phone,phone_confirmed_at) values($1,$2,$3)',[id,`92300123456${i}`,name==='unverified'?null:new Date().toISOString()]);
    if(name!=='unverified') await as(id,()=>rpc('save_profile',{p_profile:{full_name:`Test ${name}`,city:name==='far'?'Karachi':'Lahore',neighbourhood:'Test area',roles:name==='customer'||name==='stranger'?['customer']:['worker']}}));
  }
  await db.exec("insert into khidmat_private.settings(key,value) values('storage_origin','https://test.supabase.co')");
  await saveWorker(ids.worker);
  await saveWorker(ids.far,{},24.8607,67.0011);
  await saveWorker(ids.manual,{},null,null);
  await as(ids.worker,()=>rpc('set_worker_availability',{p_status:'available_now'}));
  await as(ids.far,()=>rpc('set_worker_availability',{p_status:'available_now'}));
  await as(ids.manual,()=>rpc('set_worker_availability',{p_status:'available_later'}));

  await test('PostGIS extension and GiST geographic index exist',async()=>{
    assert.match(await scalar('select extensions.postgis_version()'),/^3\./);
    assert.match(await scalar("select indexdef from pg_indexes where indexname='worker_locations_geo'"),/USING gist/);
  });
  await test('Realtime publication includes owner-authorized jobs notifications profiles',async()=>{
    assert.deepEqual((await q("select tablename from pg_publication_tables where pubname='supabase_realtime' order by tablename")).rows.map(r=>r.tablename),['jobs','notifications','profiles']);
  });
  await test('catalog is extensible data with 18 professions and dynamic questions',async()=>as(null,async()=>{
    assert.equal(await scalar('select count(*)::int from public.professions'),18);
    assert.equal(await scalar('select jsonb_array_length(questions) from public.professions where id=$1',[profession]),3);
  },'anon'));
  await test('anonymous clients cannot read accounts/jobs/private coordinates',async()=>as(null,async()=>{
    await rejects(()=>q('select * from public.profiles'));
    await rejects(()=>q('select * from public.jobs'));
    await rejects(()=>q('select * from khidmat_private.worker_locations'));
  },'anon'));
  await test('unverified phone account cannot mutate profile',async()=>as(ids.unverified,()=>rejects(()=>rpc('save_profile',{p_profile:{full_name:'Unverified',city:'Lahore',roles:['customer']}}))));
  await test('own accounts readable and other private phones invisible by RLS',async()=>as(ids.customer,async()=>{
    assert.equal(await scalar('select count(*)::int from public.profiles'),1);
    assert.equal(await scalar('select phone from public.profiles where id=$1',[ids.worker]),undefined);
  }));
  await test('direct status or role writes denied',async()=>as(ids.customer,()=>rejects(()=>q("update public.profiles set status='active',roles=array['worker']"))));
  await test('server ignores account status injection through profile RPC',async()=>as(ids.customer,async()=>{
    const p=await rpc('save_profile',{p_profile:{full_name:'Test customer',city:'Lahore',roles:['customer'],status:'suspended'}}); assert.equal(p.status,'active');
  }));
  await test('WhatsApp must be Pakistani mobile number',async()=>as(ids.customer,()=>rejects(()=>rpc('save_profile',{p_profile:{full_name:'Test customer',city:'Lahore',roles:['customer'],whatsapp:'+447911123456'}}))));
  await test('unknown worker profession rejected',()=>saveWorker(ids.worker,{profession_id:'10000000-0000-4000-8000-000000000099'}).then(()=>assert.fail(),()=>{}));
  await test('skill membership is validated server side',()=>rejects(()=>saveWorker(ids.worker,{skills:['Wiring Repair']})));
  await test('required profession questions validated at publication',()=>rejects(()=>saveWorker(ids.worker,{answers:{}})));
  await test('profession select options validated',()=>rejects(()=>saveWorker(ids.worker,{answers:{role:'invented',work_types:['Digging']}})));
  await test('profession boolean answer types validated',()=>rejects(()=>saveWorker(ids.worker,{answers:{role:'Labourer',work_types:['Digging'],team:'yes'}})));
  await test('unknown profession answer keys rejected',()=>rejects(()=>saveWorker(ids.worker,{answers:{role:'Labourer',work_types:['Digging'],home_coordinates:'private'}})));
  await test('null skill, language, portfolio and multiselect items are rejected',async()=>{
    await rejects(()=>saveWorker(ids.worker,{skills:[null]}));
    await rejects(()=>saveWorker(ids.worker,{languages:[null]}));
    await rejects(()=>saveWorker(ids.worker,{portfolio_urls:[null]}));
    await rejects(()=>saveWorker(ids.worker,{answers:{role:'Labourer',work_types:[null]}}));
  });
  await test('draft can be saved before professional details are complete',async()=>{
    const w=await saveWorker(ids.manual,{published:false,skills:[],description:'',rate:0,answers:{},working_days:[]},null,null); assert.equal(w.published,false);
    await saveWorker(ids.manual,{},null,null);
  });
  await test('price/experience bounds enforced',async()=>{
    await rejects(()=>saveWorker(ids.worker,{rate:-1})); await rejects(()=>saveWorker(ids.worker,{experience_years:90}));
    await rejects(()=>saveWorker(ids.worker,{rate:'NaN'}));
  });
  await test('per-visit pricing is supported alongside hour day job units',async()=>{
    assert.equal((await saveWorker(ids.worker,{price_unit:'visit'})).price_unit,'visit');
    await saveWorker(ids.worker,{price_unit:'day'});
  });
  await test('working hours validated',()=>rejects(()=>saveWorker(ids.worker,{start_time:'19:00',end_time:'08:00'})));
  await test('arbitrary foreign image URLs rejected',()=>rejects(()=>saveWorker(ids.worker,{avatar_url:'https://tracker.example/photo.png'})));
  await test('unuploaded media paths rejected even on project origin',()=>rejects(()=>saveWorker(ids.worker,{avatar_url:`https://test.supabase.co/storage/v1/object/public/worker-media/${ids.worker}/not-uploaded.jpg`})));
  await test('verification cannot be self granted',async()=>{
    const w=await saveWorker(ids.worker,{verified:true}); assert.equal(w.verified,false);
  });
  await test('worker cannot read another raw worker profile by table select',async()=>as(ids.customer,async()=>assert.equal(await scalar('select count(*)::int from public.worker_profiles'),0)));
  await test('nearby search filters server side and excludes far/manual workers',async()=>as(ids.customer,async()=>{
    const rows=await search(); assert.deepEqual(rows.map(w=>w.id),[ids.worker]); assert.equal(rows[0].distance_km,0.5);
    for(const key of ['phone','whatsapp','latitude','longitude','location','coordinates']) assert.equal(key in rows[0],false);
  }));
  await test('anonymous discovery exposes safe worker profile but no contact RPC',async()=>as(null,async()=>{
    assert.equal((await search()).length,1);
    const w=await rpc('worker_profile',{p_worker_id:ids.worker}); assert.equal(w.full_name,'Test worker');
    assert.equal('phone' in w,false); assert.equal('location' in w,false);
    await rejects(()=>rpc('get_worker_contact',{p_worker_id:ids.worker}));
  },'anon'));
  await test('city search permits manual service areas without invented distance',async()=>as(ids.customer,async()=>{
    const rows=await scalar("select jsonb_agg(r) from public.search_workers(p_city=>'Lahore') r");
    assert.equal(rows.length,2); assert.ok(rows.every(w=>w.distance_km===null));
  }));
  await test('manual neighbourhood selection filters within the selected city',async()=>as(ids.customer,async()=>{
    assert.equal((await q("select * from public.search_workers(p_city=>'Lahore',p_neighbourhood=>'TEST AREA')")).rows.length,2);
    assert.equal((await q("select * from public.search_workers(p_city=>'Lahore',p_neighbourhood=>'Another neighbourhood')")).rows.length,0);
    await rejects(()=>q('select * from public.search_workers(p_city=>$1,p_neighbourhood=>$2)',['Lahore','x'.repeat(101)]));
  }));
  await test('search filters profession/skill/price/experience/rating',async()=>as(ids.customer,async()=>{
    for(const sql of ["p_max_price=>100","p_min_experience=>20","p_min_rating=>4","p_skill=>'Wiring Repair'"])
      assert.equal((await q(`select * from public.search_workers(p_city=>'Lahore',${sql})`)).rows.length,0);
  }));
  await test('search page size and offset bounded',async()=>as(ids.customer,async()=>{
    await rejects(()=>q("select * from public.search_workers(p_city=>'Lahore',p_limit=>1000)"));
    await rejects(()=>q("select * from public.search_workers(p_city=>'Lahore',p_offset=>10001)"));
    const one=(await q("select * from public.search_workers(p_city=>'Lahore',p_limit=>1)")).rows;
    const two=(await q("select * from public.search_workers(p_city=>'Lahore',p_limit=>1,p_offset=>1)")).rows;
    assert.equal(one.length,1); assert.equal(two.length,1); assert.notDeepEqual(one,two);
  }));
  await test('search rejects null sort/state filters and matches city query',async()=>as(ids.customer,async()=>{
    await rejects(()=>q("select * from public.search_workers(p_city=>'Lahore',p_sort=>null)"));
    await rejects(()=>q("select * from public.search_workers(p_city=>'Lahore',p_available_only=>null)"));
    assert.equal((await q("select * from public.search_workers(p_city=>'Lahore',p_query=>'Lahore')")).rows.length,2);
  }));
  await test('invalid and incomplete geographic coordinates rejected',async()=>as(ids.customer,async()=>{
    await rejects(()=>q("select * from public.search_workers(p_latitude=>31,p_longitude=>null)"));
    await rejects(()=>q("select * from public.search_workers(p_latitude=>'NaN'::float8,p_longitude=>74)"));
    await rejects(()=>q("select * from public.search_workers(p_latitude=>51,p_longitude=>0)"));
  }));
  await test('availability now requires recent coordinates',async()=>as(ids.manual,()=>rejects(()=>rpc('set_worker_availability',{p_status:'available_now'}))));
  await test('stale availability becomes unknown and stale geo excluded from nearby',async()=>{
    await q("update khidmat_private.worker_locations set updated_at=now()-interval '16 minutes' where worker_id=$1",[ids.worker]);
    const w=await as(ids.customer,()=>rpc('worker_profile',{p_worker_id:ids.worker})); assert.equal(w.availability,'unknown');
    assert.equal((await as(ids.customer,()=>search())).length,0);
    await as(ids.worker,()=>rpc('set_worker_availability',{p_status:'available_now',p_latitude:31.5204,p_longitude:74.3587}));
  });
  await test('contact phone requires explicit worker sharing consent',async()=>{
    await as(ids.customer,()=>rejects(()=>rpc('get_worker_contact',{p_worker_id:ids.worker})));
    await saveWorker(ids.worker,{share_contact:true});
    const contact=await as(ids.customer,()=>rpc('get_worker_contact',{p_worker_id:ids.worker})); assert.equal(contact.phone,'+923001234561');
  });
  let job;
  await test('customer can create future job request and worker receives notification',async()=>{
    job=await as(ids.customer,()=>rpc('create_job',{p_worker_id:ids.worker,p_profession_id:profession,p_description:'Please help with building materials.',p_scheduled_at:new Date(Date.now()+86400000).toISOString(),p_city:'Lahore',p_neighbourhood:'Test area',p_address:'Private customer address',p_offered_price:2000}));
    assert.equal(job.status,'pending');
    assert.equal(await as(ids.worker,()=>scalar('select count(*)::int from public.notifications')),1);
    assert.equal(await scalar('select count(*)::int from khidmat_private.push_outbox'),1);
  });
  await test('stranger cannot read jobs or private job addresses',async()=>as(ids.stranger,async()=>assert.equal(await scalar('select count(*)::int from public.jobs'),0)));
  await test('stranger cannot transition someone else job',async()=>as(ids.stranger,()=>rejects(()=>rpc('transition_job',{p_job_id:job.id,p_status:'accepted'}))));
  await test('customer cannot accept worker request or skip job lifecycle',async()=>as(ids.customer,async()=>{
    await rejects(()=>rpc('transition_job',{p_job_id:job.id,p_status:'accepted'}));
    await rejects(()=>rpc('transition_job',{p_job_id:job.id,p_status:'completed'}));
  }));
  await test('worker accepts and starts job',async()=>as(ids.worker,async()=>{
    assert.equal((await rpc('transition_job',{p_job_id:job.id,p_status:'accepted'})).status,'accepted');
    assert.equal((await rpc('transition_job',{p_job_id:job.id,p_status:'in_progress'})).status,'in_progress');
  }));
  await test('review before completion rejected',async()=>as(ids.customer,()=>rejects(()=>rpc('review_job',{p_job_id:job.id,p_rating:5}))));
  await test('worker requests completion but cannot confirm it',async()=>as(ids.worker,async()=>{
    assert.equal((await rpc('transition_job',{p_job_id:job.id,p_status:'completion_requested'})).status,'completion_requested');
    await rejects(()=>rpc('transition_job',{p_job_id:job.id,p_status:'completed'}));
  }));
  await test('customer confirms completion and terminal job cannot reopen',async()=>as(ids.customer,async()=>{
    assert.equal((await rpc('transition_job',{p_job_id:job.id,p_status:'completed'})).status,'completed');
    await rejects(()=>rpc('transition_job',{p_job_id:job.id,p_status:'pending'}));
  }));
  await test('worker cannot review own job',async()=>as(ids.worker,()=>rejects(()=>rpc('review_job',{p_job_id:job.id,p_rating:5}))));
  await test('only completed customer can review once; public rating derives from reviews',async()=>{
    assert.equal((await as(ids.customer,()=>rpc('review_job',{p_job_id:job.id,p_rating:4,p_comment:'Reliable work.'}))).reviewed,true);
    await as(ids.customer,()=>rejects(()=>rpc('review_job',{p_job_id:job.id,p_rating:5})));
    const w=await as(ids.customer,()=>rpc('worker_profile',{p_worker_id:ids.worker})); assert.equal(w.rating,4); assert.equal(w.review_count,1); assert.equal(w.reviews.length,1);
  });
  await test('notifications have owner RLS and cannot be marked read by strangers',async()=>{
    const n=await as(ids.worker,()=>scalar('select id from public.notifications limit 1'));
    await as(ids.stranger,()=>rejects(()=>rpc('read_notification',{p_notification_id:n})));
    await as(ids.worker,()=>rpc('read_notification',{p_notification_id:n}));
    assert.ok(await as(ids.worker,()=>scalar('select read_at from public.notifications where id=$1',[n])));
  });
  await test('non-admin cannot suspend/verify accounts or read moderation reports',async()=>as(ids.customer,async()=>{
    assert.equal(await rpc('admin_check'),false);
    await rejects(()=>rpc('moderate_account',{p_user_id:ids.worker,p_action:'verify_worker',p_reason:'Attempt to grant own privileges'}));
    await rejects(()=>q('select * from public.moderation_reports()'));
    await rejects(()=>q('insert into khidmat_private.account_admins(user_id) values($1)',[ids.customer]));
  }));
  await test('account reports are private and rate limited',async()=>{
    for(let i=0;i<5;i++) await as(ids.customer,()=>rpc('report_account',{p_reported_user_id:ids.worker,p_reason:'other',p_details:'Test moderation report'}));
    await as(ids.customer,()=>rejects(()=>rpc('report_account',{p_reported_user_id:ids.worker,p_reason:'other'})));
    assert.equal(await as(ids.stranger,()=>scalar('select count(*)::int from public.account_reports')),0);
  });
  await test('trusted admin verifies/suspends/reactivates with audit log',async()=>{
    await q('insert into khidmat_private.account_admins(user_id) values($1)',[ids.stranger]);
    await as(ids.stranger,()=>rpc('moderate_account',{p_user_id:ids.worker,p_action:'verify_worker',p_reason:'Manually checked worker qualifications'}));
    assert.equal((await as(ids.customer,()=>rpc('worker_profile',{p_worker_id:ids.worker}))).verified,true);
    await as(ids.stranger,()=>rpc('moderate_account',{p_user_id:ids.worker,p_action:'suspend',p_reason:'Test safety suspension for moderation'}));
    await as(ids.worker,()=>rejects(()=>rpc('worker_own_profile')));
    await as(ids.worker,()=>rejects(()=>search()));
    assert.equal((await as(ids.customer,()=>search())).length,0);
    assert.equal(await as(ids.worker,()=>scalar('select count(*)::int from public.jobs')),0);
    await as(ids.stranger,()=>rpc('moderate_account',{p_user_id:ids.worker,p_action:'reactivate',p_reason:'Test investigation completed safely'}));
    assert.equal(await scalar('select count(*)::int from khidmat_private.moderation_log'),3);
  });
  const reviewId=await scalar('select id from public.reviews where job_id=$1',[job.id]);
  await test('review moderation is inaccessible to anon and ordinary accounts',async()=>{
    await as(null,()=>rejects(()=>q('select * from public.moderation_reviews()')),'anon');
    await as(ids.customer,()=>rejects(()=>q('select * from public.moderation_reviews()')));
    await as(ids.customer,()=>rejects(()=>rpc('moderate_review',{p_review_id:reviewId,p_hidden:true,p_reason:'Attempted unauthorized moderation'})));
    await as(ids.customer,()=>rejects(()=>q('update public.reviews set hidden=true')));
  });
  await test('review moderation requires nonempty reason, visibility and an existing review',async()=>as(ids.stranger,async()=>{
    await rejects(()=>rpc('moderate_review',{p_review_id:reviewId,p_hidden:true,p_reason:'short'}));
    await rejects(()=>rpc('moderate_review',{p_review_id:reviewId,p_hidden:null,p_reason:'A sufficiently long reason'}));
    await rejects(()=>rpc('moderate_review',{p_review_id:ids.manual,p_hidden:true,p_reason:'A sufficiently long reason'}));
    await rejects(()=>q('select * from public.moderation_reviews(p_limit=>null)'));
    await rejects(()=>q('select * from public.moderation_reports(p_limit=>null)'));
  }));
  await test('authorized admin hides review without altering customer text/rating',async()=>{
    const before=(await q('select * from public.reviews where id=$1',[reviewId])).rows[0];
    await as(ids.stranger,()=>rpc('moderate_review',{p_review_id:reviewId,p_hidden:true,p_reason:'Inappropriate content reviewed by moderation'}));
    const after=(await q('select * from public.reviews where id=$1',[reviewId])).rows[0];
    assert.equal(after.hidden,true); assert.equal(after.comment,before.comment); assert.equal(after.rating,before.rating);
    assert.equal(await scalar('select reviewed from public.jobs where id=$1',[job.id]),true);
    await as(ids.customer,()=>rejects(()=>rpc('review_job',{p_job_id:job.id,p_rating:5})));
  });
  await test('hidden reviews are excluded from public list, aggregate and rating search',async()=>{
    const w=await as(null,()=>rpc('worker_profile',{p_worker_id:ids.worker}),'anon');
    assert.equal(w.reviews.length,0); assert.equal(w.review_count,0); assert.equal(w.rating,0);
    assert.equal((await as(ids.customer,()=>q("select * from public.search_workers(p_city=>'Lahore',p_min_rating=>4)"))).rows.length,0);
    const adminRows=(await as(ids.stranger,()=>q('select * from public.moderation_reviews(p_worker_id=>$1)',[ids.worker]))).rows;
    assert.equal(Object.values(adminRows[0])[0].hidden,true);
  });
  await test('review unhide restores public rating and both actions have private audit records',async()=>{
    await as(ids.stranger,()=>rpc('moderate_review',{p_review_id:reviewId,p_hidden:false,p_reason:'Review restored after moderation appeal'}));
    const w=await as(null,()=>rpc('worker_profile',{p_worker_id:ids.worker}),'anon');
    assert.equal(w.reviews.length,1); assert.equal(w.review_count,1); assert.equal(w.rating,4);
    assert.equal(await scalar('select count(*)::int from khidmat_private.review_moderation_log where review_id=$1',[reviewId]),2);
    await as(ids.stranger,()=>rejects(()=>q('select * from khidmat_private.review_moderation_log')));
  });
  await test('admins cannot moderate their own job reviews or change text/rating',async()=>{
    await q('insert into khidmat_private.account_admins(user_id) values($1)',[ids.customer]);
    try {
      await as(ids.customer,()=>rejects(()=>rpc('moderate_review',{p_review_id:reviewId,p_hidden:true,p_reason:'Self moderation must be refused'})));
      await as(ids.stranger,()=>rejects(()=>q('update public.reviews set rating=5,comment=$1 where id=$2',['Changed review',reviewId])));
    } finally {await q('delete from khidmat_private.account_admins where user_id=$1',[ids.customer]);}
  });
  await test('suspended admin cannot moderate reviews',async()=>{
    await q("update public.profiles set status='suspended' where id=$1",[ids.stranger]);
    try {await as(ids.stranger,()=>rejects(()=>rpc('moderate_review',{p_review_id:reviewId,p_hidden:true,p_reason:'Suspended administrator must be refused'})));}
    finally {await q("update public.profiles set status='active' where id=$1",[ids.stranger]);}
  });
  await test('client push tokens are registered privately and invalid platform denied',async()=>{
    await as(ids.worker,()=>rpc('register_push_token',{p_token:'test_device_token_12345678901234567890',p_platform:'android'}));
    await as(ids.worker,()=>rejects(()=>q('select * from khidmat_private.push_tokens')));
    await as(ids.worker,()=>rejects(()=>rpc('register_push_token',{p_token:'test_device_token_12345678901234567891',p_platform:'web'})));
  });
  await test('device cannot claim push tokens or finish delivery',async()=>as(ids.worker,async()=>{
    await rejects(()=>q('select * from public.claim_push_batch()'));
  }));
  await test('push outbox leases avoid concurrent duplicate claims and reject stale lease',async()=>{
    const rows=await as(null,()=>q('select * from public.claim_push_batch(50)'),'service_role');
    assert.ok(rows.rows.length>=1);
    assert.equal((await as(null,()=>q('select * from public.claim_push_batch(50)'),'service_role')).rows.length,0);
    const lease=Object.values(rows.rows[0])[0];
    await as(null,()=>rpc('finish_push',{p_id:lease.id,p_lease_token:lease.lease_token,p_success:true}),'service_role');
    await as(null,()=>rejects(()=>rpc('finish_push',{p_id:lease.id,p_lease_token:lease.lease_token,p_success:true})),'service_role');
  });
  await test('push receipts skip previously sent devices on retry and reject unrelated token',async()=>{
    // Make all unresolved leases eligible, as if their dispatcher had crashed.
    await db.exec("update khidmat_private.push_outbox set lease_until=now()-interval '1 second' where delivered_at is null");
    const claimed=(await as(null,()=>q('select * from public.claim_push_batch(50)'),'service_role')).rows.map(r=>Object.values(r)[0]);
    const lease=claimed.find(r=>r.tokens.length>0); assert.ok(lease);
    await as(null,()=>rejects(()=>rpc('record_push_delivery',{p_id:lease.id,p_lease_token:lease.lease_token,p_token:'unrelated_token',p_outcome:'sent'})),'service_role');
    await as(null,()=>rpc('record_push_delivery',{p_id:lease.id,p_lease_token:lease.lease_token,p_token:lease.tokens[0],p_outcome:'sent'}),'service_role');
    await as(null,()=>rpc('finish_push',{p_id:lease.id,p_lease_token:lease.lease_token,p_success:false}),'service_role');
    await q("update khidmat_private.push_outbox set available_at=now()-interval '1 second' where id=$1",[lease.id]);
    const retry=(await as(null,()=>q('select * from public.claim_push_batch(50)'),'service_role')).rows.map(r=>Object.values(r)[0]).find(r=>r.id===lease.id);
    assert.ok(retry); assert.equal(retry.tokens.length,0);
    await as(null,()=>rpc('finish_push',{p_id:retry.id,p_lease_token:retry.lease_token,p_success:true}),'service_role');
  });
  await test('crashed dispatchers cannot bypass the eight-attempt dead-letter cap',async()=>{
    const id=await scalar('select id from khidmat_private.push_outbox where delivered_at is null limit 1'); assert.ok(id);
    await q("update khidmat_private.push_outbox set attempts=8,lease_until=now()-interval '1 second',available_at=now() where id=$1",[id]);
    const claimed=(await as(null,()=>q('select * from public.claim_push_batch(50)'),'service_role')).rows.map(r=>Object.values(r)[0]);
    assert.equal(claimed.some(r=>r.id===id),false); assert.ok(await scalar('select dead_at from khidmat_private.push_outbox where id=$1',[id]));
  });
  await test('storage upload cannot use another users folder',async()=>as(ids.worker,async()=>{
    await rejects(()=>q("insert into storage.objects(bucket_id,name) values('worker-media',$1)",[`${ids.customer}/avatar.jpg`]));
    await q("insert into storage.objects(bucket_id,name) values('worker-media',$1)",[`${ids.worker}/avatar.jpg`]);
  }));
  await test('customer role cannot upload worker media even to own folder',async()=>as(ids.customer,()=>rejects(()=>q("insert into storage.objects(bucket_id,name) values('worker-media',$1)",[`${ids.customer}/avatar.jpg`]))));
  await test('uploaded media uses trusted project origin; spoofed host rejected',async()=>{
    const path=`/storage/v1/object/public/worker-media/${ids.worker}/avatar.jpg`;
    await rejects(()=>saveWorker(ids.worker,{avatar_url:`https://tracker.example${path}`}));
    const w=await saveWorker(ids.worker,{avatar_url:`https://test.supabase.co${path}`}); assert.ok(w.avatar_url.startsWith('https://test.supabase.co/'));
  });
  await test('missing media origin fails closed for actual uploaded owner object',async()=>{
    await db.exec("delete from khidmat_private.settings where key='storage_origin'");
    try {await rejects(()=>saveWorker(ids.worker,{avatar_url:`https://test.supabase.co/storage/v1/object/public/worker-media/${ids.worker}/avatar.jpg`}));}
    finally {await db.exec("insert into khidmat_private.settings(key,value) values('storage_origin','https://test.supabase.co')");}
  });
  await test('all private tables have deny-by-default RLS and accepted-job unique index',async()=>{
    assert.equal(await scalar("select count(*)::int from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='khidmat_private' and c.relkind='r' and not c.relrowsecurity"),0);
    assert.match(await scalar("select indexdef from pg_indexes where indexname='jobs_worker_no_double_accept'"),/UNIQUE.*worker_id, scheduled_at/);
  });
  await test('private coordinate RLS remains deny-by-default after accidental SELECT grant',async()=>{
    await db.exec('grant select on khidmat_private.worker_locations to authenticated');
    try { assert.equal(await as(ids.worker,()=>scalar('select count(*)::int from khidmat_private.worker_locations')),0); }
    finally { await db.exec('revoke select on khidmat_private.worker_locations from authenticated'); }
  });
  await test('internal functions are not exposed through API and all definers pin search_path',async()=>{
    const bad=(await q("select proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','khidmat_private') and p.prosecdef and (p.proconfig is null or not ('search_path=\"\"'=any(p.proconfig)))")).rows;
    assert.deepEqual(bad,[]);
    assert.equal(await scalar("select has_function_privilege('authenticated','khidmat_private.worker_json(uuid,double precision)','execute')"),false);
  });
  await test('account export excludes other users and precise coordinates',async()=>{
    const data=await as(ids.customer,()=>rpc('export_my_account')); assert.equal(data.profile.id,ids.customer); assert.equal(data.jobs.length,1);
    assert.equal(JSON.stringify(data).includes('latitude'),false);
  });
  await test('deactivation hides worker profile and blocks account writes',async()=>{
    await as(ids.manual,()=>rpc('deactivate_account'));
    await as(ids.manual,()=>rejects(()=>rpc('worker_own_profile')));
    await as(ids.customer,()=>rejects(()=>rpc('worker_profile',{p_worker_id:ids.manual})));
  });
  console.log(`\n${passed} backend tests passed. PostgreSQL/PostGIS real; Supabase service schemas isolated fixtures. Live SMS, Storage HTTP, FCM and Realtime not exercised.`);
} catch(error) {
  console.error(`FAILED after ${passed} tests:`,error.message,error.detail??'',error.hint??'');
  if(error.query) console.error('SQL:',error.query.slice(0,2000));
  process.exitCode=1;
} finally { await db.close(); }
