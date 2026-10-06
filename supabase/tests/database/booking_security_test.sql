begin;
create extension if not exists pgtap with schema extensions;
set search_path = public, extensions;
select plan(33);
-- Fixtures are rolled back. Production has no fictitious providers.
insert into auth.users(id, email, raw_user_meta_data) values
  ('00000000-0000-4000-8000-000000000001','customer@example.test','{"full_name":"Customer"}'),
  ('00000000-0000-4000-8000-000000000002','provider@example.test','{"full_name":"Provider"}'),
  ('00000000-0000-4000-8000-000000000003','outsider@example.test','{"full_name":"Outsider"}');
insert into public.providers(id,user_id,name,category,city,location,price_min,price_max,is_approved)
values ('00000000-0000-4000-8000-000000000010',
  '00000000-0000-4000-8000-000000000002','Provider','Plumber','Islamabad','G-13',1200,1500,true);
insert into public.providers(id,user_id,name,category,city,location,price_min,price_max)
values ('00000000-0000-4000-8000-000000000020',
  '00000000-0000-4000-8000-000000000003','Other provider','Plumber','Islamabad','G-11',1000,1000);
create temporary table test_ids(label text primary key, id uuid);
grant all on test_ids to authenticated;

set local role authenticated;
set local "request.jwt.claim.sub" = '00000000-0000-4000-8000-000000000001';
select is((select count(*)::integer from public.profiles),1,'Only own private profile is visible');
select throws_ok(
  $$update public.providers set is_approved = true where id = '00000000-0000-4000-8000-000000000010'$$,
  '42501',null,'Client cannot grant provider approval');
select throws_ok(
  $$update public.providers set rating = 5 where id = '00000000-0000-4000-8000-000000000010'$$,
  '42501',null,'Client cannot forge reputation');
insert into test_ids values ('quote', (public.quote_provider(
  '00000000-0000-4000-8000-000000000010')->>'id')::uuid);
select is((select final_price from public.quotes where id = (select id from test_ids where label='quote')),
  1200,'Server chooses provider-authorized price');
insert into test_ids values ('booking',(public.create_booking(
  (select id from test_ids where label='quote'),
  (now() at time zone 'Asia/Karachi')::date+1,'09:00','House 12, G-13, Islamabad','Leaking pipe')->>'id')::uuid);
select is((select status from public.bookings where id=(select id from test_ids where label='booking')),
  'pending','Booking waits for provider acceptance');
select is((public.create_booking(
  (select id from test_ids where label='quote'),
  (now() at time zone 'Asia/Karachi')::date+1,'09:00','House 12, G-13, Islamabad','Leaking pipe')->>'id')::uuid,
  (select id from test_ids where label='booking'),'Retries do not create duplicate bookings');
select throws_ok(
  $$select public.transition_booking((select id from test_ids where label='booking'),'completed')$$,
  'P0001','This status change is not allowed','Customer cannot mark service completed');
select throws_ok(
  $$insert into public.reviews(booking_id,customer_id,provider_id,stars)
    select (select id from test_ids where label='booking'),auth.uid(),
      '00000000-0000-4000-8000-000000000010',5$$,
  '42501',null,'Reviews require completed service');
insert into test_ids values ('other_quote',(public.quote_provider(
  '00000000-0000-4000-8000-000000000010')->>'id')::uuid);
select throws_ok(
  $$select public.create_booking((select id from test_ids where label='other_quote'),
    (now() at time zone 'Asia/Karachi')::date+1,'09:00','House 13, Islamabad','')$$,
  'P0001','This time slot was just booked; choose another slot','Double booking is prevented');
set local "request.jwt.claim.sub" = '00000000-0000-4000-8000-000000000003';
select is((select count(*)::integer from public.bookings),0,'Unrelated user cannot read bookings');
select throws_ok(
  $$insert into public.messages(booking_id,sender_id,body)
    values((select id from test_ids where label='booking'),auth.uid(),'Intrusion')$$,
  '42501',null,'Unrelated user cannot enter private chat');
set local "request.jwt.claim.sub" = '00000000-0000-4000-8000-000000000002';
select lives_ok(
  $$select public.transition_booking((select id from test_ids where label='booking'),'accepted')$$,
  'Assigned provider can accept');
