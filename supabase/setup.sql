-- Khidmat live backend. Apply once using Supabase SQL Editor or supabase db push.
begin;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '' check (char_length(full_name) <= 100),
  city text not null default '' check (char_length(city) <= 80),
  location text not null default '' check (char_length(location) <= 300),
  avatar_path text,
  created_at timestamptz not null default now()
);

create function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, full_name)
    values (new.id, left(coalesce(new.raw_user_meta_data->>'full_name', ''), 100));
  return new;
end;
$$;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();
-- Include accounts created before this migration.
insert into public.profiles(id, full_name)
  select id, left(coalesce(raw_user_meta_data->>'full_name', ''), 100)
  from auth.users on conflict (id) do nothing;

create table public.providers (
  id uuid primary key default gen_random_uuid(),
  user_id uuid unique not null references public.profiles(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 100),
  category text not null check (category in ('AC Technician','Plumber','Electrician',
    'Tutor','Beautician','Carpenter','Painter','Deep Cleaning')),
  city text not null check (char_length(city) between 2 and 80),
  location text not null check (char_length(location) between 2 and 300),
  phone text not null default '' check (char_length(phone) <= 30),
  price_min integer not null check (price_min > 0 and price_min <= 1000000),
  price_max integer not null check (price_max >= price_min and price_max <= 1000000),
  available_slots text[] not null default array['09:00','12:00','15:00','18:00']::text[]
    check (cardinality(available_slots) between 0 and 24),
  is_available boolean not null default true,
  is_approved boolean not null default false,
  avatar_path text,
  rating numeric(3,2) not null default 0,
  review_count integer not null default 0,
  completion_rate numeric(5,4) not null default 0,
  completed_jobs integer not null default 0,
  created_at timestamptz not null default now()
);
create index providers_search_idx on public.providers(category, city)
  where is_approved and is_available;

create table public.quotes (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.profiles(id),
  provider_id uuid not null references public.providers(id),
  service text not null,
  original_price integer not null,
  final_price integer not null,
  expires_at timestamptz not null default (now() + interval '10 minutes'),
  created_at timestamptz not null default now()
);
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  quote_id uuid unique not null references public.quotes(id),
  customer_id uuid not null references public.profiles(id),
  provider_id uuid not null references public.providers(id),
  provider_user_id uuid not null references public.profiles(id),
  provider_snapshot jsonb not null,
  service text not null,
  location text not null check (char_length(location) between 5 and 500),
  notes text not null default '' check (char_length(notes) <= 2000),
  booking_date date not null,
  time_slot text not null,
  original_price integer not null,
  final_price integer not null,
  status text not null default 'pending' check (status in
    ('pending','accepted','on_the_way','in_progress','completed','cancelled','declined')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (customer_id <> provider_user_id)
);
create index bookings_customer_idx on public.bookings(customer_id, created_at desc);
create index bookings_provider_idx on public.bookings(provider_user_id, created_at desc);
create unique index bookings_reserved_slot_idx
  on public.bookings(provider_id, booking_date, time_slot)
  where status in ('pending','accepted','on_the_way','in_progress');

create table public.booking_events (
  id bigint generated always as identity primary key,
  booking_id uuid not null references public.bookings(id) on delete cascade,
  actor_id uuid references public.profiles(id),
  status text not null,
  created_at timestamptz not null default now()
);
create index booking_events_booking_idx on public.booking_events(booking_id, id);
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  sender_id uuid not null references public.profiles(id),
  body text not null default '' check (char_length(body) <= 4000),
  attachment_path text,
  created_at timestamptz not null default now(),
  check (char_length(trim(body)) > 0 or attachment_path is not null)
);
create index messages_booking_idx on public.messages(booking_id, created_at);
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid unique not null references public.bookings(id),
  customer_id uuid not null references public.profiles(id),
  provider_id uuid not null references public.providers(id),
  stars integer not null check (stars between 1 and 5),
  comment text not null default '' check (char_length(comment) <= 1000),
  created_at timestamptz not null default now()
);

create function public.is_booking_participant(booking_id_text text) returns boolean
language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.bookings b
    where b.id::text = booking_id_text
      and (b.customer_id = auth.uid() or b.provider_user_id = auth.uid())
  );
