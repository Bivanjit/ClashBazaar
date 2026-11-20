-- Tighten policy composition and add indexes for foreign-key lookups.
drop policy if exists "owners manage layouts" on public.base_layouts;
create policy "owners insert layouts" on public.base_layouts for insert to authenticated
with check (owner_id = (select auth.uid()));
create policy "owners update layouts" on public.base_layouts for update to authenticated
using (owner_id = (select auth.uid()) or (select app_private.is_staff()))
with check (owner_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "owners delete layouts" on public.base_layouts for delete to authenticated
using (owner_id = (select auth.uid()) or (select app_private.is_staff()));

drop policy if exists "owners create recruitment" on public.clan_recruitment;
drop policy if exists "owners manage recruitment" on public.clan_recruitment;
create policy "owners insert recruitment" on public.clan_recruitment for insert to authenticated
with check (owner_id = (select auth.uid()));
create policy "owners update recruitment" on public.clan_recruitment for update to authenticated
using (owner_id = (select auth.uid()) or (select app_private.is_staff()))
with check (owner_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "owners delete recruitment" on public.clan_recruitment for delete to authenticated
using (owner_id = (select auth.uid()) or (select app_private.is_staff()));

drop policy if exists "owners manage coach profile" on public.coaches;
create policy "owners insert coach profile" on public.coaches for insert to authenticated
with check (owner_id = (select auth.uid()));
create policy "owners update coach profile" on public.coaches for update to authenticated
using (owner_id = (select auth.uid()) or (select app_private.is_staff()))
with check (owner_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "owners delete coach profile" on public.coaches for delete to authenticated
using (owner_id = (select auth.uid()) or (select app_private.is_staff()));

drop policy if exists "owners manage coaching services" on public.coaching_services;
create policy "owners insert coaching services" on public.coaching_services for insert to authenticated
with check (owner_id = (select auth.uid()));
create policy "owners update coaching services" on public.coaching_services for update to authenticated
using (owner_id = (select auth.uid()) or (select app_private.is_staff()))
with check (owner_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "owners delete coaching services" on public.coaching_services for delete to authenticated
using (owner_id = (select auth.uid()) or (select app_private.is_staff()));

drop policy if exists "users view own favourites" on public.favourites;
drop policy if exists "users manage own favourites" on public.favourites;
create policy "users read own favourites" on public.favourites for select to authenticated
using (user_id = (select auth.uid()));
create policy "users insert own favourites" on public.favourites for insert to authenticated
with check (user_id = (select auth.uid()));
create policy "users delete own favourites" on public.favourites for delete to authenticated
using (user_id = (select auth.uid()));

create index if not exists base_layouts_owner_idx on public.base_layouts(owner_id);
create index if not exists clan_recruitment_clan_idx on public.clan_recruitment(clan_id);
create index if not exists clan_recruitment_owner_idx on public.clan_recruitment(owner_id);
create index if not exists clans_owner_idx on public.clans(owner_id);
create index if not exists coaching_bookings_coach_idx on public.coaching_bookings(coach_owner_id);
create index if not exists coaching_bookings_service_idx on public.coaching_bookings(service_id);
create index if not exists coaching_services_coach_idx on public.coaching_services(coach_id);
create index if not exists coaching_services_owner_idx on public.coaching_services(owner_id);
create index if not exists moderation_logs_actor_idx on public.moderation_logs(actor_id);
create index if not exists notifications_user_idx on public.notifications(user_id);
create index if not exists reports_reporter_idx on public.reports(reporter_id);
