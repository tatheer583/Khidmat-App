-- Additive marketplace migration. Run against a NEW development Supabase project
-- first. Existing tables with the same names intentionally cause a failure;
-- never DROP a previous project's tables to make this migration pass.
begin;
create schema if not exists extensions;
create extension if not exists postgis with schema extensions;
do $$ begin
  if (select n.nspname <> 'extensions' from pg_extension e join pg_namespace n on n.oid=e.extnamespace where e.extname='postgis') then
    raise exception 'PostGIS must be installed in extensions. Review the existing project; do not drop its extension or data.';
  end if;
end $$;
create schema khidmat_private;
revoke all on schema khidmat_private from public, anon, authenticated;
grant usage on schema khidmat_private to authenticated;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '' check (length(full_name)<=100),
  phone text not null default '',
  whatsapp text not null default '' check (whatsapp='' or whatsapp ~ '^\+923[0-9]{9}$'),
  city text not null default '' check(length(city)<=80),
  neighbourhood text not null default '' check(length(neighbourhood)<=100),
  roles text[] not null default array['customer'] check(cardinality(roles) between 1 and 2 and roles <@ array['customer','worker']::text[]),
  status text not null default 'active' check(status in ('active','suspended','deactivated')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.professions (
  id uuid primary key default gen_random_uuid(), category text not null,
  name text not null unique, name_ur text not null default '',
  skills jsonb not null default '[]' check(jsonb_typeof(skills)='array'),
  questions jsonb not null default '[]' check(jsonb_typeof(questions)='array'),
  sort_order integer not null default 0, active boolean not null default true
);
create table public.worker_profiles (
  id uuid primary key references public.profiles(id) on delete cascade,
  profession_id uuid not null references public.professions(id),
  skills text[] not null default '{}', experience_years integer not null default 0 check(experience_years between 0 and 60),
  description text not null default '' check(length(description)<=2000),
  languages text[] not null default '{}', rate numeric(12,2) not null default 0 check(rate between 0 and 1000000),
  price_unit text not null default 'day' check(price_unit in ('hour','day','visit','job')),
  service_radius_km double precision not null default 15 check(service_radius_km between 1 and 100),
  working_days integer[] not null default array[1,2,3,4,5,6] check(working_days <@ array[1,2,3,4,5,6,7]),
  start_time time not null default '08:00', end_time time not null default '18:00',
  answers jsonb not null default '{}' check(jsonb_typeof(answers)='object'),
  avatar_url text not null default '', portfolio_urls text[] not null default '{}',
  published boolean not null default false, share_contact boolean not null default false,
  availability text not null default 'unknown' check(availability in ('available_now','available_later','busy','offline','unknown')),
  availability_updated_at timestamptz, verified boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table khidmat_private.worker_locations (
  worker_id uuid primary key references public.worker_profiles(id) on delete cascade,
  location extensions.geography(Point,4326) not null,
  updated_at timestamptz not null default now()
);
create index worker_locations_geo on khidmat_private.worker_locations using gist(location);
create index workers_profession_published on public.worker_profiles(profession_id) where published;
create index workers_skills on public.worker_profiles using gin(skills);
create index profile_city on public.profiles(lower(city));
create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id), worker_id uuid not null references public.profiles(id),
  profession_id uuid not null references public.professions(id),
  customer_name text not null, worker_name text not null,
  description text not null check(length(description) between 10 and 2000),
  scheduled_at timestamptz not null, city text not null check(length(city) between 2 and 80),
  neighbourhood text not null default '' check(length(neighbourhood)<=100),
  address text not null default '' check(length(address)<=300), offered_price numeric(12,2) check(offered_price between 0 and 1000000),
  status text not null default 'pending' check(status in ('pending','accepted','in_progress','completion_requested','completed','cancelled','declined')),
  reviewed boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check(customer_id<>worker_id)
);
create index jobs_customer_recent on public.jobs(customer_id,created_at desc);
create index jobs_worker_recent on public.jobs(worker_id,created_at desc);
create unique index jobs_no_duplicate_pending on public.jobs(customer_id,worker_id,scheduled_at)
  where status in ('pending','accepted','in_progress','completion_requested');
create unique index jobs_worker_no_double_accept on public.jobs(worker_id,scheduled_at)
  where status in ('accepted','in_progress','completion_requested');