$$;
create function public.refresh_provider_metrics(target_provider uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  update public.providers p set
    rating = coalesce((select avg(stars) from public.reviews r where r.provider_id = p.id),0),
    review_count = (select count(*) from public.reviews r where r.provider_id = p.id),
    completed_jobs = (select count(*) from public.bookings b
      where b.provider_id = p.id and b.status = 'completed'),
    completion_rate = coalesce((select
      count(*) filter (where b.status = 'completed')::numeric /
      nullif(count(*) filter (where b.status in ('completed','declined')),0)
      from public.bookings b where b.provider_id = p.id),0)
  where p.id = target_provider;
end;
$$;
create function public.record_booking_event() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' or new.status is distinct from old.status then
    insert into public.booking_events(booking_id, actor_id, status)
      values (new.id, auth.uid(), new.status);
    perform public.refresh_provider_metrics(new.provider_id);
  end if;
  return new;
end;
$$;
create trigger booking_event after insert or update on public.bookings
  for each row execute function public.record_booking_event();
create function public.review_metrics() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  perform public.refresh_provider_metrics(new.provider_id);
  return new;
end;
$$;
create trigger review_metrics after insert on public.reviews
  for each row execute function public.review_metrics();

-- Prices originate from the provider's authorized rates, never the client.
create function public.quote_provider(p_provider_id uuid) returns jsonb
language plpgsql security definer set search_path = public as $$
declare p public.providers; q public.quotes;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  select * into p from public.providers where id = p_provider_id
    and is_approved and is_available;
  if not found then raise exception 'Provider is unavailable'; end if;
  if p.user_id = auth.uid() then raise exception 'You cannot book yourself'; end if;
  if cardinality(p.available_slots) = 0 then raise exception 'No available slots'; end if;
  insert into public.quotes(customer_id,provider_id,service,original_price,final_price)
    values (auth.uid(),p.id,p.category,p.price_max,p.price_min) returning * into q;
  return to_jsonb(q);
end;
$$;

create function public.create_booking(p_quote_id uuid, p_date date,
  p_slot text, p_location text, p_notes text default '') returns jsonb
language plpgsql security definer set search_path = public as $$
declare q public.quotes; p public.providers; b public.bookings;
  local_today date := (now() at time zone 'Asia/Karachi')::date;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  select * into q from public.quotes where id = p_quote_id
    and customer_id = auth.uid() for update;
  if not found then raise exception 'Quote not found'; end if;
  -- Replaying a successful request returns its original booking.
  select * into b from public.bookings where quote_id = q.id;
  if found then return to_jsonb(b); end if;
  if q.expires_at <= now() then raise exception 'Quote expired; request a new price'; end if;
  select * into p from public.providers where id = q.provider_id
    and is_approved and is_available for update;
  if not found then raise exception 'Provider is unavailable'; end if;
  if p_date is null or p_date < local_today or p_date > local_today + 90 then
    raise exception 'Choose a date within the next 90 days';
  end if;
  if p_slot is null or not (p_slot = any(p.available_slots))
    or p_slot !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$' then
    raise exception 'Choose an available time slot';
  end if;
  if (p_date + p_slot::time) <= (now() at time zone 'Asia/Karachi') then
    raise exception 'That appointment time has already passed';
  end if;
  if p_location is null or char_length(trim(p_location)) < 5
    or char_length(p_location) > 500 then raise exception 'Enter a full service address'; end if;
  insert into public.bookings(quote_id,customer_id,provider_id,provider_user_id,
    provider_snapshot,service,location,notes,booking_date,time_slot,original_price,final_price)
    values(q.id,auth.uid(),p.id,p.user_id,to_jsonb(p),q.service,trim(p_location),
      coalesce(p_notes,''),p_date,p_slot,q.original_price,q.final_price) returning * into b;
  return to_jsonb(b);
exception when unique_violation then
  raise exception 'This time slot was just booked; choose another slot';
end;
$$;

create function public.transition_booking(p_booking_id uuid, p_status text) returns jsonb
language plpgsql security definer set search_path = public as $$
declare b public.bookings; permitted boolean := false;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  select * into b from public.bookings where id = p_booking_id
    and (customer_id = auth.uid() or provider_user_id = auth.uid());
  if not found then raise exception 'Booking not found'; end if;
  -- Lock providers before bookings consistently with create_booking.
  perform 1 from public.providers where id = b.provider_id for update;
  select * into b from public.bookings where id = p_booking_id for update;
  if b.provider_user_id = auth.uid() then
    permitted := (b.status = 'pending' and p_status in ('accepted','declined'))
      or (b.status = 'accepted' and p_status in ('on_the_way','in_progress'))
      or (b.status = 'on_the_way' and p_status = 'in_progress')
      or (b.status = 'in_progress' and p_status = 'completed');
  elsif b.customer_id = auth.uid() then
    permitted := b.status in ('pending','accepted','on_the_way') and p_status = 'cancelled';
  end if;
  if not coalesce(permitted,false) then raise exception 'This status change is not allowed'; end if;
  update public.bookings set status = p_status, updated_at = now()
    where id = b.id returning * into b;
  return to_jsonb(b);
end;
$$;

alter table public.profiles enable row level security;
alter table public.providers enable row level security;
alter table public.quotes enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_events enable row level security;
alter table public.messages enable row level security;
alter table public.reviews enable row level security;

create policy profiles_read on public.profiles for select to authenticated using (id = auth.uid());
create policy profiles_update on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy providers_read on public.providers for select to authenticated
  using (is_approved or user_id = auth.uid());
create policy providers_insert on public.providers for insert to authenticated
  with check (user_id = auth.uid());
create policy providers_update on public.providers for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy quotes_read on public.quotes for select to authenticated using (customer_id = auth.uid());
create policy bookings_read on public.bookings for select to authenticated
  using (customer_id = auth.uid() or provider_user_id = auth.uid());
create policy events_read on public.booking_events for select to authenticated
  using (public.is_booking_participant(booking_id::text));
create policy messages_read on public.messages for select to authenticated
  using (public.is_booking_participant(booking_id::text));
create policy messages_insert on public.messages for insert to authenticated with check (
  sender_id = auth.uid() and public.is_booking_participant(booking_id::text)
  and (attachment_path is null or (
    (storage.foldername(attachment_path))[1] = booking_id::text
    and (storage.foldername(attachment_path))[2] = auth.uid()::text
    and exists (select 1 from storage.objects o
      where o.bucket_id = 'booking-media' and o.name = attachment_path))));
create policy reviews_read on public.reviews for select to authenticated using (true);
create policy reviews_insert on public.reviews for insert to authenticated with check (
  customer_id = auth.uid() and exists(select 1 from public.bookings b
    where b.id = booking_id and b.customer_id = auth.uid()
      and b.provider_id = reviews.provider_id and b.status = 'completed'));

-- Deny direct mutation of prices, bookings, approval flags, and computed reputation.
revoke all on public.profiles,public.providers,public.quotes,public.bookings,
  public.booking_events,public.messages,public.reviews from anon,authenticated;
grant select on public.profiles,public.providers,public.quotes,public.bookings,
  public.booking_events,public.messages,public.reviews to authenticated;
grant update(full_name,city,location,avatar_path) on public.profiles to authenticated;
grant insert(user_id,name,category,city,location,phone,price_min,price_max,
  available_slots,is_available,avatar_path) on public.providers to authenticated;
grant update(user_id,name,category,city,location,phone,price_min,price_max,
  available_slots,is_available,avatar_path) on public.providers to authenticated;
grant insert(booking_id,sender_id,body,attachment_path) on public.messages to authenticated;
grant insert(booking_id,customer_id,provider_id,stars,comment) on public.reviews to authenticated;
revoke all on function public.handle_new_user(), public.refresh_provider_metrics(uuid),
  public.record_booking_event(), public.review_metrics(),
  public.is_booking_participant(text),public.quote_provider(uuid),
  public.create_booking(uuid,date,text,text,text),public.transition_booking(uuid,text)
  from public,anon,authenticated;
grant execute on function public.is_booking_participant(text),public.quote_provider(uuid),
  public.create_booking(uuid,date,text,text,text),public.transition_booking(uuid,text) to authenticated;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
  values ('avatars','avatars',false,5242880,array['image/jpeg','image/png','image/webp']),
    ('booking-media','booking-media',false,5242880,array['image/jpeg','image/png','image/webp']);
create policy avatar_upload on storage.objects for insert to authenticated with check (
  bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy avatar_read on storage.objects for select to authenticated using (
  bucket_id = 'avatars' and ((storage.foldername(name))[1] = auth.uid()::text
    or exists (select 1 from public.providers p where p.is_approved
      and p.user_id::text = (storage.foldername(name))[1] and p.avatar_path = name)));
create policy avatar_delete on storage.objects for delete to authenticated using (
  bucket_id = 'avatars' and (storage.foldername(name))[1] = auth.uid()::text);
create policy booking_media_upload on storage.objects for insert to authenticated with check (
  bucket_id = 'booking-media' and (storage.foldername(name))[2] = auth.uid()::text
  and public.is_booking_participant((storage.foldername(name))[1]));
create policy booking_media_read on storage.objects for select to authenticated using (
  bucket_id = 'booking-media' and public.is_booking_participant((storage.foldername(name))[1]));
create policy booking_media_delete on storage.objects for delete to authenticated using (
  bucket_id = 'booking-media' and (storage.foldername(name))[2] = auth.uid()::text
  and public.is_booking_participant((storage.foldername(name))[1]));

do $$
declare table_name text;
begin
  foreach table_name in array array['providers','bookings','booking_events','messages'] loop
    if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime'
      and schemaname = 'public' and tablename = table_name) then
      execute format('alter publication supabase_realtime add table public.%I', table_name);
    end if;
  end loop;
end;
$$;
commit;


begin;
alter table public.profiles
  add column if not exists account_role text not null default 'customer'
    check (account_role in ('customer','worker')),
  add column if not exists profession text not null default '' check (char_length(profession) <= 100),
  add column if not exists experience_years integer not null default 0 check (experience_years between 0 and 60),
  add column if not exists bio text not null default '' check (char_length(bio) <= 2000),
  add column if not exists onboarding_completed boolean not null default false;
alter table public.providers
  add column if not exists description text not null default '' check (char_length(description) <= 2000),
  add column if not exists experience_years integer not null default 0 check (experience_years between 0 and 60);
grant insert(description,experience_years), update(description,experience_years)
  on public.providers to authenticated;
-- Role selection is a dashboard preference; booking participant permissions
-- remain enforced by the original RLS and server transition functions.
create function public.complete_profile(p_full_name text, p_role text, p_city text,
  p_location text, p_profession text, p_experience_years integer, p_bio text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare saved public.profiles;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if p_role not in ('customer','worker') or p_role is null then raise exception 'Choose your role'; end if;
  if p_full_name is null or char_length(trim(p_full_name)) not between 2 and 100
    then raise exception 'Enter your name'; end if;
  if p_city is null or char_length(trim(p_city)) not between 2 and 80
    then raise exception 'Enter your city'; end if;
  if char_length(coalesce(p_location,'')) > 300 then raise exception 'Address is too long'; end if;
  if char_length(coalesce(p_profession,'')) > 100 then raise exception 'Profession is too long'; end if;
  if p_experience_years is null or p_experience_years not between 0 and 60
    then raise exception 'Enter experience from 0 to 60 years'; end if;
  if p_bio is null or char_length(p_bio) > 2000 then raise exception 'Description is too long'; end if;
  if p_role = 'worker' and (char_length(trim(coalesce(p_profession,''))) < 2
    or char_length(trim(p_bio)) < 10) then raise exception 'Complete your worker details'; end if;
  update public.profiles set full_name=trim(p_full_name), account_role=p_role,
    city=trim(p_city), location=trim(coalesce(p_location,'')), profession=trim(coalesce(p_profession,'')),
    experience_years=p_experience_years, bio=trim(p_bio), onboarding_completed=true
    where id=auth.uid() returning * into saved;
  if not found then raise exception 'Profile not found'; end if;
  update public.providers set description=saved.bio, experience_years=saved.experience_years
    where user_id=auth.uid();
  return to_jsonb(saved);
end;
$$;
revoke all on function public.complete_profile(text,text,text,text,text,integer,text) from public,anon,authenticated;
grant execute on function public.complete_profile(text,text,text,text,text,integer,text) to authenticated;
commit;
