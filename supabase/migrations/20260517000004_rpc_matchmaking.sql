-- ============================================================================
-- Realtime matchmaking — Socket.IO yaddaş queue-sunun Postgres ekvivalenti.
--
-- Mobile axını:
--   1. join_matchmaking_queue(...) çağır → ya match qaytarılır (dərhal pair),
--      ya da row queue-yə daxil olur (matched_with=null).
--   2. Mobile öz row-una Realtime subscribe edir (UPDATE event):
--        matched_with set olarsa → match tapıldı, match_id ilə döyüşə keç.
--   3. Hər 5 saniyədə try_find_match() çağır — vaxt keçdikcə ELO toleransı
--      genişlənir, yeni pair-lər tapılır.
--   4. Cancel: cancel_matchmaking() çağır.
-- ============================================================================

-- ──────── elo_tolerance: gözləmə müddətindən asılı ────────
-- 0-10s → 100, 10-30s → 250, 30-60s → 500, 60s+ → 1000
CREATE OR REPLACE FUNCTION public.elo_tolerance(p_waiting_ms bigint)
RETURNS integer
LANGUAGE sql
IMMUTABLE
AS $$
  SELECT CASE
    WHEN p_waiting_ms < 10000 THEN 100
    WHEN p_waiting_ms < 30000 THEN 250
    WHEN p_waiting_ms < 60000 THEN 500
    ELSE 1000
  END;
$$;

-- ──────── pick_random_question_indices ────────
-- Mobile-də 100 sual var (quiz_questions.dart); backend 10 random index qaytarır.
CREATE OR REPLACE FUNCTION public.pick_random_question_indices(p_count integer DEFAULT 10, p_total integer DEFAULT 100)
RETURNS integer[]
LANGUAGE sql
VOLATILE
AS $$
  SELECT array_agg(idx ORDER BY ord)
  FROM (
    SELECT (i - 1) AS idx, random() AS ord
      FROM generate_series(1, p_total) i
     ORDER BY ord
     LIMIT p_count
  ) shuffled;
$$;

