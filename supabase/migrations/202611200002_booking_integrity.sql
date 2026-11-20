-- Harden coaching booking ownership and status transitions.
drop policy if exists "booking parties update" on public.coaching_bookings;
create policy "coaches update their booking requests"
on public.coaching_bookings for update to authenticated
using (coach_owner_id = (select auth.uid()) or (select app_private.is_staff()))
with check (coach_owner_id = (select auth.uid()) or (select app_private.is_staff()));

create or replace function app_private.enforce_booking_integrity()
returns trigger language plpgsql set search_path = ''
as $$
declare actual_owner uuid;
begin
  if tg_op = 'INSERT' then
    select owner_id into actual_owner
    from public.coaching_services
    where id = new.service_id and status = 'published';
    if actual_owner is null then raise exception 'Coaching service is not available'; end if;
    if actual_owner = (select auth.uid()) then raise exception 'You cannot book your own coaching service'; end if;
    new.learner_id := (select auth.uid());
    new.coach_owner_id := actual_owner;
    new.status := 'requested';
    return new;
  end if;
  if new.service_id is distinct from old.service_id
     or new.learner_id is distinct from old.learner_id
     or new.coach_owner_id is distinct from old.coach_owner_id then
    raise exception 'Booking parties and service cannot be changed';
  end if;
  if not (select app_private.is_staff()) and old.coach_owner_id <> (select auth.uid()) then
    raise exception 'Only the coach can update booking status';
  end if;
  return new;
end;
$$;
revoke all on function app_private.enforce_booking_integrity() from public, anon, authenticated;
drop trigger if exists enforce_booking_integrity on public.coaching_bookings;
create trigger enforce_booking_integrity
before insert or update on public.coaching_bookings
for each row execute function app_private.enforce_booking_integrity();
