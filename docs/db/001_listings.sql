-- Marti — Listing Discovery schema (Step 5 backend dependency)
-- Run in Supabase SQL editor: dev project first; production at launch.

create table if not exists public.listings (
    id                  uuid primary key default gen_random_uuid(),
    title               text not null,
    city                text not null,
    neighborhood        text not null,
    description         text not null,
    price_per_night     integer not null,           -- USD cents (8500 = $85.00)
    latitude            double precision not null,
    longitude           double precision not null,
    photo_urls          text[] not null default '{}',
    amenities           text[] not null default '{}',
    max_guests          integer not null,
    host_id             uuid not null,
    host_name           text not null,
    host_photo_url      text,
    is_verified         boolean not null default false,
    average_rating      double precision,
    review_count        integer not null default 0,
    cancellation_policy text not null default 'flexible',
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now()
);

create index if not exists listings_city_idx        on public.listings (city);
create index if not exists listings_price_idx       on public.listings (price_per_night);
create index if not exists listings_max_guests_idx  on public.listings (max_guests);

-- Junction: which listings a given user has saved.
create table if not exists public.saved_listings (
    user_id    uuid not null references auth.users(id) on delete cascade,
    listing_id uuid not null references public.listings(id) on delete cascade,
    created_at timestamptz not null default now(),
    primary key (user_id, listing_id)
);

-- Row-Level Security: listings are public read; saved_listings are per-user.
alter table public.listings enable row level security;

drop policy if exists "Listings are publicly readable" on public.listings;
create policy "Listings are publicly readable"
    on public.listings for select
    using (true);

alter table public.saved_listings enable row level security;

drop policy if exists "Users read their own saves" on public.saved_listings;
create policy "Users read their own saves"
    on public.saved_listings for select
    using (auth.uid() = user_id);

drop policy if exists "Users insert their own saves" on public.saved_listings;
create policy "Users insert their own saves"
    on public.saved_listings for insert
    with check (auth.uid() = user_id);

drop policy if exists "Users delete their own saves" on public.saved_listings;
create policy "Users delete their own saves"
    on public.saved_listings for delete
    using (auth.uid() = user_id);