-- ──────── start_match_pair: atomic match yaratma + queue təmizləmə ────────
-- İki user_id qəbul edir; concurrent çağırışlardan müdafiə üçün advisory lock.
-- Hər iki user-in row-ları queue-də mövcud olmalıdır və matched_with=null.
CREATE OR REPLACE FUNCTION public.start_match_pair(
  p_user_a uuid,
  p_user_b uuid
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_match_id uuid;
  v_indices integer[];
  v_min_id uuid;
  v_max_id uuid;
  v_a_exists boolean;
  v_b_exists boolean;
BEGIN
  -- Eyni cüt üçün eyni vaxtda iki çağırışı bir-birinə müraciət etdirmək üçün
  -- advisory lock istifadə edirik (sıralanmış pair → həmişə eyni lock).
  v_min_id := LEAST(p_user_a, p_user_b);
  v_max_id := GREATEST(p_user_a, p_user_b);
  PERFORM pg_advisory_xact_lock(
    hashtext(v_min_id::text || ':' || v_max_id::text)::bigint
  );

  -- Hər iki user hələ də queue-də matched_with=null halında olmalıdır.
  SELECT EXISTS (
    SELECT 1 FROM public.matchmaking_queue
     WHERE user_id = p_user_a AND matched_with IS NULL
  ) INTO v_a_exists;
  SELECT EXISTS (
    SELECT 1 FROM public.matchmaking_queue
     WHERE user_id = p_user_b AND matched_with IS NULL
  ) INTO v_b_exists;
  IF NOT (v_a_exists AND v_b_exists) THEN
    -- Birisi artıq başqa pair ilə bağlanıb; bu çağırış nəticəsiz.
    RETURN NULL;
  END IF;

  -- Match yarat
  v_indices := public.pick_random_question_indices(10, 100);
  INSERT INTO public.matches (type, status, started_at, question_indices)
  VALUES ('1v1', 'in_progress', now(), v_indices)
  RETURNING id INTO v_match_id;

  -- Queue row-larını "matched" olaraq işarələ — mobile Realtime UPDATE event-i
  -- görüb döyüşə keçəcək.
  UPDATE public.matchmaking_queue
     SET matched_with = p_user_b, match_id = v_match_id
   WHERE user_id = p_user_a;
  UPDATE public.matchmaking_queue
     SET matched_with = p_user_a, match_id = v_match_id
   WHERE user_id = p_user_b;

  RETURN v_match_id;
END$$;

-- ──────── join_matchmaking_queue ────────
-- Queue-yə daxil ol və dərhal pair axtar. ELO ±100 (yeni gələnin toleransı)
-- daxilində ən yaxın gözləyəni tap. Tapılırsa match yarat, queue təmizlə.
-- Tapılmırsa öz row-unu queue-də qoy.
CREATE OR REPLACE FUNCTION public.join_matchmaking_queue(
  p_elo integer,
  p_username text,
  p_friend_code text DEFAULT '',
  p_customization jsonb DEFAULT '{}'::jsonb
)
RETURNS TABLE(match_id uuid, opponent_user_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_opp record;
  v_now timestamptz := now();
  v_match_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  -- Əgər artıq aktiv matçda olduğumuzu yoxla
  IF EXISTS (
    SELECT 1 FROM public.match_players mp
    JOIN public.matches m ON m.id = mp.match_id
    WHERE mp.user_id = v_uid AND m.status::text = 'in_progress'
  ) THEN
    RAISE EXCEPTION 'already_in_match' USING ERRCODE = 'P0001';
  END IF;

  -- Mövcud queue row-unu upsert
  INSERT INTO public.matchmaking_queue (user_id, elo, username, friend_code, customization, joined_at, matched_with, match_id)
  VALUES (v_uid, p_elo, p_username, COALESCE(p_friend_code, ''), COALESCE(p_customization, '{}'::jsonb), v_now, NULL, NULL)
  ON CONFLICT (user_id) DO UPDATE
     SET elo = EXCLUDED.elo,
         username = EXCLUDED.username,
         friend_code = EXCLUDED.friend_code,
         customization = EXCLUDED.customization,
         joined_at = v_now,
         matched_with = NULL,
         match_id = NULL;

  -- Pair tap: yeni gələnin toleransı ±100, gözləyənin toleransı genişlənmiş ola bilər.
  -- Match qurulması üçün hər iki tərəfin toleransının MAX-i ELO fərqini əhatə etməlidir.
  SELECT q.user_id, q.elo, q.joined_at
    INTO v_opp
    FROM public.matchmaking_queue q
   WHERE q.user_id <> v_uid
     AND q.matched_with IS NULL
     AND abs(q.elo - p_elo) <= GREATEST(
           100, -- mənim toleransım
           public.elo_tolerance(extract(epoch FROM (v_now - q.joined_at))::bigint * 1000)
         )
   ORDER BY abs(q.elo - p_elo) ASC, q.joined_at ASC
   LIMIT 1;

  IF NOT FOUND THEN
    match_id := NULL;
    opponent_user_id := NULL;
    RETURN NEXT;
    RETURN;
  END IF;

  -- Atomic match yarat
  v_match_id := public.start_match_pair(v_uid, v_opp.user_id);
  IF v_match_id IS NULL THEN
    -- Race condition — rəqib artıq başqası ilə pair olub. Queue-də qal.
    match_id := NULL;
    opponent_user_id := NULL;
    RETURN NEXT;
    RETURN;
  END IF;

  match_id := v_match_id;
  opponent_user_id := v_opp.user_id;
  RETURN NEXT;
END$$;

GRANT EXECUTE ON FUNCTION public.join_matchmaking_queue(integer, text, text, jsonb) TO authenticated;

-- ──────── try_find_match: re-scan üçün, mobile periodically çağırır ────────
-- İstifadəçi queue-də qalmışdırsa, yenidən pair axtarır (ELO toleransı vaxt
-- keçdikcə genişlənir). Tapılırsa match yaradılır.
CREATE OR REPLACE FUNCTION public.try_find_match()
RETURNS TABLE(match_id uuid, opponent_user_id uuid)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_me record;
  v_opp record;
  v_now timestamptz := now();
  v_match_id uuid;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT * INTO v_me
    FROM public.matchmaking_queue
   WHERE user_id = v_uid AND matched_with IS NULL;
  IF NOT FOUND THEN
    match_id := NULL; opponent_user_id := NULL; RETURN NEXT; RETURN;
  END IF;

  SELECT q.user_id, q.elo, q.joined_at
    INTO v_opp
    FROM public.matchmaking_queue q
   WHERE q.user_id <> v_uid
     AND q.matched_with IS NULL
     AND abs(q.elo - v_me.elo) <= GREATEST(
           public.elo_tolerance(extract(epoch FROM (v_now - v_me.joined_at))::bigint * 1000),
           public.elo_tolerance(extract(epoch FROM (v_now - q.joined_at))::bigint * 1000)
         )
   ORDER BY abs(q.elo - v_me.elo) ASC, q.joined_at ASC
   LIMIT 1;

  IF NOT FOUND THEN
    match_id := NULL; opponent_user_id := NULL; RETURN NEXT; RETURN;
  END IF;

  v_match_id := public.start_match_pair(v_uid, v_opp.user_id);
  IF v_match_id IS NULL THEN
    match_id := NULL; opponent_user_id := NULL; RETURN NEXT; RETURN;
  END IF;

  match_id := v_match_id;
  opponent_user_id := v_opp.user_id;
  RETURN NEXT;
END$$;

GRANT EXECUTE ON FUNCTION public.try_find_match() TO authenticated;

-- ──────── cancel_matchmaking ────────
CREATE OR REPLACE FUNCTION public.cancel_matchmaking()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;
  DELETE FROM public.matchmaking_queue WHERE user_id = auth.uid();
END$$;

GRANT EXECUTE ON FUNCTION public.cancel_matchmaking() TO authenticated;

-- ──────── cleanup_stale_queue: 5 dəqiqədən köhnə row-ları sil ────────
-- Mobile disconnect olarsa row qala bilər; pg_cron yoxdursa client çağıra bilər.
CREATE OR REPLACE FUNCTION public.cleanup_stale_queue()
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_deleted integer;
BEGIN
  DELETE FROM public.matchmaking_queue
   WHERE matched_with IS NULL AND joined_at < (now() - interval '5 minutes');
  GET DIAGNOSTICS v_deleted = ROW_COUNT;
  RETURN v_deleted;
END$$;

GRANT EXECUTE ON FUNCTION public.cleanup_stale_queue() TO authenticated;