create table public.reviews (
  id uuid primary key default gen_random_uuid(), job_id uuid not null unique references public.jobs(id),
  customer_id uuid not null references public.profiles(id), worker_id uuid not null references public.profiles(id),
  rating integer not null check(rating between 1 and 5), comment text not null default '' check(length(comment)<=1000),
  hidden boolean not null default false,
  created_at timestamptz not null default now()
);
create index reviews_worker on public.reviews(worker_id,created_at desc);
create index reviews_worker_visible on public.reviews(worker_id,created_at desc) where not hidden;
create table public.notifications (
  id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(id) on delete cascade,
  job_id uuid references public.jobs(id), title text not null, body text not null,
  read_at timestamptz, created_at timestamptz not null default now()
);
create index notifications_owner on public.notifications(user_id,created_at desc);
create table public.account_reports (
  id uuid primary key default gen_random_uuid(), reporter_id uuid not null references public.profiles(id),
  reported_user_id uuid not null references public.profiles(id), reason text not null check(reason in ('safety','fraud','harassment','inappropriate_profile','other')),
  details text not null default '' check(length(details)<=2000), status text not null default 'open' check(status in ('open','reviewed','dismissed')),
  created_at timestamptz not null default now(), check(reporter_id<>reported_user_id)
);
create table khidmat_private.account_admins(user_id uuid primary key references public.profiles(id), created_at timestamptz not null default now());
create table khidmat_private.settings(key text primary key,value text not null);
create table khidmat_private.moderation_log(id uuid primary key default gen_random_uuid(),admin_id uuid not null,user_id uuid not null,action text not null,reason text not null,created_at timestamptz not null default now());
create table khidmat_private.rate_limits(user_id uuid not null,action text not null,window_start timestamptz not null,hits integer not null default 1, primary key(user_id,action,window_start));
create table khidmat_private.push_tokens(token text primary key check(length(token) between 20 and 4096),user_id uuid not null references public.profiles(id) on delete cascade,platform text not null check(platform in ('android','ios')),updated_at timestamptz not null default now());
create table khidmat_private.push_outbox(
  id uuid primary key default gen_random_uuid(),notification_id uuid not null unique references public.notifications(id) on delete cascade,
  attempts integer not null default 0,available_at timestamptz not null default now(),lease_until timestamptz,lease_token uuid,
  delivered_at timestamptz,dead_at timestamptz,last_error text,created_at timestamptz not null default now()
);
create index push_outbox_pending on khidmat_private.push_outbox(available_at) where delivered_at is null and dead_at is null;

-- No client can set account status, verification, rating, ownership or coordinates
-- through direct table writes. Private relations have no client grants.
alter table public.profiles enable row level security;
alter table public.professions enable row level security;
alter table public.worker_profiles enable row level security;
alter table public.jobs enable row level security;
alter table public.reviews enable row level security;
alter table public.notifications enable row level security;
alter table public.account_reports enable row level security;
revoke all on all tables in schema khidmat_private from public,anon,authenticated;
revoke all on public.profiles,public.professions,public.worker_profiles,public.jobs,public.reviews,public.notifications,public.account_reports from public,anon,authenticated;
grant select on public.professions to anon,authenticated;
grant select on public.profiles,public.worker_profiles,public.jobs,public.notifications,public.account_reports to authenticated;

create function khidmat_private.is_active() returns boolean language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.profiles p join auth.users u on u.id=p.id where p.id=auth.uid() and p.status='active' and u.phone_confirmed_at is not null and u.phone ~ '^\+?923[0-9]{9}$');
$$;
create function khidmat_private.require_active() returns uuid language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is null or not khidmat_private.is_active() then raise exception 'Verified active Pakistani phone account required' using errcode='42501'; end if;
 return auth.uid();
end $$;
create function khidmat_private.require_browse() returns void language plpgsql stable security definer set search_path='' as $$
begin
 if auth.uid() is not null then perform khidmat_private.require_active();
 elsif coalesce(auth.role(),'')<>'anon' then raise exception 'Invalid session' using errcode='42501'; end if;
end $$;
create policy own_profile on public.profiles for select to authenticated using(id=auth.uid());
create policy catalog_active on public.professions for select to anon,authenticated using(active);
create policy own_worker on public.worker_profiles for select to authenticated using(id=auth.uid() and khidmat_private.is_active());
create policy own_jobs on public.jobs for select to authenticated using((customer_id=auth.uid() or worker_id=auth.uid()) and khidmat_private.is_active());
create policy own_notifications on public.notifications for select to authenticated using(user_id=auth.uid() and khidmat_private.is_active());
create policy own_reports on public.account_reports for select to authenticated using(reporter_id=auth.uid() and khidmat_private.is_active());

create function khidmat_private.sync_auth_profile() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.profiles(id,phone) values(new.id,case when coalesce(new.phone,'')='' then '' else '+'||ltrim(new.phone,'+') end)
 on conflict(id) do update set phone=excluded.phone,updated_at=now();
 return new;
end $$;
create trigger khidmat_auth_profile after insert or update of phone,phone_confirmed_at on auth.users for each row execute function khidmat_private.sync_auth_profile();
-- Existing accounts are preserved and only receive a missing marketplace record.
insert into public.profiles(id,phone) select id,case when coalesce(phone,'')='' then '' else '+'||ltrim(phone,'+') end from auth.users on conflict(id) do nothing;

create function khidmat_private.throttle(p_action text,p_max integer,p_minutes integer default 60) returns void language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active(); v_window timestamptz; v_hits integer;
begin
 v_window:=to_timestamp(floor(extract(epoch from now())/(p_minutes*60))*(p_minutes*60));
 insert into khidmat_private.rate_limits(user_id,action,window_start) values(v_uid,p_action,v_window)
 on conflict(user_id,action,window_start) do update set hits=khidmat_private.rate_limits.hits+1 returning hits into v_hits;
 if v_hits>p_max then raise exception 'Too many requests. Try again later.' using errcode='P0001'; end if;
end $$;

