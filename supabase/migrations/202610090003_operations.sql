begin;
create table khidmat_private.push_delivery_receipts(
 outbox_id uuid not null references khidmat_private.push_outbox(id) on delete cascade,token text not null,
 outcome text not null check(outcome in ('sent','invalid')),created_at timestamptz not null default now(),primary key(outbox_id,token)
);
revoke all on khidmat_private.push_delivery_receipts from public,anon,authenticated;
create table khidmat_private.review_moderation_log(
 id uuid primary key default gen_random_uuid(),review_id uuid not null references public.reviews(id),
 admin_id uuid not null references public.profiles(id),hidden boolean not null,
 reason text not null check(length(reason) between 10 and 1000),created_at timestamptz not null default now()
);
revoke all on khidmat_private.review_moderation_log from public,anon,authenticated;
create function khidmat_private.moderation_reviews(p_worker_id uuid default null,p_limit integer default 30,p_offset integer default 0) returns setof jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not khidmat_private.admin_check() then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_limit is null or p_limit not between 1 and 50 or p_offset is null or p_offset not between 0 and 10000 then raise exception 'Invalid page'; end if;
 return query select to_jsonb(r) from public.reviews r where p_worker_id is null or r.worker_id=p_worker_id order by r.created_at desc,r.id limit p_limit offset p_offset;
