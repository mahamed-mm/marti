-- Marti — sample listings for Discovery
-- Run in the Supabase SQL editor AFTER 001_listings.sql has been applied.
-- Safe to re-run: uses `on conflict (id) do nothing`.

-- Two deterministic host UUIDs so we can talk about them in tests.
-- (They don't need to exist in auth.users yet — host_id has no FK in v1.)
--   aaaa0000-0000-0000-0000-000000000001  = Aisha M.
--   bbbb0000-0000-0000-0000-000000000001  = Omar H.

insert into public.listings (
    id, title, city, neighborhood, description,
    price_per_night, latitude, longitude,
    photo_urls, amenities, max_guests,
    host_id, host_name, host_photo_url,
    is_verified, average_rating, review_count, cancellation_policy
)
values
(
    '11111111-1111-1111-1111-111111111101',
    'Peaceful Villa in Hodan',
    'Mogadishu', 'Hodan',
    'A quiet two-bedroom villa with a garden, five minutes from the main road.',
    8500, 2.0469, 45.3182,
    array['https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=1200'],
    array['WiFi', 'AC', 'Parking', 'Kitchen'], 4,
    'aaaa0000-0000-0000-0000-000000000001', 'Aisha M.', null,
    true, 4.8, 12, 'moderate'
),
(
    '11111111-1111-1111-1111-111111111102',
    'Modern Apartment near Lido Beach',
    'Mogadishu', 'Abdiaziz',
    'Bright one-bedroom with sea breeze and easy beach access.',
    12000, 2.0395, 45.3395,
    array['https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=1200'],
    array['WiFi', 'AC', 'Elevator'], 2,
    'bbbb0000-0000-0000-0000-000000000001', 'Omar H.', null,
    true, 4.6, 8, 'flexible'
),
(
    '11111111-1111-1111-1111-111111111103',
    'Beachfront Studio',
    'Mogadishu', 'Lido',
    'Compact studio a stone''s throw from Lido Beach. Great for solo travel.',
    6500, 2.0412, 45.3421,
    array['https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?w=1200'],
    array['WiFi', 'AC'], 1,
    'aaaa0000-0000-0000-0000-000000000001', 'Aisha M.', null,
    true, 4.5, 21, 'flexible'
),
(
    '11111111-1111-1111-1111-111111111104',
    'Cozy Guesthouse in Hargeisa',
    'Hargeisa', 'Jigjiga Yar',
    'Family-run guesthouse with breakfast included.',
    5500, 9.5600, 44.0650,
    array['https://images.unsplash.com/photo-1600585154340-be6161a56a0c?w=1200'],
    array['WiFi', 'Breakfast', 'Parking'], 3,
    'bbbb0000-0000-0000-0000-000000000001', 'Omar H.', null,
    false, 4.7, 15, 'strict'
),
(
    '11111111-1111-1111-1111-111111111105',
    'Central Hargeisa Loft',
    'Hargeisa', 'Koodbur',
    'Spacious two-bedroom loft in the heart of town.',
    9500, 9.5614, 44.0658,
    array['https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=1200'],
    array['WiFi', 'AC', 'Workspace', 'Parking'], 4,
    'aaaa0000-0000-0000-0000-000000000001', 'Aisha M.', null,
    true, 4.4, 6, 'moderate'
),
(
    '11111111-1111-1111-1111-111111111106',
    'Garden Villa in Waaberi',
    'Mogadishu', 'Waaberi',
    'Three-bedroom villa with a courtyard. Brand new to Marti.',
    11000, 2.0350, 45.3302,
    array['https://images.unsplash.com/photo-1613977257363-707ba9348227?w=1200'],
    array['WiFi', 'AC', 'Garden', 'Parking', 'Kitchen'], 6,
    'bbbb0000-0000-0000-0000-000000000001', 'Omar H.', null,
    true, null, 0, 'flexible'
)
on conflict (id) do nothing;
