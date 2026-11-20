-- CoC Marketplace initial schema
-- Apply only to the dedicated CoC Marketplace Supabase project.
create extension if not exists pgcrypto;

create schema if not exists app_private;
revoke all on schema app_private from public, anon, authenticated;

create type public.listing_status as enum ('draft','pending_review','published','rejected','archived','sold');
create type public.price_type as enum ('fixed','negotiable');
create type public.market_currency as enum ('INR','USD');
create type public.progression_type as enum ('maxed','almost_maxed','balanced','rushed');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  username text unique,
  display_name text not null default 'New player',
  avatar_url text,
  country text,
  languages text[] not null default '{}',
  bio text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table app_private.user_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('user','moderator','admin')),
  created_at timestamptz not null default now()
);

create or replace function app_private.is_staff()
returns boolean language sql stable security definer
set search_path = ''
as $$
  select exists (
    select 1 from app_private.user_roles
    where user_id = (select auth.uid()) and role in ('moderator','admin')
  );
$$;
revoke all on function app_private.is_staff() from public;
grant execute on function app_private.is_staff() to authenticated;

create table public.game_catalogue (
  id uuid primary key default gen_random_uuid(),
  catalogue_key text not null,
  version integer not null check (version > 0),
  entity_type text not null,
  entity_key text not null,
  display_name text not null,
  max_level integer,
  metadata jsonb not null default '{}',
  effective_from date not null default current_date,
  effective_to date,
  created_at timestamptz not null default now(),
  unique(catalogue_key, version, entity_type, entity_key),
  check (effective_to is null or effective_to >= effective_from)
);