end $$;
create function khidmat_private.moderate_review(p_review_id uuid,p_hidden boolean,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active(); r public.reviews;
begin
 if not khidmat_private.admin_check() then raise exception 'Administrator access required' using errcode='42501'; end if;
 perform khidmat_private.throttle('review_moderation',120);
 if p_hidden is null or length(trim(coalesce(p_reason,''))) not between 10 and 1000 then raise exception 'Choose review visibility and record a reason'; end if;
 select * into r from public.reviews where id=p_review_id for update;
 if not found then raise exception 'Review not found'; end if;
 if v_uid in (r.customer_id,r.worker_id) then raise exception 'Another administrator must moderate your own job review' using errcode='42501'; end if;
 if r.hidden=p_hidden then return; end if;
 update public.reviews set hidden=p_hidden where id=r.id;
 insert into khidmat_private.review_moderation_log(review_id,admin_id,hidden,reason) values(r.id,v_uid,p_hidden,trim(p_reason));
end $$;
create function khidmat_private.moderation_reports(p_limit integer default 30,p_offset integer default 0) returns setof jsonb language plpgsql stable security definer set search_path='' as $$
begin
 if not khidmat_private.admin_check() then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_limit is null or p_limit not between 1 and 50 or p_offset is null or p_offset not between 0 and 10000 then raise exception 'Invalid page'; end if;
 return query select to_jsonb(r) from public.account_reports r order by created_at desc,id limit p_limit offset p_offset;
end $$;
create function khidmat_private.export_my_account() returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active(); begin
 return jsonb_build_object('exported_at',now(),'profile',(select to_jsonb(p) from public.profiles p where id=v_uid),
 'worker',khidmat_private.worker_json(v_uid),'jobs',coalesce((select jsonb_agg(to_jsonb(j)) from public.jobs j where customer_id=v_uid or worker_id=v_uid),'[]'::jsonb),
 'reviews_written',coalesce((select jsonb_agg(to_jsonb(r)) from public.reviews r where customer_id=v_uid),'[]'::jsonb),
 'reports_written',coalesce((select jsonb_agg(to_jsonb(r)) from public.account_reports r where reporter_id=v_uid),'[]'::jsonb));
end $$;
create function khidmat_private.deactivate_account() returns void language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active(); j public.jobs; begin
 if exists(select 1 from public.jobs where (customer_id=v_uid or worker_id=v_uid) and status in ('accepted','in_progress','completion_requested')) then raise exception 'Resolve your active jobs before deactivating your account'; end if;
 update public.worker_profiles set published=false,availability='offline',availability_updated_at=now(),updated_at=now() where id=v_uid;
 for j in update public.jobs set status='cancelled',updated_at=now() where (customer_id=v_uid or worker_id=v_uid) and status='pending' returning * loop
  perform khidmat_private.notify(case when j.customer_id=v_uid then j.worker_id else j.customer_id end,j.id,'Job cancelled','The other account is no longer available.');
 end loop;
 delete from khidmat_private.push_tokens where user_id=v_uid;
 delete from khidmat_private.worker_locations where worker_id=v_uid;
 update public.profiles set status='deactivated',updated_at=now() where id=v_uid;
end $$;
-- Service-role-only leasing RPCs: no device can obtain tokens or enqueue pushes.
create function khidmat_private.claim_push_batch(p_limit integer default 20) returns setof jsonb language plpgsql security definer set search_path='' as $$
declare r record; v_lease uuid; begin
 if auth.role()<>'service_role' then raise exception 'Service role required' using errcode='42501'; end if;
 if p_limit is null or p_limit not between 1 and 50 then raise exception 'Invalid batch size'; end if;
 -- A dispatcher crash also counts as an attempt. Expired leases cannot bypass
 -- the retry cap indefinitely by never reaching finish_push.
 update khidmat_private.push_outbox set dead_at=now(),lease_until=null,lease_token=null,last_error='Retry limit reached after an expired dispatcher lease'
 where delivered_at is null and dead_at is null and attempts>=8 and (lease_until is null or lease_until<now());
 for r in select o.id,o.notification_id from khidmat_private.push_outbox o
 where o.delivered_at is null and o.dead_at is null and o.attempts<8 and o.available_at<=now() and (o.lease_until is null or o.lease_until<now())
 order by o.available_at for update skip locked limit p_limit loop
  v_lease:=gen_random_uuid();
  update khidmat_private.push_outbox set lease_token=v_lease,lease_until=now()+interval '2 minutes',attempts=attempts+1 where id=r.id;
  return next (select jsonb_build_object('id',r.id,'lease_token',v_lease,'notification_id',n.id,'job_id',n.job_id,'user_id',n.user_id,
   'title','Khidmat update','body','Open Khidmat to view your latest job update.',
   'tokens',coalesce((select jsonb_agg(t.token) from khidmat_private.push_tokens t join public.profiles p on p.id=t.user_id
     where t.user_id=n.user_id and p.status='active' and t.updated_at>now()-interval '90 days'
     and not exists(select 1 from khidmat_private.push_delivery_receipts d where d.outbox_id=r.id and d.token=t.token)),'[]'::jsonb))
   from public.notifications n where n.id=r.notification_id);
 end loop;
end $$;
create function khidmat_private.record_push_delivery(p_id uuid,p_lease_token uuid,p_token text,p_outcome text) returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.role()<>'service_role' then raise exception 'Service role required' using errcode='42501'; end if;
 if not exists(select 1 from khidmat_private.push_outbox o join public.notifications n on n.id=o.notification_id join khidmat_private.push_tokens t on t.user_id=n.user_id
 where o.id=p_id and o.lease_token=p_lease_token and o.delivered_at is null and o.dead_at is null and t.token=p_token) then raise exception 'Invalid push token or lease'; end if;
 insert into khidmat_private.push_delivery_receipts(outbox_id,token,outcome) values(p_id,p_token,p_outcome) on conflict(outbox_id,token) do nothing;
end $$;
create function khidmat_private.finish_push(p_id uuid,p_lease_token uuid,p_success boolean,p_invalid_tokens text[] default '{}',p_error text default '') returns void language plpgsql security definer set search_path='' as $$
declare r khidmat_private.push_outbox; v_uid uuid; begin
 if auth.role()<>'service_role' then raise exception 'Service role required' using errcode='42501'; end if;
 select * into r from khidmat_private.push_outbox where id=p_id and lease_token=p_lease_token and delivered_at is null and dead_at is null for update;
 if not found then raise exception 'Invalid or completed push lease'; end if;
 select user_id into v_uid from public.notifications where id=r.notification_id;
 delete from khidmat_private.push_tokens where token=any(p_invalid_tokens) and user_id=v_uid;
 update khidmat_private.push_outbox set delivered_at=case when p_success then now() else null end,
 dead_at=case when not p_success and r.attempts>=8 then now() else null end,
 available_at=now()+make_interval(secs=>least(3600,30*power(2,least(r.attempts,7)))::integer),
 lease_token=null,lease_until=null,last_error=left(p_error,500) where id=r.id;
end $$;
-- Only these administrative wrappers are exposed; private tables remain hidden.
do $$ declare r record; args text; begin
 for r in select p.oid,p.proname,pg_get_function_arguments(p.oid) signature,pg_get_function_result(p.oid) result,p.proargnames
 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='khidmat_private' and p.proname=any(array[
 'moderation_reports','moderation_reviews','moderate_review','export_my_account','deactivate_account','claim_push_batch','finish_push','record_push_delivery']) loop
  select string_agg(quote_ident(x),',') into args from unnest(r.proargnames) x;
  execute format('create function public.%I(%s) returns %s language sql security invoker set search_path='''' as %L',r.proname,r.signature,r.result,'select * from khidmat_private.'||quote_ident(r.proname)||'('||coalesce(args,'')||');');
  execute format('revoke all on function public.%I(%s) from public,anon,authenticated',r.proname,pg_get_function_identity_arguments(r.oid));
  execute format('revoke all on function khidmat_private.%I(%s) from public,anon,authenticated',r.proname,pg_get_function_identity_arguments(r.oid));
  if r.proname in ('claim_push_batch','finish_push','record_push_delivery') then
   execute format('grant execute on function public.%I(%s) to service_role',r.proname,pg_get_function_identity_arguments(r.oid));
   execute format('grant execute on function khidmat_private.%I(%s) to service_role',r.proname,pg_get_function_identity_arguments(r.oid));
  else
   execute format('grant execute on function public.%I(%s) to authenticated',r.proname,pg_get_function_identity_arguments(r.oid));
   execute format('grant execute on function khidmat_private.%I(%s) to authenticated',r.proname,pg_get_function_identity_arguments(r.oid));
  end if;
 end loop;
end $$;
grant usage on schema khidmat_private to service_role;
-- Defense in depth if an operator accidentally grants private-table privileges.
-- Definer implementations run as the migration owner; clients have no policies.
do $$ declare r record; begin
 for r in select tablename from pg_tables where schemaname='khidmat_private' loop
  execute format('alter table khidmat_private.%I enable row level security',r.tablename);
 end loop;
end $$;
commit;
