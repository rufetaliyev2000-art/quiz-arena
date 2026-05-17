-- ============================================================================
-- finish_1v1 RPC: 1v1 matçı bitirir — ELO update, mükafat, match_player insert.
-- Hər iki oyunçu öz tərəfindən çağırır (idempotent: ikinci çağırış mövcud
-- nəticələri qaytarır, ELO təkrar update olunmur).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.finish_1v1(
  p_match_id uuid,
  p_my_score integer,
  p_my_correct integer,
  p_opp_user_id uuid,
  p_opp_score integer,
  p_opp_correct integer
)
RETURNS TABLE(
  winner_id uuid,
  is_draw boolean,
  my_elo_delta integer,
  opp_elo_delta integer,
  my_new_elo integer,
  opp_new_elo integer,
  my_xp_reward integer,
  my_coin_reward integer
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_me public.users;
  v_opp public.users;
  v_match public.matches;
  v_existing_my_score integer;
  v_winner_id uuid;
  v_is_draw boolean;
  v_expected_me float;
  v_expected_opp float;
  v_actual_me float;
  v_actual_opp float;
  v_k integer := 32;
  v_delta_me integer;
  v_delta_opp integer;
  v_new_elo_me integer;
  v_new_elo_opp integer;
  v_base_xp_me integer;
  v_base_coins_me integer;
  v_base_xp_opp integer;
  v_base_coins_opp integer;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  -- Match-i kilidlə (concurrent finish çağırışları üçün)
  SELECT * INTO v_match FROM public.matches WHERE id = p_match_id FOR UPDATE;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'match_not_found' USING ERRCODE = 'P0002';
  END IF;

  SELECT * INTO v_me FROM public.users WHERE id = v_uid FOR UPDATE;
  SELECT * INTO v_opp FROM public.users WHERE id = p_opp_user_id FOR UPDATE;

  IF NOT FOUND OR v_me.id IS NULL OR v_opp.id IS NULL THEN
    RAISE EXCEPTION 'player_not_found' USING ERRCODE = 'P0002';
  END IF;

  -- İdempotensi: əgər match artıq finished-dirsə və mənim row-um match_players-də
  -- mövcuddur — heç bir update etmə, ROC qaytar.
  IF v_match.status::text = 'finished' THEN
    SELECT score INTO v_existing_my_score
      FROM public.match_players
     WHERE match_id = p_match_id AND user_id = v_uid;
    IF FOUND THEN
      winner_id := v_match.winner_id;
      is_draw := v_match.winner_id IS NULL;
      -- ELO dəltası artıq tətbiq olunub — burada 0 qaytarırıq
      my_elo_delta := 0;
      opp_elo_delta := 0;
      my_new_elo := v_me.elo;
      opp_new_elo := v_opp.elo;
      my_xp_reward := 0;
      my_coin_reward := 0;
      RETURN NEXT;
      RETURN;
    END IF;
  END IF;

  -- Nəticə hesabla
  IF p_my_score = p_opp_score THEN
    v_is_draw := true;
    v_winner_id := NULL;
    v_actual_me := 0.5;
    v_actual_opp := 0.5;
  ELSE
    v_is_draw := false;
    IF p_my_score > p_opp_score THEN
      v_winner_id := v_me.id;
      v_actual_me := 1.0;
      v_actual_opp := 0.0;
    ELSE
      v_winner_id := v_opp.id;
      v_actual_me := 0.0;
      v_actual_opp := 1.0;
    END IF;
  END IF;

  -- ELO (K=32)
  v_expected_me := 1.0 / (1.0 + power(10, (v_opp.elo - v_me.elo)::float / 400.0));
  v_expected_opp := 1.0 - v_expected_me;
  v_delta_me := round(v_k * (v_actual_me - v_expected_me))::integer;
  v_delta_opp := round(v_k * (v_actual_opp - v_expected_opp))::integer;
  v_new_elo_me := GREATEST(0, v_me.elo + v_delta_me);
  v_new_elo_opp := GREATEST(0, v_opp.elo + v_delta_opp);

  -- Mükafat: outcome 1=win, 0.5=draw, 0=loss
  v_base_xp_me := CASE WHEN v_actual_me = 1 THEN 200 WHEN v_actual_me = 0.5 THEN 100 ELSE 50 END;
  v_base_coins_me := CASE WHEN v_actual_me = 1 THEN 150 WHEN v_actual_me = 0.5 THEN 75 ELSE 25 END;
  v_base_xp_opp := CASE WHEN v_actual_opp = 1 THEN 200 WHEN v_actual_opp = 0.5 THEN 100 ELSE 50 END;
  v_base_coins_opp := CASE WHEN v_actual_opp = 1 THEN 150 WHEN v_actual_opp = 0.5 THEN 75 ELSE 25 END;

  -- Match update
  UPDATE public.matches
     SET status = 'finished',
         winner_id = v_winner_id,
         ended_at = now()
   WHERE id = p_match_id;

  -- Match player-lər (upsert — concurrent çağırışda hər tərəf öz row-u yaradır)
  INSERT INTO public.match_players (match_id, user_id, score, correct_answers)
  VALUES (p_match_id, v_me.id, p_my_score, p_my_correct)
  ON CONFLICT DO NOTHING;
  INSERT INTO public.match_players (match_id, user_id, score, correct_answers)
  VALUES (p_match_id, v_opp.id, p_opp_score, p_opp_correct)
  ON CONFLICT DO NOTHING;

  -- User stats yenilə
  UPDATE public.users
     SET elo = v_new_elo_me,
         xp = xp + v_base_xp_me + p_my_correct * 10,
         coins = coins + v_base_coins_me + p_my_correct * 5,
         wins = wins + (CASE WHEN v_winner_id = v_me.id THEN 1 ELSE 0 END),
         losses = losses + (CASE WHEN v_winner_id = v_opp.id THEN 1 ELSE 0 END)
   WHERE id = v_me.id;
  UPDATE public.users
     SET level = public.compute_level(xp)
   WHERE id = v_me.id;

  UPDATE public.users
     SET elo = v_new_elo_opp,
         xp = xp + v_base_xp_opp + p_opp_correct * 10,
         coins = coins + v_base_coins_opp + p_opp_correct * 5,
         wins = wins + (CASE WHEN v_winner_id = v_opp.id THEN 1 ELSE 0 END),
         losses = losses + (CASE WHEN v_winner_id = v_me.id THEN 1 ELSE 0 END)
   WHERE id = v_opp.id;
  UPDATE public.users
     SET level = public.compute_level(xp)
   WHERE id = v_opp.id;

  winner_id := v_winner_id;
  is_draw := v_is_draw;
  my_elo_delta := v_delta_me;
  opp_elo_delta := v_delta_opp;
  my_new_elo := v_new_elo_me;
  opp_new_elo := v_new_elo_opp;
  my_xp_reward := v_base_xp_me + p_my_correct * 10;
  my_coin_reward := v_base_coins_me + p_my_correct * 5;
  RETURN NEXT;
END$$;

GRANT EXECUTE ON FUNCTION public.finish_1v1(uuid, integer, integer, uuid, integer, integer) TO authenticated;
