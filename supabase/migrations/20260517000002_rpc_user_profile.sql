-- ============================================================================
-- Migration: user profile RPC funksiyaları
-- Bütün RPC-lər SECURITY DEFINER istifadə edir ki, RLS-i bypass edib biznes
-- məntiqi mərkəzləşmiş yerdə həll olunsun. Hər RPC-də ilk addım auth.uid()
-- yoxlanışıdır (anonim çağırış rədd olunur).
-- ============================================================================

-- ──────── get_my_profile ────────
-- /users/me-nin Supabase ekvivalenti. Backend `signup_otp_verified` və
-- `username_set` daxil olmaqla bütün profil sahələrini qaytarır.
CREATE OR REPLACE FUNCTION public.get_my_profile()
RETURNS public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user public.users;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT * INTO v_user FROM public.users WHERE id = auth.uid();
  IF NOT FOUND THEN
    RAISE EXCEPTION 'user_not_found' USING ERRCODE = 'P0002';
  END IF;

  RETURN v_user;
END$$;

GRANT EXECUTE ON FUNCTION public.get_my_profile() TO authenticated;

-- ──────── is_username_available ────────
CREATE OR REPLACE FUNCTION public.is_username_available(p_name text)
RETURNS TABLE(available boolean, reason text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_raw text := trim(p_name);
  v_existing_id uuid;
BEGIN
  IF length(v_raw) < 3 THEN
    available := false; reason := 'min_three_chars'; RETURN NEXT; RETURN;
  END IF;
  IF v_raw !~ '^[a-zA-Z0-9_]+$' THEN
    available := false; reason := 'format'; RETURN NEXT; RETURN;
  END IF;

  SELECT id INTO v_existing_id FROM public.users WHERE username = v_raw;
  IF v_existing_id IS NULL OR v_existing_id = auth.uid() THEN
    available := true; reason := NULL;
  ELSE
    available := false; reason := 'taken';
  END IF;
  RETURN NEXT;
END$$;

GRANT EXECUTE ON FUNCTION public.is_username_available(text) TO authenticated;

-- ──────── set_username ────────
CREATE OR REPLACE FUNCTION public.set_username(p_name text)
RETURNS public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_raw text := trim(p_name);
  v_existing_id uuid;
  v_user public.users;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;
  IF length(v_raw) < 3 THEN
    RAISE EXCEPTION 'min_three_chars' USING ERRCODE = '22023';
  END IF;
  IF v_raw !~ '^[a-zA-Z0-9_]+$' THEN
    RAISE EXCEPTION 'username_format' USING ERRCODE = '22023';
  END IF;

  SELECT id INTO v_existing_id FROM public.users WHERE username = v_raw;
  IF v_existing_id IS NOT NULL AND v_existing_id <> auth.uid() THEN
    RAISE EXCEPTION 'username_taken' USING ERRCODE = '23505';
  END IF;

  UPDATE public.users
     SET username = v_raw, username_set = true
   WHERE id = auth.uid()
   RETURNING * INTO v_user;

  RETURN v_user;
END$$;

GRANT EXECUTE ON FUNCTION public.set_username(text) TO authenticated;

-- ──────── compute_level ────────
-- Quadratic level curve: Lv N-ə çatmaq üçün 500*N*(N-1) XP, max 100.
CREATE OR REPLACE FUNCTION public.compute_level(p_total_xp integer)
RETURNS integer
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_total_xp <= 0 THEN 1
    ELSE LEAST(100, GREATEST(1, floor((1 + sqrt(1 + (8.0 * p_total_xp) / 1000)) / 2)::integer))
  END;
$$;

GRANT EXECUTE ON FUNCTION public.compute_level(integer) TO authenticated;

-- ──────── apply_local_reward ────────
-- Bot/solo oyunlarından qazanılan toplu mükafat. Lokal queue-da yığılan
-- xp/coins/wins ədədləri tək çağırışla göndərilir. ELO dəyişmir.
CREATE OR REPLACE FUNCTION public.apply_local_reward(
  p_xp integer DEFAULT 0,
  p_coins integer DEFAULT 0,
  p_wins integer DEFAULT 0,
  p_losses integer DEFAULT 0,
  p_draws integer DEFAULT 0  -- hələ DB-də saxlanılmır
)
RETURNS public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user public.users;
  v_new_xp integer;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  UPDATE public.users
     SET xp = xp + GREATEST(0, p_xp),
         coins = coins + GREATEST(0, p_coins),
         wins = wins + GREATEST(0, p_wins),
         losses = losses + GREATEST(0, p_losses)
   WHERE id = auth.uid()
   RETURNING * INTO v_user;

  -- Level-i yeni xp-ə uyğunlaşdır
  UPDATE public.users
     SET level = public.compute_level(v_user.xp)
   WHERE id = auth.uid()
   RETURNING * INTO v_user;

  RETURN v_user;
END$$;

GRANT EXECUTE ON FUNCTION public.apply_local_reward(integer, integer, integer, integer, integer) TO authenticated;

-- ──────── get_leaderboard ────────
-- Top N ELO-ya görə. Public profile sahələri.
CREATE OR REPLACE FUNCTION public.get_leaderboard(p_limit integer DEFAULT 50)
RETURNS TABLE(
  id uuid,
  username text,
  avatar text,
  elo integer,
  wins integer,
  losses integer,
  level integer
)
LANGUAGE sql
STABLE
AS $$
  SELECT u.id, u.username, u.avatar, u.elo, u.wins, u.losses, u.level
    FROM public.users u
   WHERE u.username_set = true
   ORDER BY u.elo DESC
   LIMIT LEAST(GREATEST(p_limit, 1), 200);
$$;

GRANT EXECUTE ON FUNCTION public.get_leaderboard(integer) TO authenticated, anon;

-- ──────── get_match_history ────────
-- Profil ekranı üçün son 20 matç + rəqib məlumatı + outcome.
CREATE OR REPLACE FUNCTION public.get_match_history()
RETURNS TABLE(
  match_id uuid,
  type text,
  status text,
  started_at timestamptz,
  ended_at timestamptz,
  outcome text,
  my_score integer,
  my_correct integer,
  opponent_id uuid,
  opponent_username text,
  opponent_score integer,
  opponent_correct integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  RETURN QUERY
  SELECT
    m.id AS match_id,
    m.type::text AS type,
    m.status::text AS status,
    m.started_at,
    m.ended_at,
    CASE
      WHEN m.type::text = '1v1' AND m.winner_id IS NOT NULL THEN
        CASE WHEN m.winner_id = v_uid THEN 'win' ELSE 'loss' END
      WHEN m.type::text = '1v1' AND m.winner_id IS NULL AND m.status::text = 'finished' THEN 'draw'
      ELSE 'solo'
    END AS outcome,
    mp_me.score AS my_score,
    mp_me.correct_answers AS my_correct,
    opp.user_id AS opponent_id,
    opp_u.username AS opponent_username,
    opp.score AS opponent_score,
    opp.correct_answers AS opponent_correct
  FROM public.match_players mp_me
  JOIN public.matches m ON m.id = mp_me.match_id
  LEFT JOIN LATERAL (
    SELECT mp.user_id, mp.score, mp.correct_answers
      FROM public.match_players mp
     WHERE mp.match_id = m.id AND mp.user_id <> v_uid
     LIMIT 1
  ) opp ON true
  LEFT JOIN public.users opp_u ON opp_u.id = opp.user_id
  WHERE mp_me.user_id = v_uid
  ORDER BY m.started_at DESC
  LIMIT 20;
END$$;

GRANT EXECUTE ON FUNCTION public.get_match_history() TO authenticated;