create function khidmat_private.save_profile(p_profile jsonb) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active(); v_roles text[];
begin
 perform khidmat_private.throttle('profile',30);
 if jsonb_typeof(p_profile)<>'object' or length(trim(coalesce(p_profile->>'full_name',''))) not between 2 and 100
 or length(trim(coalesce(p_profile->>'city',''))) not between 2 and 80 or length(coalesce(p_profile->>'neighbourhood',''))>100
 or jsonb_typeof(p_profile->'roles')<>'array' then raise exception 'Enter name, city and account roles'; end if;
 select array_agg(distinct value) into v_roles from jsonb_array_elements_text(p_profile->'roles');
 if cardinality(v_roles) not between 1 and 2 or not v_roles <@ array['customer','worker']::text[] then raise exception 'Choose customer or worker roles'; end if;
 if coalesce(p_profile->>'whatsapp','')<>'' and (p_profile->>'whatsapp') !~ '^\+923[0-9]{9}$' then raise exception 'Enter a Pakistani WhatsApp number'; end if;
 update public.profiles set full_name=trim(p_profile->>'full_name'),city=trim(p_profile->>'city'),neighbourhood=trim(coalesce(p_profile->>'neighbourhood','')),
 roles=v_roles,whatsapp=coalesce(p_profile->>'whatsapp',''),updated_at=now() where id=v_uid;
 if not 'worker'=any(v_roles) then update public.worker_profiles set published=false,availability='offline',availability_updated_at=now() where id=v_uid; end if;
 return (select to_jsonb(p) from public.profiles p where id=v_uid);
end $$;

create function khidmat_private.effective_availability(p_status text,p_updated timestamptz,p_geo_updated timestamptz) returns text language sql stable set search_path='' as $$
 select case when p_status='available_now' and (p_updated is null or p_updated<now()-interval '15 minutes' or p_geo_updated is null or p_geo_updated<now()-interval '15 minutes') then 'unknown'
 when p_status in ('available_later','busy') and (p_updated is null or p_updated<now()-interval '24 hours') then 'unknown' else p_status end;
$$;
create function khidmat_private.worker_json(p_worker_id uuid,p_distance double precision default null) returns jsonb language sql stable security definer set search_path='' as $$
 select to_jsonb(w)||jsonb_build_object('name',p.full_name,'full_name',p.full_name,'city',p.city,'neighbourhood',p.neighbourhood,'profession_name',pr.name,
 'availability',khidmat_private.effective_availability(w.availability,w.availability_updated_at,l.updated_at),'location_updated_at',l.updated_at,
 'rating',coalesce(r.rating,0),'review_count',coalesce(r.review_count,0),'distance_km',p_distance)
 from public.worker_profiles w join public.profiles p on p.id=w.id join public.professions pr on pr.id=w.profession_id
 left join khidmat_private.worker_locations l on l.worker_id=w.id
 left join lateral(select round(avg(rating),2) rating,count(*) review_count from public.reviews where worker_id=w.id and not hidden) r on true
 where w.id=p_worker_id;
$$;
create function khidmat_private.valid_media(p_url text,p_uid uuid) returns boolean language sql stable set search_path='' as $$
 select coalesce(p_url='' or (length(p_url)<=1000 and
 starts_with(p_url,(select rtrim(value,'/')||'/storage/v1/object/public/worker-media/' from khidmat_private.settings where key='storage_origin')) and
 split_part(p_url,'/storage/v1/object/public/worker-media/',2) ~ ('^'||p_uid::text||'/[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$')
 and exists(select 1 from storage.objects o where o.bucket_id='worker-media' and o.name=split_part(p_url,'/storage/v1/object/public/worker-media/',2))),false);