do $$
begin
  perform public.transition_booking((select id from test_ids where label='booking'),'in_progress');
  perform public.transition_booking((select id from test_ids where label='booking'),'completed');
end;
$$;
select is((select count(*)::integer from public.booking_events),4,'Events record every state change');
set local "request.jwt.claim.sub" = '00000000-0000-4000-8000-000000000001';
select throws_ok(
  $$insert into public.reviews(booking_id,customer_id,provider_id,stars)
    values((select id from test_ids where label='booking'),auth.uid(),
      '00000000-0000-4000-8000-000000000020',5)$$,
  '42501',null,'A review cannot be assigned to a different provider');
select lives_ok(
  $$insert into public.reviews(booking_id,customer_id,provider_id,stars)
    values((select id from test_ids where label='booking'),auth.uid(),
      '00000000-0000-4000-8000-000000000010',5)$$,
  'Customer can review completed service');
select throws_ok(
  $$insert into public.reviews(booking_id,customer_id,provider_id,stars)
    values((select id from test_ids where label='booking'),auth.uid(),
      '00000000-0000-4000-8000-000000000010',4)$$,
  '23505',null,'One review is allowed per booking');
select lives_ok(
  $$insert into public.messages(booking_id,sender_id,body)
    values((select id from test_ids where label='booking'),auth.uid(),'Hello provider')$$,
  'Customer can send a real message');
select lives_ok(
  $$insert into storage.objects(bucket_id,name) values
    ('avatars',auth.uid()::text || '/avatar.jpg')$$,
  'Customer can upload their own avatar');
select lives_ok(
  $$insert into storage.objects(bucket_id,name) values
    ('booking-media',(select id::text from test_ids where label='booking') || '/' || auth.uid()::text || '/photo.jpg')$$,
  'Participant can upload private booking media');
select throws_ok(
  $$insert into public.messages(booking_id,sender_id,body,attachment_path)
    values((select id from test_ids where label='booking'),auth.uid(),'',
      (select id::text from test_ids where label='booking') || '/' || auth.uid()::text || '/missing.jpg')$$,
  '42501',null,'Attachments must refer to uploaded media');
select lives_ok(
  $$insert into public.messages(booking_id,sender_id,body,attachment_path)
    values((select id from test_ids where label='booking'),auth.uid(),'',
      (select id::text from test_ids where label='booking') || '/' || auth.uid()::text || '/photo.jpg')$$,
  'Participant can send an uploaded attachment');
set local "request.jwt.claim.sub" = '00000000-0000-4000-8000-000000000003';
select is((select count(*)::integer from storage.objects),0,'Outsiders cannot read private images');
select throws_ok(
  $$insert into storage.objects(bucket_id,name) values
    ('booking-media',(select id::text from test_ids where label='booking') || '/' || auth.uid()::text || '/intrusion.jpg')$$,
  '42501',null,'Outsiders cannot upload into a private conversation');
set local "request.jwt.claim.sub" = '00000000-0000-4000-8000-000000000002';
select is((select count(*)::integer from storage.objects where bucket_id='booking-media'),1,
  'Assigned provider can read the conversation image');
select is((select count(*)::integer from public.messages),2,
  'Assigned provider can read customer text and attachment messages');
select lives_ok(
  $$select public.complete_profile('Experienced Worker','worker','Islamabad','G-13',
    'Plumber',5,'Experienced in plumbing repairs and installation.')$$,
  'Authenticated worker can complete their own profile');
select is((select account_role from public.profiles),'worker','Worker role is persisted');
select is((select experience_years from public.profiles),5,'Work experience is persisted');
select is((select onboarding_completed from public.profiles),true,'Completed profile unlocks the dashboard');
select is((select experience_years from public.providers
  where user_id=auth.uid()),5,'Public worker experience stays synchronized');
select is((select description from public.providers where user_id=auth.uid()),
  'Experienced in plumbing repairs and installation.','Public worker details stay synchronized');
select throws_ok(
  $$update public.profiles set onboarding_completed=true$$,
  '42501',null,'Clients cannot bypass profile validation');
select throws_ok(
  $$select public.complete_profile('Worker','worker','Islamabad','G-13','Plumber',61,'Plumbing repairs')$$,
  'P0001','Enter experience from 0 to 60 years','Invalid experience is rejected');
select * from finish();
rollback;
