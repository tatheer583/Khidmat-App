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
