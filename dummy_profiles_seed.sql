-- ─────────────────────────────────────────────────────────────────
-- FIFA LOVE — 5 Dummy Profiles with Avatar URLs
-- Real photos from Unsplash (free, no auth needed)
-- ─────────────────────────────────────────────────────────────────

-- Profile 1 — Camila Santos (Brazil)
INSERT INTO auth.users (
  id, instance_id, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  role, aud, confirmation_token,
  raw_app_meta_data, raw_user_meta_data, 
  is_super_admin
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'camila@fifalove.test',
  crypt('Fifalove2026!', gen_salt('bf')),
  now(), now(), now(),
  'authenticated', 'authenticated', '',
  '{"provider":"email","providers":["email"]}',
  '{"name":"Camila Santos"}',
  false
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (
  id, user_id, provider_id, identity_data,
  provider, last_sign_in_at, created_at, updated_at
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000001',
  'bbbbbbbb-0000-0000-0000-000000000001',
  'camila@fifalove.test',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000001",
    "email":"camila@fifalove.test",
    "email_verified":true}',
  'email', now(), now(), now()
)
ON CONFLICT (provider, provider_id) DO NOTHING;

INSERT INTO public.profiles (
  id, name, age, gender, nationality,
  city, is_local, team_supported,
  bio, interests, languages,
  match_type_preference, countries_to_match,
  is_verified, last_active_at, avatar_url
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000001',
  'Camila Santos', 26, 'female', 'Brazil',
  'Dallas', false, 'Brazil',
  'Carioca living for the beautiful game. 
   Here for the World Cup and maybe something 
   more. Vamos Brasil! 🇧🇷⚽',
  ARRAY['⚽ Die-Hard Fan','🍽️ Foodie',
    '🎶 Music','🏖️ Beach'],
  ARRAY['Portuguese','English','Spanish'],
  ARRAY['local-tourist','match-buddy',
    'tourist-tourist'],
  ARRAY['United States','Argentina','France',
    'Germany','England','Benin'],
  true, now(),
  'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400&h=500&fit=crop&crop=face'
)
ON CONFLICT (id) DO UPDATE SET
  avatar_url = EXCLUDED.avatar_url,
  last_active_at = now();

-- Profile 2 — Sofia Andrade (Portugal)
INSERT INTO auth.users (
  id, instance_id, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  role, aud, confirmation_token,
  raw_app_meta_data, raw_user_meta_data,
  is_super_admin
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000000',
  'sofia@fifalove.test',
  crypt('Fifalove2026!', gen_salt('bf')),
  now(), now(), now(),
  'authenticated', 'authenticated', '',
  '{"provider":"email","providers":["email"]}',
  '{"name":"Sofia Andrade"}',
  false
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (
  id, user_id, provider_id, identity_data,
  provider, last_sign_in_at, created_at, updated_at
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000002',
  'bbbbbbbb-0000-0000-0000-000000000002',
  'sofia@fifalove.test',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000002",
    "email":"sofia@fifalove.test",
    "email_verified":true}',
  'email', now(), now(), now()
)
ON CONFLICT (provider, provider_id) DO NOTHING;

INSERT INTO public.profiles (
  id, name, age, gender, nationality,
  city, is_local, team_supported,
  bio, interests, languages,
  match_type_preference, countries_to_match,
  is_verified, last_active_at, avatar_url
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000002',
  'Sofia Andrade', 28, 'female', 'Portugal',
  'Los Angeles', false, 'Portugal',
  'Porto girl exploring LA for the Cup. 
   Big Benfica fan but I will cheer for 
   Portugal first 🇵🇹. Love food and culture.',
  ARRAY['⚽ Die-Hard Fan','🎭 Culture',
    '🍽️ Foodie','📸 Explorer'],
  ARRAY['Portuguese','English','French'],
  ARRAY['dating-romance','local-tourist',
    'match-buddy'],
  ARRAY['United States','Brazil','France',
    'Morocco','Benin','England'],
  true, now(),
  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=500&fit=crop&crop=face'
)
ON CONFLICT (id) DO UPDATE SET
  avatar_url = EXCLUDED.avatar_url,
  last_active_at = now();

-- Profile 3 — Marcus Adeyemi (Nigeria)
INSERT INTO auth.users (
  id, instance_id, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  role, aud, confirmation_token,
  raw_app_meta_data, raw_user_meta_data,
  is_super_admin
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000003',
  '00000000-0000-0000-0000-000000000000',
  'marcus@fifalove.test',
  crypt('Fifalove2026!', gen_salt('bf')),
  now(), now(), now(),
  'authenticated', 'authenticated', '',
  '{"provider":"email","providers":["email"]}',
  '{"name":"Marcus Adeyemi"}',
  false
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (
  id, user_id, provider_id, identity_data,
  provider, last_sign_in_at, created_at, updated_at
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000003',
  'bbbbbbbb-0000-0000-0000-000000000003',
  'marcus@fifalove.test',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000003",
    "email":"marcus@fifalove.test",
    "email_verified":true}',
  'email', now(), now(), now()
)
ON CONFLICT (provider, provider_id) DO NOTHING;

