-- ==============================================================================
-- Turf&Ardor / FIFA Love Flutter App Schema Setup
-- Run this in your Supabase SQL Editor
-- ==============================================================================

-- DROP EXISTING TABLES IN CASE YOU RUN THIS MULTIPLE TIMES
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.verification_requests CASCADE;
DROP TABLE IF EXISTS public.swipe_actions CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.matches CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- 1. Profiles Table
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  age INTEGER,
  gender TEXT,
  nationality TEXT,
  city TEXT,
  is_local BOOLEAN DEFAULT false,
  team_supported TEXT,
  bio TEXT,
  interests TEXT[],
  languages TEXT[],
  match_type_preference TEXT[],
  countries_to_match TEXT[],
  is_verified BOOLEAN DEFAULT false,
  last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(), -- Used interchangeably in code
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Turn on Row Level Security for profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public profiles are viewable by everyone." ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert their own profile." ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile." ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Users can delete own profile." ON public.profiles FOR DELETE USING (auth.uid() = id);


-- 2. Matches Table
CREATE TABLE public.matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_a UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  user_b UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  match_score INTEGER DEFAULT 0,
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'unmatched')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Prevent duplicate active matches between the same users
CREATE UNIQUE INDEX IF NOT EXISTS matches_users_idx ON public.matches (LEAST(user_a, user_b), GREATEST(user_a, user_b));

ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view their matches." ON public.matches FOR SELECT USING (auth.uid() IN (user_a, user_b));
CREATE POLICY "Users can create matches." ON public.matches FOR INSERT WITH CHECK (auth.uid() IN (user_a, user_b));
CREATE POLICY "Users can update their matches." ON public.matches FOR UPDATE USING (auth.uid() IN (user_a, user_b));


-- 3. Messages Table
CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID REFERENCES public.matches(id) ON DELETE CASCADE,
  sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  read_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can view messages of their matches." ON public.messages FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.matches 
    WHERE public.matches.id = messages.match_id 
    AND auth.uid() IN (public.matches.user_a, public.matches.user_b)
  )
);
CREATE POLICY "Users can insert messages." ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);
CREATE POLICY "Users can update read status." ON public.messages FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.matches 
    WHERE public.matches.id = messages.match_id 
    AND auth.uid() IN (public.matches.user_a, public.matches.user_b)
  )
);


-- 4. Swipe Actions Table
CREATE TABLE public.swipe_actions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  swiper_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  swiped_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  action TEXT NOT NULL CHECK (action IN ('like', 'superlike', 'nope')),
  comment TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.swipe_actions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert their swipe actions." ON public.swipe_actions FOR INSERT WITH CHECK (auth.uid() = swiper_id);
CREATE POLICY "Users can view their own swipe actions." ON public.swipe_actions FOR SELECT USING (auth.uid() IN (swiper_id, swiped_id));
CREATE POLICY "Users can delete their swipe actions." ON public.swipe_actions FOR DELETE USING (auth.uid() = swiper_id);


-- 5. Verification Requests Table
CREATE TABLE public.verification_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  id_photo_url TEXT,
  selfie_url TEXT,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.verification_requests ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can manage their own verification." ON public.verification_requests USING (auth.uid() = user_id);


-- 6. Reports Table
CREATE TABLE public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  reported_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
  reason TEXT,
  details TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users can insert their own reports." ON public.reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);


-- ==============================================================================
-- Storage Buckets
-- ==============================================================================

-- Create buckets for Avatars and Verification Docs
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true) ON CONFLICT DO NOTHING;
INSERT INTO storage.buckets (id, name, public) VALUES ('verification-docs', 'verification-docs', false) ON CONFLICT DO NOTHING;

-- Storage Policies: Avatars
DO $$
BEGIN
    DROP POLICY IF EXISTS "Avatar images are publicly accessible." ON storage.objects;
    DROP POLICY IF EXISTS "Users can upload their own avatars." ON storage.objects;
    DROP POLICY IF EXISTS "Users can update their own avatars." ON storage.objects;
EXCEPTION
    WHEN undefined_object THEN null;
END $$;

CREATE POLICY "Avatar images are publicly accessible." ON storage.objects FOR SELECT USING (bucket_id = 'avatars');
CREATE POLICY "Users can upload their own avatars." ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'avatars' AND auth.role() = 'authenticated');
CREATE POLICY "Users can update their own avatars." ON storage.objects FOR UPDATE USING (bucket_id = 'avatars' AND auth.role() = 'authenticated');

-- Storage Policies: Verification Docs
DO $$
BEGIN
    DROP POLICY IF EXISTS "Users can upload verification docs." ON storage.objects;
    DROP POLICY IF EXISTS "Users can view their own verification docs." ON storage.objects;
EXCEPTION
    WHEN undefined_object THEN null;
END $$;

CREATE POLICY "Users can upload verification docs." ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'verification-docs' AND auth.role() = 'authenticated');
CREATE POLICY "Users can view their own verification docs." ON storage.objects FOR SELECT USING (bucket_id = 'verification-docs' AND auth.role() = 'authenticated');


-- ==============================================================================
-- Auto-Profile Creation Trigger
-- ==============================================================================

-- 1. Function to handle new user insertion
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, name, created_at)
  VALUES (
    new.id, 
    COALESCE(new.raw_user_meta_data->>'name', 'New Fan'),
    NOW()
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Trigger to execute function on signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ==============================================================================
-- RPC / Functions (Stubs to prevent errors if the code calls them)
-- ==============================================================================

CREATE OR REPLACE FUNCTION calculate_smart_match_score(p_user_id UUID, p_limit INT DEFAULT 40)
RETURNS TABLE (profile_id UUID, score FLOAT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT id AS profile_id, 80.0 AS score
  FROM public.profiles
  WHERE id != p_user_id
  LIMIT p_limit;
END;
$$;

CREATE OR REPLACE FUNCTION update_elo_after_swipe(p_swiper_id UUID, p_swiped_id UUID, p_action TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Dummy function to satisfy flutter calls.
END;
$$;

CREATE OR REPLACE FUNCTION learn_from_swipe(p_swiper_id UUID, p_swiped_id UUID, p_action TEXT)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Dummy function to satisfy flutter calls.
END;
$$;
