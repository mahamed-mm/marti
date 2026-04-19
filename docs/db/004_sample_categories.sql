-- Marti — sample categories + join rows for Discovery rails
-- Run AFTER 002_sample_listings.sql AND 003_categories.sql.
-- Safe to re-run: uses `on conflict do nothing`.

-- Category rows. display_order controls rail sequence on screen.
insert into public.categories (id, slug, title, subtitle, city, display_order) values
    ('22222222-0000-0000-0000-000000000001', 'popular-mogadishu', 'Popular homes in Mogadishu', null,                            'Mogadishu', 10),
    ('22222222-0000-0000-0000-000000000002', 'new-hargeisa',      'New in Hargeisa',            null,                            'Hargeisa',  20),
    ('22222222-0000-0000-0000-000000000003', 'beachfront',        'Beachfront stays',           null,                            null,        30),
    ('22222222-0000-0000-0000-000000000004', 'verified-hosts',    'Verified hosts',             'Identity & property confirmed', null,        40),
    ('22222222-0000-0000-0000-000000000005', 'weekend-ready',     'Available this weekend',     null,                            null,        50)
on conflict (id) do nothing;

-- Join rows. Designed so every listing appears in >=2 categories and every category has >=3 listings.
--   popular-mogadishu   -> 4 (Hodan, Lido Apt, Lido Studio, Waaberi)
--   new-hargeisa        -> 3 (Cozy Guesthouse, Central Loft, Rooftop)
--   beachfront          -> 3 (Lido Apt, Lido Studio, Waaberi)
--   verified-hosts      -> 5 (all verified listings)
--   weekend-ready       -> 4 (Hodan, Cozy Guesthouse, Central Loft, Rooftop)
insert into public.listing_categories (listing_id, category_id) values
    -- 101 Peaceful Villa in Hodan (Mogadishu, verified)
    ('11111111-1111-1111-1111-111111111101', '22222222-0000-0000-0000-000000000001'),
    ('11111111-1111-1111-1111-111111111101', '22222222-0000-0000-0000-000000000004'),
    ('11111111-1111-1111-1111-111111111101', '22222222-0000-0000-0000-000000000005'),
    -- 102 Modern Apartment near Lido Beach (Mogadishu, verified, beach)
    ('11111111-1111-1111-1111-111111111102', '22222222-0000-0000-0000-000000000001'),
    ('11111111-1111-1111-1111-111111111102', '22222222-0000-0000-0000-000000000003'),
    ('11111111-1111-1111-1111-111111111102', '22222222-0000-0000-0000-000000000004'),
    -- 103 Beachfront Studio (Mogadishu, verified, beach)
    ('11111111-1111-1111-1111-111111111103', '22222222-0000-0000-0000-000000000001'),
    ('11111111-1111-1111-1111-111111111103', '22222222-0000-0000-0000-000000000003'),
    ('11111111-1111-1111-1111-111111111103', '22222222-0000-0000-0000-000000000004'),
    -- 104 Cozy Guesthouse in Hargeisa (Hargeisa, unverified)
    ('11111111-1111-1111-1111-111111111104', '22222222-0000-0000-0000-000000000002'),
    ('11111111-1111-1111-1111-111111111104', '22222222-0000-0000-0000-000000000005'),
    -- 105 Central Hargeisa Loft (Hargeisa, verified)
    ('11111111-1111-1111-1111-111111111105', '22222222-0000-0000-0000-000000000002'),
    ('11111111-1111-1111-1111-111111111105', '22222222-0000-0000-0000-000000000004'),
    ('11111111-1111-1111-1111-111111111105', '22222222-0000-0000-0000-000000000005'),
    -- 106 Garden Villa in Waaberi (Mogadishu, verified, beachfront-courtyard)
    ('11111111-1111-1111-1111-111111111106', '22222222-0000-0000-0000-000000000001'),
    ('11111111-1111-1111-1111-111111111106', '22222222-0000-0000-0000-000000000003'),
    ('11111111-1111-1111-1111-111111111106', '22222222-0000-0000-0000-000000000004'),
    -- 107 Rooftop Apartment in Hargeisa (Hargeisa, unverified, new)
    ('11111111-1111-1111-1111-111111111107', '22222222-0000-0000-0000-000000000002'),
    ('11111111-1111-1111-1111-111111111107', '22222222-0000-0000-0000-000000000005')
on conflict do nothing;