INSERT INTO public.profiles (
  id, name, age, gender, nationality,
  city, is_local, team_supported,
  bio, interests, languages,
  match_type_preference, countries_to_match,
  is_verified, last_active_at, avatar_url
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000003',
  'Marcus Adeyemi', 24, 'male', 'Nigeria',
  'Atlanta', false, 'Nigeria',
  'Lagos to Atlanta for the Super Eagles. 
   First World Cup trip and already loving it. 
   Looking for fans to explore the city 🦅🇳🇬',
  ARRAY['⚽ Die-Hard Fan','🎶 Music',
    '🏃 Active','🍺 Nightlife'],
  ARRAY['English','Yoruba','French'],
  ARRAY['fan-friends','match-buddy',
    'local-tourist'],
  ARRAY['United States','Brazil','England',
    'France','Ghana','Senegal','Benin'],
  true, now(),
  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400&h=500&fit=crop&crop=face'
)
ON CONFLICT (id) DO UPDATE SET
  avatar_url = EXCLUDED.avatar_url,
  last_active_at = now();

-- Profile 4 — Yuki Tanaka (Japan)
INSERT INTO auth.users (
  id, instance_id, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  role, aud, confirmation_token,
  raw_app_meta_data, raw_user_meta_data,
  is_super_admin
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000004',
  '00000000-0000-0000-0000-000000000000',
  'yuki@fifalove.test',
  crypt('Fifalove2026!', gen_salt('bf')),
  now(), now(), now(),
  'authenticated', 'authenticated', '',
  '{"provider":"email","providers":["email"]}',
  '{"name":"Yuki Tanaka"}',
  false
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (
  id, user_id, provider_id, identity_data,
  provider, last_sign_in_at, created_at, updated_at
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000004',
  'bbbbbbbb-0000-0000-0000-000000000004',
  'yuki@fifalove.test',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000004",
    "email":"yuki@fifalove.test",
    "email_verified":true}',
  'email', now(), now(), now()
)
ON CONFLICT (provider, provider_id) DO NOTHING;

INSERT INTO public.profiles (
  id, name, age, gender, nationality,
  city, is_local, team_supported,
  bio, interests, languages,
  match_type_preference, countries_to_match,
  is_verified, last_active_at, avatar_url
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000004',
  'Yuki Tanaka', 25, 'female', 'Japan',
  'Miami', false, 'Japan',
  'Tokyo girl in Miami for the Samurai Blue. 
   Passionate about football and photography. 
   Looking for someone to share this 
   experience with 🇯🇵📸',
  ARRAY['⚽ Die-Hard Fan','📸 Explorer',
    '🎨 Art','🍽️ Foodie'],
  ARRAY['Japanese','English'],
  ARRAY['dating-romance','fan-friends',
    'match-buddy'],
  ARRAY['United States','Brazil','France',
    'South Korea','Australia','Benin'],
  false, now(),
  'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=500&fit=crop&crop=face'
)
ON CONFLICT (id) DO UPDATE SET
  avatar_url = EXCLUDED.avatar_url,
  last_active_at = now();

-- Profile 5 — Antoine Dubois (France)
INSERT INTO auth.users (
  id, instance_id, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  role, aud, confirmation_token,
  raw_app_meta_data, raw_user_meta_data,
  is_super_admin
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000005',
  '00000000-0000-0000-0000-000000000000',
  'antoine@fifalove.test',
  crypt('Fifalove2026!', gen_salt('bf')),
  now(), now(), now(),
  'authenticated', 'authenticated', '',
  '{"provider":"email","providers":["email"]}',
  '{"name":"Antoine Dubois"}',
  false
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO auth.identities (
  id, user_id, provider_id, identity_data,
  provider, last_sign_in_at, created_at, updated_at
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000005',
  'bbbbbbbb-0000-0000-0000-000000000005',
  'antoine@fifalove.test',
  '{"sub":"bbbbbbbb-0000-0000-0000-000000000005",
    "email":"antoine@fifalove.test",
    "email_verified":true}',
  'email', now(), now(), now()
)
ON CONFLICT (provider, provider_id) DO NOTHING;

INSERT INTO public.profiles (
  id, name, age, gender, nationality,
  city, is_local, team_supported,
  bio, interests, languages,
  match_type_preference, countries_to_match,
  is_verified, last_active_at, avatar_url
)
VALUES (
  'bbbbbbbb-0000-0000-0000-000000000005',
  'Antoine Dubois', 29, 'male', 'France',
  'New York/New Jersey', false, 'France',
  'Parisien in New York for Les Bleus. 
   Architect by day, football analyst by night. 
   Looking for fans who understand that 
   football is art 🇫🇷⚽',
  ARRAY['⚽ Die-Hard Fan','🎨 Art',
    '📚 History','🍽️ Foodie'],
  ARRAY['French','English','Spanish'],
  ARRAY['dating-romance','fan-friends',
    'match-buddy'],
  ARRAY['United States','Brazil','Portugal',
    'Morocco','Nigeria','Benin','Argentina'],
  true, now(),
  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=400&h=500&fit=crop&crop=face'
)
ON CONFLICT (id) DO UPDATE SET
  avatar_url = EXCLUDED.avatar_url,
  last_active_at = now();

-- Make sure all 5 profiles appear 
-- in the admin user's feed
-- by adding their nationalities to
-- admin's countries_to_match
UPDATE public.profiles
SET countries_to_match = ARRAY[
  'Brazil','France','Argentina',
  'United States','England','Germany',
  'Spain','Portugal','Morocco','Japan',
  'Nigeria','Mexico','Colombia','Senegal',
  'Australia','South Korea','Netherlands',
  'Italy','Belgium','Canada','Benin',
  'Ghana','Cameroon','Uruguay',
  'South Africa','Iran','Saudi Arabia'
]
WHERE id = 'aaaaaaaa-0000-0000-0000-000000000001';
