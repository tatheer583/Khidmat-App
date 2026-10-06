begin;

-- Public operational status only; never exposes users, bookings, or keys.
create function public.app_health() returns jsonb
language sql stable security definer set search_path = public, pg_catalog as $$
  select jsonb_build_object(
    'schema_version', 3,
    'ready',
      (select count(*) = 2 from storage.buckets
       where id in ('avatars','booking-media') and not public)
      and (select count(*) = 4 from pg_publication_tables
       where pubname = 'supabase_realtime' and schemaname = 'public'
         and tablename in ('providers','bookings','booking_events','messages'))
  );
$$;
revoke all on function public.app_health() from public;
grant execute on function public.app_health() to anon, authenticated;

-- Returns only available times, never another customer's booking information.
create function public.available_slots(p_provider_id uuid, p_date date)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare p public.providers; slots jsonb;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if p_date is null or p_date < (now() at time zone 'Asia/Karachi')::date
    or p_date > (now() at time zone 'Asia/Karachi')::date + 90 then
    raise exception 'Choose a date within the next 90 days';
  end if;
  select * into p from public.providers
    where id=p_provider_id and is_approved and is_available;
  if not found then raise exception 'Provider is unavailable'; end if;
  select coalesce(jsonb_agg(s order by s), '[]'::jsonb) into slots
  from (select distinct unnest(p.available_slots) as s) times
  where (p_date + case when s ~ '^([01][0-9]|2[0-3]):[0-5][0-9]$'
                       then s::time else null end) > (now() at time zone 'Asia/Karachi')
    and not exists (
      select 1 from public.bookings b where b.provider_id=p.id and b.booking_date=p_date
        and b.time_slot=s and b.status in ('pending','accepted','on_the_way','in_progress')
    );
  return slots;
end;
$$;
revoke all on function public.available_slots(uuid,date) from public, anon;
grant execute on function public.available_slots(uuid,date) to authenticated;

create function public.valid_daily_slots(slots text[]) returns boolean
language sql immutable set search_path = public as $$
  select cardinality(slots) <= 24
    and not exists (select 1 from unnest(slots) s
      where s is null or s !~ '^([01][0-9]|2[0-3]):[0-5][0-9]$')
    and cardinality(slots) = (select count(distinct s) from unnest(slots) s);
$$;
revoke all on function public.valid_daily_slots(text[]) from public, anon;
grant execute on function public.valid_daily_slots(text[]) to authenticated;
alter table public.providers add constraint providers_valid_daily_slots
  check (public.valid_daily_slots(available_slots)) not valid;

create function public.sync_provider_avatar() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  update public.providers set avatar_path=new.avatar_path where user_id=new.id;
  return new;
end;
$$;
revoke all on function public.sync_provider_avatar() from public, anon, authenticated;
create trigger profile_avatar_updated after update of avatar_path on public.profiles
  for each row when (old.avatar_path is distinct from new.avatar_path)
  execute function public.sync_provider_avatar();

notify pgrst, 'reload schema';
commit;
