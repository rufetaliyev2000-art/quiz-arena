-- ────────────────────────────────────────────────────────────────────
-- public.users.username_set sütunu
-- ────────────────────────────────────────────────────────────────────
-- Niyə: Supabase Auth ilə girişdə avtomatik username (email/Google name-dən)
-- yaradılır. İstifadəçi qeydiyyatdan sonra özünə ad seçməlidir. Bu flag
-- mobile-a deyir ki, profil üçün username setup ekranı göstərsin.
-- ────────────────────────────────────────────────────────────────────

-- Sütun əlavə et (idempotent)
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS username_set BOOLEAN NOT NULL DEFAULT FALSE;

-- Mövcud istifadəçilərə bu flag-i true qoy — onlar artıq username seçiblər
-- (yalnız yeni Supabase Auth ilə qeydiyyatdan keçənlərdə default false işləyəcək).
UPDATE public.users SET username_set = TRUE WHERE username_set = FALSE;

-- Trigger funksiyasını yenilə: yeni Supabase Auth istifadəçisi üçün
-- username avtomatik derive olunur AMMA username_set = FALSE qalır.
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
  derived_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    NEW.raw_user_meta_data->>'name',
    NEW.raw_user_meta_data->>'full_name',
    split_part(COALESCE(NEW.email, 'player'), '@', 1)
  );
  derived_username := lower(regexp_replace(derived_username, '[^a-zA-Z0-9_]', '_', 'g'));
  derived_username := regexp_replace(derived_username, '^_+|_+$', '', 'g');
  IF length(derived_username) = 0 THEN
    derived_username := 'player';
  END IF;
  IF length(derived_username) > 24 THEN
    derived_username := substring(derived_username, 1, 24);
  END IF;

  candidate := derived_username;
  WHILE EXISTS (SELECT 1 FROM public.users WHERE username = candidate) AND attempt < 10 LOOP
    candidate := derived_username || '_' || floor(1000 + random() * 9000)::int::text;
    attempt := attempt + 1;
  END LOOP;

  -- username_set = FALSE → mobile setup ekranı göstərəcək
  INSERT INTO public.users (id, username, email, avatar, email_verified, username_set)
  VALUES (
    NEW.id,
    candidate,
    NEW.email,
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.email_confirmed_at IS NOT NULL,
    FALSE
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;
