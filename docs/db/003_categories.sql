-- Marti — categories for Discovery rails
-- Run in the Supabase SQL editor AFTER 001_listings.sql has been applied.
-- Safe to re-run: uses `create table if not exists`, `create index if not exists`,
-- and `drop policy if exists` guards.

create table if not exists public.categories (
    id            uuid primary key default gen_random_uuid(),
    slug          text unique not null,
    title         text not null,
    subtitle      text,
    city          text,                                  -- match listings.city (plain text)
    display_order integer not null default 0,
    created_at    timestamptz not null default now()
);

create table if not exists public.listing_categories (
    listing_id  uuid not null references public.listings(id)  on delete cascade,
    category_id uuid not null references public.categories(id) on delete cascade,
    primary key (listing_id, category_id)
);

create index if not exists listing_categories_category_idx on public.listing_categories (category_id);
create index if not exists listing_categories_listing_idx  on public.listing_categories (listing_id);
create index if not exists categories_city_order_idx       on public.categories (city, display_order);

-- Read-side view so the client can pull listings with their category_ids in one round-trip.
-- The `drop` is necessary because `listings.*` columns may change; `create or replace view`
-- doesn't allow renaming/removing columns.
drop view if exists public.listings_with_categories;
create view public.listings_with_categories as
select
    l.*,
    coalesce(
        array_agg(lc.category_id) filter (where lc.category_id is not null),
        '{}'::uuid[]
    ) as category_ids
from public.listings l
left join public.listing_categories lc on lc.listing_id = l.id
group by l.id;

alter table public.categories         enable row level security;
alter table public.listing_categories enable row level security;

drop policy if exists "Categories are publicly readable" on public.categories;
create policy  "Categories are publicly readable"
    on public.categories for select
    using (true);

drop policy if exists "Listing-categories are publicly readable" on public.listing_categories;
create policy  "Listing-categories are publicly readable"
    on public.listing_categories for select
    using (true);