$$;
create function khidmat_private.validate_answers(p_answers jsonb,p_questions jsonb,p_required boolean) returns void language plpgsql set search_path='' as $$
declare q jsonb; v jsonb; opt text; k text;
begin
 if jsonb_typeof(p_answers)<>'object' or octet_length(p_answers::text)>16000 then raise exception 'Invalid profession answers'; end if;
 for k in select jsonb_object_keys(p_answers) loop
  if not exists(select 1 from jsonb_array_elements(p_questions) x where x->>'key'=k) then raise exception 'Unknown profession question'; end if;
 end loop;
 for q in select * from jsonb_array_elements(p_questions) loop
  v:=p_answers->(q->>'key');
  if v is null or v='null'::jsonb or v='""'::jsonb or v='[]'::jsonb then
   if p_required and coalesce((q->>'required')::boolean,false) then raise exception 'Complete question: %',q->>'label'; end if;
   continue;
  end if;
  case q->>'type'
   when 'boolean' then if jsonb_typeof(v)<>'boolean' then raise exception 'Expected a yes/no answer'; end if;
   when 'number' then if jsonb_typeof(v)<>'number' or (v#>>'{}')::numeric not between 0 and 1000000 then raise exception 'Invalid numeric answer'; end if;
   when 'select' then if jsonb_typeof(v)<>'string' or not (q->'options') ? (v#>>'{}') then raise exception 'Choose a listed answer'; end if;
   when 'multiselect' then
    if jsonb_typeof(v)<>'array' or jsonb_array_length(v)>30 then raise exception 'Choose listed answers'; end if;
    for opt in select jsonb_array_elements_text(v) loop if opt is null or not (q->'options') ? opt then raise exception 'Choose listed answers'; end if; end loop;
   when 'text' then if jsonb_typeof(v)<>'string' or length(v#>>'{}')>500 then raise exception 'Answer too long'; end if;
   else raise exception 'Unsupported profession question type';
  end case;
 end loop;
end $$;
create function khidmat_private.update_location(p_uid uuid,p_latitude double precision,p_longitude double precision) returns void language plpgsql set search_path='' as $$
begin
 if (p_latitude is null)<>(p_longitude is null) then raise exception 'Both coordinates are required'; end if;
 if p_latitude is null then return; end if;
 if not p_latitude between 23 and 38 or not p_longitude between 60 and 78 then raise exception 'Choose a service location in Pakistan'; end if;
 insert into khidmat_private.worker_locations(worker_id,location,updated_at)
 values(p_uid,extensions.st_setsrid(extensions.st_makepoint(p_longitude,p_latitude),4326)::extensions.geography,now())
 on conflict(worker_id) do update set location=excluded.location,updated_at=now();
end $$;
create function khidmat_private.save_worker_profile(p_profile jsonb,p_latitude double precision default null,p_longitude double precision default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active(); v_prof public.professions; v_skills text[]; v_languages text[]; v_days integer[]; v_portfolio text[]; v_published boolean; s text;
begin
 perform khidmat_private.throttle('worker_profile',30);
 if not exists(select 1 from public.profiles where id=v_uid and 'worker'=any(roles) and length(full_name)>=2 and length(city)>=2) then raise exception 'Save your worker account name and city first'; end if;
 if jsonb_typeof(p_profile)<>'object' then raise exception 'Invalid worker profile'; end if;
 select * into v_prof from public.professions where id=(p_profile->>'profession_id')::uuid and active;
 if not found then raise exception 'Choose an active profession'; end if;
 v_published:=coalesce((p_profile->>'published')::boolean,false);
 if jsonb_typeof(coalesce(p_profile->'skills','[]'))<>'array' or jsonb_typeof(coalesce(p_profile->'languages','[]'))<>'array'
 or jsonb_typeof(coalesce(p_profile->'working_days','[]'))<>'array' or jsonb_typeof(coalesce(p_profile->'portfolio_urls','[]'))<>'array' then raise exception 'Invalid profile lists'; end if;
 select coalesce(array_agg(distinct value),'{}') into v_skills from jsonb_array_elements_text(coalesce(p_profile->'skills','[]'));
 if cardinality(v_skills)>30 then raise exception 'Too many skills'; end if;
 foreach s in array v_skills loop if s is null or not v_prof.skills ? s then raise exception 'Skill does not belong to profession'; end if; end loop;
 select coalesce(array_agg(distinct value),'{}') into v_languages from jsonb_array_elements_text(coalesce(p_profile->'languages','[]'));
 if cardinality(v_languages)>10 or exists(select 1 from unnest(v_languages) x where x is null or length(x)>40 or length(trim(x))=0) then raise exception 'Invalid languages'; end if;
 select coalesce(array_agg(distinct value::integer),'{}') into v_days from jsonb_array_elements_text(coalesce(p_profile->'working_days','[]'));
 select coalesce(array_agg(value),'{}') into v_portfolio from jsonb_array_elements_text(coalesce(p_profile->'portfolio_urls','[]'));
 if cardinality(v_portfolio)>8 then raise exception 'Maximum 8 portfolio photos'; end if;
 if not khidmat_private.valid_media(coalesce(p_profile->>'avatar_url',''),v_uid) then raise exception 'Use your own uploaded profile photo'; end if;
 foreach s in array v_portfolio loop if s='' or not khidmat_private.valid_media(s,v_uid) then raise exception 'Use your own uploaded work photos'; end if; end loop;
 if v_published and (cardinality(v_skills)=0 or length(trim(coalesce(p_profile->>'description','')))<10 or cardinality(v_days)=0 or (p_profile->>'rate')::numeric<=0) then raise exception 'Add skills, description, working days and price before publishing'; end if;
 if coalesce((p_profile->>'start_time')::time,'08:00'::time)>=coalesce((p_profile->>'end_time')::time,'18:00'::time) then raise exception 'Closing time must be after opening time'; end if;
 perform khidmat_private.validate_answers(coalesce(p_profile->'answers','{}'),v_prof.questions,v_published);
 insert into public.worker_profiles(id,profession_id,skills,experience_years,description,languages,rate,price_unit,service_radius_km,working_days,start_time,end_time,answers,avatar_url,portfolio_urls,published,share_contact)
 values(v_uid,v_prof.id,v_skills,coalesce((p_profile->>'experience_years')::integer,0),trim(coalesce(p_profile->>'description','')),v_languages,
 coalesce((p_profile->>'rate')::numeric,0),coalesce(p_profile->>'price_unit','day'),coalesce((p_profile->>'service_radius_km')::double precision,15),v_days,
 coalesce((p_profile->>'start_time')::time,'08:00'::time),coalesce((p_profile->>'end_time')::time,'18:00'::time),coalesce(p_profile->'answers','{}'),
 coalesce(p_profile->>'avatar_url',''),v_portfolio,v_published,coalesce((p_profile->>'share_contact')::boolean,false))
 on conflict(id) do update set profession_id=excluded.profession_id,skills=excluded.skills,experience_years=excluded.experience_years,description=excluded.description,
 languages=excluded.languages,rate=excluded.rate,price_unit=excluded.price_unit,service_radius_km=excluded.service_radius_km,working_days=excluded.working_days,
 start_time=excluded.start_time,end_time=excluded.end_time,answers=excluded.answers,avatar_url=excluded.avatar_url,portfolio_urls=excluded.portfolio_urls,
 published=excluded.published,share_contact=excluded.share_contact,updated_at=now();
 perform khidmat_private.update_location(v_uid,p_latitude,p_longitude);
 return khidmat_private.worker_json(v_uid);
end $$;
create function khidmat_private.worker_own_profile() returns jsonb language plpgsql stable security definer set search_path='' as $$
begin return khidmat_private.worker_json(khidmat_private.require_active()); end $$;
create function khidmat_private.worker_profile(p_worker_id uuid) returns jsonb language plpgsql stable security definer set search_path='' as $$
declare v_result jsonb;
begin
 perform khidmat_private.require_browse();
 if not exists(select 1 from public.worker_profiles w join public.profiles p on p.id=w.id join public.professions pr on pr.id=w.profession_id join auth.users a on a.id=w.id
 where w.id=p_worker_id and w.published and p.status='active' and 'worker'=any(p.roles) and pr.active and a.phone_confirmed_at is not null and a.phone ~ '^\+?923[0-9]{9}$') then raise exception 'Worker profile unavailable'; end if;
 v_result:=khidmat_private.worker_json(p_worker_id);
 return v_result||jsonb_build_object('reviews',coalesce((select jsonb_agg(to_jsonb(r)) from (select rating,comment,created_at from public.reviews where worker_id=p_worker_id and not hidden order by created_at desc limit 20) r),'[]'::jsonb));
end $$;
create function khidmat_private.set_worker_availability(p_status text,p_latitude double precision default null,p_longitude double precision default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active();
begin
 perform khidmat_private.throttle('availability',120);
 if p_status not in ('available_now','available_later','busy','offline','unknown') then raise exception 'Choose an availability state'; end if;
 if not exists(select 1 from public.worker_profiles where id=v_uid) or not exists(select 1 from public.profiles where id=v_uid and 'worker'=any(roles)) then raise exception 'Create a worker profile first'; end if;
 perform khidmat_private.update_location(v_uid,p_latitude,p_longitude);
 if p_status='available_now' and not exists(select 1 from khidmat_private.worker_locations where worker_id=v_uid and updated_at>=now()-interval '15 minutes') then raise exception 'Refresh your location to appear available nearby, or choose available later'; end if;
 update public.worker_profiles set availability=p_status,availability_updated_at=now(),updated_at=now() where id=v_uid;
 return khidmat_private.worker_json(v_uid);
end $$;

create function khidmat_private.search_workers(p_query text default '',p_profession_id uuid default null,p_skill text default null,
 p_latitude double precision default null,p_longitude double precision default null,p_city text default null,p_radius_km double precision default 15,
 p_min_price numeric default null,p_max_price numeric default null,p_min_experience integer default 0,p_min_rating numeric default 0,
 p_available_only boolean default false,p_sort text default 'distance',p_limit integer default 20,p_offset integer default 0,p_neighbourhood text default null) returns setof jsonb
 language plpgsql security definer set search_path='' as $$
declare v_point extensions.geography;
begin
 perform khidmat_private.require_browse();
 if auth.uid() is not null then perform khidmat_private.throttle('search',120,15); end if;
 if (p_latitude is null)<>(p_longitude is null) or p_radius_km is null or not p_radius_km between 1 and 100
 or p_limit is null or p_limit not between 1 and 50 or p_offset is null or p_offset not between 0 and 10000
 or p_min_rating is null or not p_min_rating between 0 and 5 or p_min_experience is null or p_min_experience not between 0 and 60
 or length(coalesce(p_query,''))>100 or length(coalesce(p_neighbourhood,''))>100 or p_sort is null or p_sort not in ('distance','rating','price','experience','relevance') or p_available_only is null
 or (p_min_price is not null and not p_min_price between 0 and 1000000) or (p_max_price is not null and not p_max_price between 0 and 1000000)
 or (p_min_price is not null and p_max_price is not null and p_min_price>p_max_price) then raise exception 'Invalid search filters'; end if;
 if p_latitude is null then
  if length(trim(coalesce(p_city,''))) not between 2 and 80 then raise exception 'Choose a city or share device location'; end if;
 else
  if not p_latitude between 23 and 38 or not p_longitude between 60 and 78 then raise exception 'Choose a search location in Pakistan'; end if;
  v_point:=extensions.st_setsrid(extensions.st_makepoint(p_longitude,p_latitude),4326)::extensions.geography;
 end if;
 return query
 with candidates as (
 select w.*,p.full_name,pr.name profession_name, l.updated_at geo_updated,
 case when v_point is null then null else greatest(0.5,round((extensions.st_distance(l.location,v_point)/500)::numeric)*0.5)::double precision end distance,
 coalesce(r.rating,0) rating,coalesce(r.cnt,0) review_count,
 khidmat_private.effective_availability(w.availability,w.availability_updated_at,l.updated_at) effective,
 case when lower(pr.name)=lower(trim(coalesce(p_query,''))) then 3 when w.skills @> array[p_query] then 2 else 1 end relevance
 from public.worker_profiles w join public.profiles p on p.id=w.id join public.professions pr on pr.id=w.profession_id
 left join khidmat_private.worker_locations l on l.worker_id=w.id
 left join lateral(select round(avg(rating),2) rating,count(*) cnt from public.reviews where worker_id=w.id and not hidden) r on true
 where w.published and p.status='active' and 'worker'=any(p.roles) and pr.active
 and exists(select 1 from auth.users a where a.id=w.id and a.phone_confirmed_at is not null and a.phone ~ '^\+?923[0-9]{9}$')
 and (p_profession_id is null or w.profession_id=p_profession_id) and (p_skill is null or p_skill=any(w.skills))
 and (v_point is null and lower(p.city)=lower(trim(p_city)) or v_point is not null and l.updated_at>=now()-interval '15 minutes'
   and extensions.st_dwithin(l.location,v_point,p_radius_km*1000) and extensions.st_dwithin(l.location,v_point,w.service_radius_km*1000))
 and (v_point is not null or trim(coalesce(p_neighbourhood,''))='' or position(lower(trim(p_neighbourhood)) in lower(p.neighbourhood))>0)
 and (p_min_price is null or w.rate>=p_min_price) and (p_max_price is null or w.rate<=p_max_price)
 and w.experience_years>=p_min_experience and coalesce(r.rating,0)>=p_min_rating
 and (trim(coalesce(p_query,''))='' or position(lower(trim(p_query)) in lower(p.full_name||' '||p.city||' '||p.neighbourhood||' '||pr.name||' '||pr.name_ur||' '||pr.category||' '||array_to_string(w.skills,' ')||' '||w.description))>0)
 ) select khidmat_private.worker_json(c.id,c.distance) from candidates c
 where not p_available_only or c.effective='available_now'
 order by case when p_sort='relevance' then c.relevance end desc,
 case c.effective when 'available_now' then 0 when 'available_later' then 1 when 'busy' then 2 when 'unknown' then 3 else 4 end,
 case when p_sort='rating' then c.rating end desc,
 case when p_sort='price' then c.rate end asc,
 case when p_sort='experience' then c.experience_years end desc,
 case when p_sort in ('distance','relevance') then c.distance end asc nulls last,c.id
 limit p_limit offset p_offset;
end $$;
create function khidmat_private.get_worker_contact(p_worker_id uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active();
begin
 perform khidmat_private.throttle('contact',20);
 if not exists(select 1 from public.worker_profiles w join public.profiles p on p.id=w.id join auth.users a on a.id=w.id
 where w.id=p_worker_id and w.published and w.share_contact and p.status='active' and 'worker'=any(p.roles) and a.phone_confirmed_at is not null and a.phone ~ '^\+?923[0-9]{9}$') then raise exception 'This worker has not shared contact details. Send a job request.'; end if;
 return (select jsonb_build_object('phone',phone,'whatsapp',case when whatsapp='' then phone else whatsapp end) from public.profiles where id=p_worker_id);
end $$;

create function khidmat_private.notify(p_user_id uuid,p_job_id uuid,p_title text,p_body text) returns void language plpgsql set search_path='' as $$
declare v_id uuid;
begin
 insert into public.notifications(user_id,job_id,title,body) values(p_user_id,p_job_id,p_title,p_body) returning id into v_id;
 insert into khidmat_private.push_outbox(notification_id) values(v_id);
end $$;
create function khidmat_private.create_job(p_worker_id uuid,p_profession_id uuid,p_description text,p_scheduled_at timestamptz,p_city text,p_neighbourhood text default '',p_address text default '',p_offered_price numeric default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active(); v_worker public.profiles; v_customer public.profiles; v_job public.jobs; v_state text;
begin
 perform khidmat_private.throttle('create_job',15);
 select * into v_customer from public.profiles where id=v_uid;
 if not 'customer'=any(v_customer.roles) or length(v_customer.full_name)<2 then raise exception 'Complete your customer profile first'; end if;
 select * into v_worker from public.profiles where id=p_worker_id and status='active' and 'worker'=any(roles);
 if not found or v_uid=p_worker_id then raise exception 'Choose another eligible worker'; end if;
 if not exists(select 1 from auth.users where id=p_worker_id and phone_confirmed_at is not null and phone ~ '^\+?923[0-9]{9}$') then raise exception 'This worker account is unavailable'; end if;
 select khidmat_private.effective_availability(w.availability,w.availability_updated_at,l.updated_at) into v_state
 from public.worker_profiles w left join khidmat_private.worker_locations l on l.worker_id=w.id join public.professions pr on pr.id=w.profession_id
 where w.id=p_worker_id and w.published and w.profession_id=p_profession_id and pr.active;
 if not found or v_state not in ('available_now','available_later') then raise exception 'This worker is not currently accepting requests'; end if;
 if p_scheduled_at is null or p_scheduled_at<=now() or p_scheduled_at>now()+interval '1 year' then raise exception 'Choose a future date within one year'; end if;
 if length(trim(coalesce(p_description,''))) not between 10 and 2000 or length(trim(coalesce(p_city,''))) not between 2 and 80
 or length(coalesce(p_neighbourhood,''))>100 or length(coalesce(p_address,''))>300 then raise exception 'Enter valid job details and city'; end if;
 insert into public.jobs(customer_id,worker_id,profession_id,customer_name,worker_name,description,scheduled_at,city,neighbourhood,address,offered_price)
 values(v_uid,p_worker_id,p_profession_id,v_customer.full_name,v_worker.full_name,trim(p_description),p_scheduled_at,trim(p_city),trim(coalesce(p_neighbourhood,'')),trim(coalesce(p_address,'')),p_offered_price) returning * into v_job;
 perform khidmat_private.notify(p_worker_id,v_job.id,'New job request',v_customer.full_name||' requested your service.');
 return to_jsonb(v_job);
end $$;
create function khidmat_private.transition_job(p_job_id uuid,p_status text) returns jsonb language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active(); j public.jobs; v_allowed boolean:=false; v_other uuid;
begin
 perform khidmat_private.throttle('job_status',60);
 select * into j from public.jobs where id=p_job_id for update;
 if not found or v_uid not in (j.customer_id,j.worker_id) then raise exception 'Job not available' using errcode='42501'; end if;
 if exists(select 1 from public.profiles where id in (j.customer_id,j.worker_id) and status<>'active') then raise exception 'A participant account is unavailable'; end if;
 if j.status=p_status then return to_jsonb(j); end if;
 -- Serialize acceptances for this worker, including requests in different rows.
 if p_status='accepted' then perform 1 from public.worker_profiles where id=j.worker_id for update; end if;
 v_allowed:=case j.status
 when 'pending' then p_status='cancelled' and v_uid=j.customer_id or p_status in ('accepted','declined') and v_uid=j.worker_id
 when 'accepted' then p_status='cancelled' or p_status='in_progress' and v_uid=j.worker_id
 when 'in_progress' then p_status='cancelled' or p_status='completion_requested' and v_uid=j.worker_id
 when 'completion_requested' then p_status='in_progress' or p_status='completed' and v_uid=j.customer_id
 else false end;
 if not coalesce(v_allowed,false) then raise exception 'This job status change is not allowed' using errcode='42501'; end if;
 if p_status='accepted' and exists(select 1 from public.jobs x where x.worker_id=j.worker_id and x.id<>j.id and x.scheduled_at=j.scheduled_at and x.status in ('accepted','in_progress','completion_requested')) then raise exception 'You already accepted a job at that time'; end if;
 update public.jobs set status=p_status,updated_at=now() where id=j.id returning * into j;
 v_other:=case when v_uid=j.customer_id then j.worker_id else j.customer_id end;
 perform khidmat_private.notify(v_other,j.id,'Job updated','Job status: '||replace(p_status,'_',' '));
 return to_jsonb(j);
end $$;
create function khidmat_private.review_job(p_job_id uuid,p_rating integer,p_comment text default '') returns jsonb language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active(); j public.jobs;
begin
 perform khidmat_private.throttle('review',20);
 select * into j from public.jobs where id=p_job_id for update;
 if not found or j.customer_id<>v_uid or j.status<>'completed' or j.reviewed then raise exception 'Review your completed job once' using errcode='42501'; end if;
 insert into public.reviews(job_id,customer_id,worker_id,rating,comment) values(j.id,v_uid,j.worker_id,p_rating,trim(coalesce(p_comment,'')));
 update public.jobs set reviewed=true,updated_at=now() where id=j.id returning * into j;
 perform khidmat_private.notify(j.worker_id,j.id,'New review','A customer reviewed a completed job.');
 return to_jsonb(j);
end $$;
create function khidmat_private.read_notification(p_notification_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active();
begin update public.notifications set read_at=coalesce(read_at,now()) where id=p_notification_id and user_id=v_uid; if not found then raise exception 'Notification not available' using errcode='42501'; end if; end $$;
create function khidmat_private.report_account(p_reported_user_id uuid,p_reason text,p_details text default '') returns uuid language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active(); v_id uuid;
begin
 perform khidmat_private.throttle('report',5,1440);
 if not exists(select 1 from public.profiles where id=p_reported_user_id) then raise exception 'Account unavailable'; end if;
 insert into public.account_reports(reporter_id,reported_user_id,reason,details) values(v_uid,p_reported_user_id,p_reason,trim(coalesce(p_details,''))) returning id into v_id;
 return v_id;
end $$;
create function khidmat_private.admin_check() returns boolean language plpgsql stable security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active(); begin return exists(select 1 from khidmat_private.account_admins where user_id=v_uid); end $$;
create function khidmat_private.moderate_account(p_user_id uuid,p_action text,p_reason text) returns void language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active();
begin
 if not khidmat_private.admin_check() then raise exception 'Administrator access required' using errcode='42501'; end if;
 if p_user_id=v_uid or length(trim(coalesce(p_reason,''))) not between 10 and 1000 then raise exception 'Choose another account and record a reason'; end if;
 if p_action in ('suspend','reactivate') then update public.profiles set status=case when p_action='suspend' then 'suspended' else 'active' end,updated_at=now() where id=p_user_id;
 elsif p_action in ('verify_worker','revoke_verification') then update public.worker_profiles set verified=p_action='verify_worker',updated_at=now() where id=p_user_id;
 else raise exception 'Invalid moderation action'; end if;
 if not found then raise exception 'Account not found'; end if;
 insert into khidmat_private.moderation_log(admin_id,user_id,action,reason) values(v_uid,p_user_id,p_action,trim(p_reason));
 update public.account_reports set status='reviewed' where reported_user_id=p_user_id and status='open';
end $$;
create function khidmat_private.register_push_token(p_token text,p_platform text) returns void language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active(); begin
 perform khidmat_private.throttle('push_token',30);
 if (select count(*) from khidmat_private.push_tokens where user_id=v_uid)>=5 and not exists(select 1 from khidmat_private.push_tokens where token=p_token and user_id=v_uid) then raise exception 'Too many registered devices'; end if;
 insert into khidmat_private.push_tokens(token,user_id,platform) values(p_token,v_uid,p_platform)
 on conflict(token) do update set user_id=excluded.user_id,platform=excluded.platform,updated_at=now();
end $$;
create function khidmat_private.unregister_push_token(p_token text) returns void language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active(); begin delete from khidmat_private.push_tokens where token=p_token and user_id=v_uid; end $$;

-- Private definer implementations are not exposed to the Data API. Thin public
-- invoker wrappers preserve parameter names/defaults and explicit execute grants.
do $$ declare r record; args text; begin
 for r in select p.oid,p.proname,pg_get_function_arguments(p.oid) signature,pg_get_function_result(p.oid) result,p.proargnames
 from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='khidmat_private' and p.proname=any(array[
 'save_profile','save_worker_profile','worker_own_profile','worker_profile','set_worker_availability','search_workers','get_worker_contact',
 'create_job','transition_job','review_job','read_notification','report_account','admin_check','moderate_account','register_push_token','unregister_push_token']) loop
  select string_agg(quote_ident(x),',') into args from unnest(r.proargnames) x;
  execute format('create function public.%I(%s) returns %s language sql security invoker set search_path='''' as %L',r.proname,r.signature,r.result,'select * from khidmat_private.'||quote_ident(r.proname)||'('||coalesce(args,'')||');');
  execute format('revoke all on function public.%I(%s) from public,anon,authenticated',r.proname,pg_get_function_identity_arguments(r.oid));
  execute format('grant execute on function public.%I(%s) to authenticated',r.proname,pg_get_function_identity_arguments(r.oid));
 end loop;
end $$;
revoke all on all functions in schema khidmat_private from public,anon,authenticated;
grant execute on function khidmat_private.is_active() to authenticated;
do $$ declare r record; begin
 for r in select p.oid,p.proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='khidmat_private' and p.proname=any(array[
 'save_profile','save_worker_profile','worker_own_profile','worker_profile','set_worker_availability','search_workers','get_worker_contact',
 'create_job','transition_job','review_job','read_notification','report_account','admin_check','moderate_account','register_push_token','unregister_push_token']) loop
 execute format('grant execute on function khidmat_private.%I(%s) to authenticated',r.proname,pg_get_function_identity_arguments(r.oid));
 end loop;
end $$;
-- Discovery is readable before sign-in. Only safe JSON RPCs receive anon access;
-- all raw worker/account relations and contact/job mutations remain restricted.
grant usage on schema khidmat_private to anon;
grant execute on function public.worker_profile(uuid),khidmat_private.worker_profile(uuid) to anon;
do $$ declare r record; begin
 for r in select p.oid,p.proname from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname in ('public','khidmat_private') and p.proname='search_workers' loop
  execute format('grant execute on function %s to anon',r.oid::regprocedure);
 end loop;
end $$;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types) values('worker-media','worker-media',true,5242880,array['image/jpeg','image/png','image/webp']);
create policy khidmat_media_upload on storage.objects for insert to authenticated with check(bucket_id='worker-media' and (storage.foldername(name))[1]=auth.uid()::text and khidmat_private.is_active()
 and exists(select 1 from public.profiles p where p.id=auth.uid() and 'worker'=any(p.roles)));
create policy khidmat_media_update on storage.objects for update to authenticated using(bucket_id='worker-media' and (storage.foldername(name))[1]=auth.uid()::text and khidmat_private.is_active()
 and exists(select 1 from public.profiles p where p.id=auth.uid() and 'worker'=any(p.roles)))
 with check(bucket_id='worker-media' and (storage.foldername(name))[1]=auth.uid()::text and khidmat_private.is_active()
 and exists(select 1 from public.profiles p where p.id=auth.uid() and 'worker'=any(p.roles)));
create policy khidmat_media_delete on storage.objects for delete to authenticated using(bucket_id='worker-media' and (storage.foldername(name))[1]=auth.uid()::text and khidmat_private.is_active());
create policy khidmat_media_owner_read on storage.objects for select to authenticated using(bucket_id='worker-media' and (storage.foldername(name))[1]=auth.uid()::text);

-- Realtime still evaluates the SELECT RLS policies per subscribing user.
do $$ begin
 if exists(select 1 from pg_publication where pubname='supabase_realtime') then
  alter publication supabase_realtime add table public.jobs,public.notifications,public.profiles;
 end if;
end $$;
commit;
