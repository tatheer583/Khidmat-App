-- Contact details are a customer action. A worker may still act as a customer
-- by enabling both roles, but worker-only accounts cannot query other workers.
begin;
create or replace function khidmat_private.get_worker_contact(p_worker_id uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=khidmat_private.require_active();
begin
 perform khidmat_private.throttle('contact',20);
 if not exists(select 1 from public.profiles where id=v_uid and 'customer'=any(roles)) then
  raise exception 'Customer access required' using errcode='42501';
 end if;
 if not exists(select 1 from public.worker_profiles w join public.profiles p on p.id=w.id join auth.users a on a.id=w.id
 where w.id=p_worker_id and w.published and w.share_contact and p.status='active' and 'worker'=any(p.roles)
 and a.phone_confirmed_at is not null and a.phone ~ '^\+?923[0-9]{9}$') then
  raise exception 'This worker has not shared contact details. Send a job request.';
 end if;
 return (select jsonb_build_object('phone',phone,'whatsapp',case when whatsapp='' then phone else whatsapp end)
 from public.profiles where id=p_worker_id);
end $$;
commit;