create table public.player_profiles (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  player_name text not null,
  player_tag text,
  town_hall_level integer check (town_hall_level between 1 and 20),
  hero_hall_level integer check (hero_hall_level between 1 and 20),
  current_league text,
  league_tier text,
  trophies integer check (trophies >= 0),
  best_trophies integer check (best_trophies >= 0),
  legend_best_rank integer check (legend_best_rank > 0),
  self_reported_gems integer check (self_reported_gems >= 0),
  clan_name text,
  progression public.progression_type,
  hero_progression jsonb not null default '{}',
  skin_collection jsonb not null default '[]',
  equipment_collection jsonb not null default '[]',
  pets jsonb not null default '[]',
  resource_stats jsonb not null default '{}',
  base_progression jsonb not null default '{}',
  evidence_urls text[] not null default '{}',
  verification_status text not null default 'unverified' check (verification_status in ('unverified','pending','verified','rejected')),
  description text,
  country text,
  languages text[] not null default '{}',
  status public.listing_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index player_profiles_owner_idx on public.player_profiles(owner_id);
create index player_profiles_discovery_idx on public.player_profiles(status, town_hall_level, trophies desc);

create table public.clans (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  clan_name text not null,
  clan_tag text,
  badge_url text,
  clan_level integer check (clan_level >= 1),
  member_count integer check (member_count between 1 and 50),
  clan_trophies integer check (clan_trophies >= 0),
  required_trophies integer check (required_trophies >= 0),
  war_frequency text,
  war_record jsonb not null default '{}',
  cwl_league text,
  capital_hall_level integer check (capital_hall_level between 1 and 10),
  language text,
  description text,
  requirements text,
  rules text,
  recruitment_open boolean not null default true,
  status public.listing_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index clans_discovery_idx on public.clans(status, recruitment_open, clan_level desc);

create table public.clan_recruitment (
  id uuid primary key default gen_random_uuid(),
  clan_id uuid not null references public.clans(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  headline text not null,
  details text,
  requirements text,
  contact_method text,
  status public.listing_status not null default 'draft',
  created_at timestamptz not null default now()
);

create table public.coaches (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references public.profiles(id) on delete cascade,
  experience text,
  specialties text[] not null default '{}',
  languages text[] not null default '{}',
  description text,
  avatar_url text,
  created_at timestamptz not null default now()
);

create table public.coaching_services (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coaches(id) on delete cascade,
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  category text not null,
  description text not null,
  price_amount numeric(12,2) check (price_amount >= 0),
  currency public.market_currency not null default 'INR',
  price_type public.price_type not null default 'fixed',
  duration_minutes integer check (duration_minutes > 0),
  availability jsonb not null default '{}',
  status public.listing_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (price_amount is not null or price_type = 'fixed')
);
create index coaching_services_public_idx on public.coaching_services(status, category);

create table public.coaching_bookings (
  id uuid primary key default gen_random_uuid(),
  service_id uuid not null references public.coaching_services(id) on delete restrict,
  learner_id uuid not null references public.profiles(id) on delete cascade,
  coach_owner_id uuid not null references public.profiles(id) on delete cascade,
  requested_at timestamptz,
  message text,
  status text not null default 'requested' check (status in ('requested','accepted','declined','cancelled','completed')),
  created_at timestamptz not null default now()
);
create index coaching_bookings_parties_idx on public.coaching_bookings(learner_id, coach_owner_id);

create table public.base_layouts (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  town_hall_level integer not null check (town_hall_level between 1 and 20),
  category text not null check (category in ('war','farming','trophy','hybrid','anti_3_star')),
  description text,
  image_urls text[] not null default '{}',
  layout_link text,
  price_amount numeric(12,2) check (price_amount >= 0),
  currency public.market_currency not null default 'INR',
  price_type public.price_type not null default 'fixed',
  is_original boolean not null default true,
  status public.listing_status not null default 'draft',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (price_amount is not null or price_type = 'fixed')
);
create index base_layouts_public_idx on public.base_layouts(status, town_hall_level, category);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('coach','base_layout','clan')),
  target_id uuid not null,
  rating integer not null check (rating between 1 and 5),
  body text,
  status text not null default 'published' check (status in ('published','hidden','removed')),
  created_at timestamptz not null default now(),
  unique(author_id, target_type, target_id)
);

create table public.favourites (
  user_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null check (target_type in ('player','clan','coach','base_layout')),
  target_id uuid not null,
  created_at timestamptz not null default now(),
  primary key(user_id, target_type, target_id)
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null,
  target_id uuid not null,
  reason text not null,
  details text,
  status text not null default 'open' check (status in ('open','reviewing','resolved','dismissed')),
  created_at timestamptz not null default now()
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title text not null,
  body text not null,
  href text,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.moderation_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  target_type text not null,
  target_id uuid,
  notes text,
  created_at timestamptz not null default now()
);

-- updated_at maintenance
create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = ''
as $$ begin new.updated_at = now(); return new; end; $$;

do $$
declare t text;
begin
  foreach t in array array['profiles','player_profiles','clans','coaching_services','base_layouts'] loop
    execute format('create trigger set_updated_at before update on public.%I for each row execute function public.set_updated_at()', t);
  end loop;
end $$;

-- Enable RLS on every exposed public table.
do $$
declare t text;
begin
  foreach t in array array['profiles','game_catalogue','player_profiles','clans','clan_recruitment','coaches','coaching_services','coaching_bookings','base_layouts','reviews','favourites','reports','notifications','moderation_logs'] loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- Public catalogue and published discovery content.
create policy "catalogue is readable" on public.game_catalogue for select to anon, authenticated using (true);
create policy "profiles are publicly readable" on public.profiles for select to anon, authenticated using (true);
create policy "owners update own profile" on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy "published player profiles are public" on public.player_profiles for select to anon, authenticated using (status = 'published' or owner_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "owners create player profiles" on public.player_profiles for insert to authenticated with check (owner_id = (select auth.uid()));
create policy "owners update player profiles" on public.player_profiles for update to authenticated using (owner_id = (select auth.uid()) or (select app_private.is_staff())) with check (owner_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "owners delete player profiles" on public.player_profiles for delete to authenticated using (owner_id = (select auth.uid()) or (select app_private.is_staff()));

create policy "published clans are public" on public.clans for select to anon, authenticated using ((status = 'published' and recruitment_open) or owner_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "owners create clans" on public.clans for insert to authenticated with check (owner_id = (select auth.uid()));
create policy "owners update clans" on public.clans for update to authenticated using (owner_id = (select auth.uid()) or (select app_private.is_staff())) with check (owner_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "owners delete clans" on public.clans for delete to authenticated using (owner_id = (select auth.uid()) or (select app_private.is_staff()));

create policy "published recruitment is public" on public.clan_recruitment for select to anon, authenticated using (status = 'published' or owner_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "owners create recruitment" on public.clan_recruitment for insert to authenticated with check (owner_id = (select auth.uid()));
create policy "owners manage recruitment" on public.clan_recruitment for all to authenticated using (owner_id = (select auth.uid()) or (select app_private.is_staff())) with check (owner_id = (select auth.uid()) or (select app_private.is_staff()));

create policy "coach profiles are public" on public.coaches for select to anon, authenticated using (true);
create policy "owners manage coach profile" on public.coaches for all to authenticated using (owner_id = (select auth.uid()) or (select app_private.is_staff())) with check (owner_id = (select auth.uid()) or (select app_private.is_staff()));

create policy "published coaching services are public" on public.coaching_services for select to anon, authenticated using (status = 'published' or owner_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "owners manage coaching services" on public.coaching_services for all to authenticated using (owner_id = (select auth.uid()) or (select app_private.is_staff())) with check (owner_id = (select auth.uid()) or (select app_private.is_staff()));

create policy "booking parties can view" on public.coaching_bookings for select to authenticated using (learner_id = (select auth.uid()) or coach_owner_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "learners create booking requests" on public.coaching_bookings for insert to authenticated with check (learner_id = (select auth.uid()));
create policy "booking parties update" on public.coaching_bookings for update to authenticated using (learner_id = (select auth.uid()) or coach_owner_id = (select auth.uid()) or (select app_private.is_staff())) with check (learner_id = (select auth.uid()) or coach_owner_id = (select auth.uid()) or (select app_private.is_staff()));

create policy "published layouts are public" on public.base_layouts for select to anon, authenticated using (status = 'published' or owner_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "owners manage layouts" on public.base_layouts for all to authenticated using (owner_id = (select auth.uid()) or (select app_private.is_staff())) with check (owner_id = (select auth.uid()) or (select app_private.is_staff()));

create policy "published reviews are public" on public.reviews for select to anon, authenticated using (status = 'published' or author_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "users create own reviews" on public.reviews for insert to authenticated with check (author_id = (select auth.uid()));
create policy "authors or staff manage reviews" on public.reviews for update to authenticated using (author_id = (select auth.uid()) or (select app_private.is_staff())) with check (author_id = (select auth.uid()) or (select app_private.is_staff()));

create policy "users view own favourites" on public.favourites for select to authenticated using (user_id = (select auth.uid()));
create policy "users manage own favourites" on public.favourites for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy "reporters view own reports" on public.reports for select to authenticated using (reporter_id = (select auth.uid()) or (select app_private.is_staff()));
create policy "users submit reports" on public.reports for insert to authenticated with check (reporter_id = (select auth.uid()));
create policy "staff manage reports" on public.reports for update to authenticated using ((select app_private.is_staff())) with check ((select app_private.is_staff()));

create policy "users view own notifications" on public.notifications for select to authenticated using (user_id = (select auth.uid()));
create policy "users update own notifications" on public.notifications for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy "staff view moderation logs" on public.moderation_logs for select to authenticated using ((select app_private.is_staff()));
create policy "staff write moderation logs" on public.moderation_logs for insert to authenticated with check ((select app_private.is_staff()));

-- Grants complement RLS; they do not replace it.
grant usage on schema public to anon, authenticated;
grant select on public.game_catalogue, public.profiles, public.player_profiles, public.clans, public.clan_recruitment, public.coaches, public.coaching_services, public.base_layouts, public.reviews to anon, authenticated;
grant select, insert, update, delete on public.player_profiles, public.clans, public.clan_recruitment, public.coaches, public.coaching_services, public.coaching_bookings, public.base_layouts, public.reviews, public.favourites, public.reports, public.notifications to authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert on public.moderation_logs to authenticated;


-- Create a public profile for each newly registered Auth user.
create or replace function app_private.handle_new_user()
returns trigger language plpgsql security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, username, display_name)
  values (
    new.id,
    nullif(new.raw_user_meta_data ->> 'username',''),
    coalesce(nullif(new.raw_user_meta_data ->> 'display_name',''), split_part(coalesce(new.email,''),'@',1), 'New player')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function app_private.handle_new_user() from public;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app_private.handle_new_user();

-- Private upload bucket; users may upload only into their own top-level folder.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('marketplace-media','marketplace-media',false,10485760,array['image/jpeg','image/png','image/webp'])
on conflict (id) do nothing;

create policy "owners upload marketplace media"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'marketplace-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "owners read marketplace media"
on storage.objects for select to authenticated
using (
  bucket_id = 'marketplace-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "owners update marketplace media"
on storage.objects for update to authenticated
using (
  bucket_id = 'marketplace-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
)
with check (
  bucket_id = 'marketplace-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "owners delete marketplace media"
on storage.objects for delete to authenticated
using (
  bucket_id = 'marketplace-media'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
