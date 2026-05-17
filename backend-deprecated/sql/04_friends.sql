-- ────────────────────────────────────────────────────────────────────
-- Dostlar sistemi: friend_code + friendships cədvəli
-- ────────────────────────────────────────────────────────────────────
-- friend_code: hər istifadəçi üçün 6 simvollu unikal kod (A-Z, 0-9).
-- Oyunçular bir-birinə bu kod ilə dostluq sorğusu göndərir.
-- friendships: yönəlmiş graph (requester → addressee), status: pending | accepted | blocked.
-- ────────────────────────────────────────────────────────────────────

-- 1) users.friend_code sütunu (varsa atla)
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS friend_code VARCHAR(6);

-- 2) Generator funksiyası — kollidisiya halında təkrar cəhd et
CREATE OR REPLACE FUNCTION public.gen_friend_code()
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
  chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; -- I, O, 0, 1 buraxılır oxunaqlılıq üçün
  result TEXT;
  i INT;
  attempt INT := 0;
BEGIN
  LOOP
    result := '';
    FOR i IN 1..6 LOOP
      result := result || substr(chars, 1 + floor(random() * length(chars))::int, 1);
    END LOOP;
    -- unikallıq yoxla
    IF NOT EXISTS (SELECT 1 FROM public.users WHERE friend_code = result) THEN
      RETURN result;
    END IF;
    attempt := attempt + 1;
    IF attempt > 100 THEN
      RAISE EXCEPTION 'Could not generate unique friend_code after 100 attempts';
    END IF;
  END LOOP;
END;
$$;

-- 3) Mövcud user-lərə friend_code generate et (boş olanlara)
UPDATE public.users
SET friend_code = public.gen_friend_code()
WHERE friend_code IS NULL;

-- 4) Unique + NOT NULL constraint
ALTER TABLE public.users
  ALTER COLUMN friend_code SET NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname='public' AND indexname='users_friend_code_uq'
  ) THEN
    CREATE UNIQUE INDEX users_friend_code_uq ON public.users(friend_code);
  END IF;
END $$;

-- 5) handle_new_user trigger funksiyasını yenilə — yeni istifadəçiyə də code ver
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
  fc TEXT;
BEGIN
  derived_username := COALESCE(
    NEW.raw_user_meta_data->>'username',
    NEW.raw_user_meta_data->>'name',
    NEW.raw_user_meta_data->>'full_name',
    split_part(COALESCE(NEW.email, 'player'), '@', 1)
  );
  derived_username := lower(regexp_replace(derived_username, '[^a-zA-Z0-9_]', '_', 'g'));
  derived_username := regexp_replace(derived_username, '^_+|_+$', '', 'g');
  IF length(derived_username) = 0 THEN derived_username := 'player'; END IF;
  IF length(derived_username) > 24 THEN derived_username := substring(derived_username, 1, 24); END IF;

  candidate := derived_username;
  WHILE EXISTS (SELECT 1 FROM public.users WHERE username = candidate) AND attempt < 10 LOOP
    candidate := derived_username || '_' || floor(1000 + random() * 9000)::int::text;
    attempt := attempt + 1;
  END LOOP;

  fc := public.gen_friend_code();

  INSERT INTO public.users (id, username, email, avatar, email_verified, friend_code, username_set)
  VALUES (
    NEW.id,
    candidate,
    NEW.email,
    NEW.raw_user_meta_data->>'avatar_url',
    NEW.email_confirmed_at IS NOT NULL,
    fc,
    FALSE
  )
  ON CONFLICT (id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- 6) friendships cədvəli
CREATE TABLE IF NOT EXISTS public.friendships (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  requester_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  addressee_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  status VARCHAR(16) NOT NULL CHECK (status IN ('pending','accepted','blocked')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT friendships_no_self CHECK (requester_id <> addressee_id),
  CONSTRAINT friendships_unique_pair UNIQUE (requester_id, addressee_id)
);

CREATE INDEX IF NOT EXISTS friendships_addressee_status_idx
  ON public.friendships(addressee_id, status);
CREATE INDEX IF NOT EXISTS friendships_requester_status_idx
  ON public.friendships(requester_id, status);
