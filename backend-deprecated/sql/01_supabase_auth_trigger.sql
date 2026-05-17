-- ────────────────────────────────────────────────────────────────────
-- Supabase Auth → public.users avtomatik profil yaradılması
-- ────────────────────────────────────────────────────────────────────
-- Bu skript bir dəfə Supabase SQL Editor-da işə salınır.
-- Niyə lazımdır:
--   1) Supabase Auth `auth.users` cədvəlində yalnız id/email/metadata saxlayır.
--   2) Bizim oyun datası (xp, elo, coins, wins, losses) `public.users`-dadır.
--   3) Bu trigger hər yeni Supabase istifadəçisi üçün public.users-da
--      eyni id ilə profil yaradır — beləliklə backend əlavə iş görmür.

-- Köhnə id PRIMARY GEN-d ş əyər varsa, FK problemini önləmək üçün
-- public.users.id sütununun default-i təmizlənir (Supabase Auth özü UUID təyin edir).
-- ────────────────────────────────────────────────────────────────────

-- public.users sütununa qoyula bilən FK var idi-yox yoxlama
DO $$
BEGIN
  -- id default trigger-i təmizlə (yeni id auth.users-dən gəlir)
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'users' AND column_default IS NOT NULL AND column_name = 'id'
  ) THEN
    ALTER TABLE public.users ALTER COLUMN id DROP DEFAULT;
  END IF;

  -- FK auth.users(id) — varsa ötür
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_schema = 'public' AND table_name = 'users' AND constraint_type = 'FOREIGN KEY' AND constraint_name = 'users_id_fkey'
  ) THEN
    ALTER TABLE public.users
      ADD CONSTRAINT users_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
  END IF;
END $$;

-- Trigger funksiyası: yeni auth.users sətri yaranan kimi public.users-da profil yarat
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  derived_username TEXT;
  candidate TEXT;
  attempt INT := 0;
BEGIN
  -- 1) Username derive: signup metadata-da varsa götür, yoxsa email-dən
  derived_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    NEW.raw_user_meta_data->>'name',
    NEW.raw_user_meta_data->>'full_name',
    split_part(COALESCE(NEW.email, 'player'), '@', 1)
  );

  -- 2) Yalnız hərf/rəqəm/altxətt, lowercase, max 24 simvol
  derived_username := lower(regexp_replace(derived_username, '[^a-zA-Z0-9_]', '_', 'g'));
  derived_username := regexp_replace(derived_username, '^_+|_+$', '', 'g');
  IF length(derived_username) = 0 THEN
    derived_username := 'player';
  END IF;
  IF length(derived_username) > 24 THEN
    derived_username := substring(derived_username, 1, 24);
  END IF;

  -- 3) Username-i unikal et — duplikat olarsa random suffix əlavə et
  candidate := derived_username;
  WHILE EXISTS (SELECT 1 FROM public.users WHERE username = candidate) AND attempt < 10 LOOP
    candidate := derived_username || '_' || floor(1000 + random() * 9000)::int::text;
    attempt := attempt + 1;
  END LOOP;

  -- 4) Profil yarat (default game stats)
  INSERT INTO public.users (id, username, email, avatar, email_verified)
  VALUES (
    NEW.id,
    candidate,
    NEW.email,
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.email_confirmed_at IS NOT NULL
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- Trigger: hər yeni auth.users insertindən sonra işə düş
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ────────────────────────────────────────────────────────────────────
-- Mövcud auth.users sətirləri üçün backfill (əgər varsa — yoxsa heç nə)
-- ────────────────────────────────────────────────────────────────────
INSERT INTO public.users (id, username, email, email_verified)
SELECT
  u.id,
  COALESCE(
    u.raw_user_meta_data->>'username',
    split_part(COALESCE(u.email, 'player_' || substr(u.id::text, 1, 6)), '@', 1)
  ),
  u.email,
  u.email_confirmed_at IS NOT NULL
FROM auth.users u
WHERE NOT EXISTS (SELECT 1 FROM public.users p WHERE p.id = u.id);
