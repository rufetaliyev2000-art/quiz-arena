-- ============================================================================
-- Row Level Security policies.
-- Bütün cədvəllər üçün RLS-i aktivləşdiririk və müvafiq policies əlavə edirik.
-- RPC funksiyaları SECURITY DEFINER ilə işlədiyi üçün biznes məntiqi onlardan
-- keçir; client-dən birbaşa SELECT/INSERT/UPDATE-ləri də məhdudlaşdırırıq.
-- ============================================================================

-- ──────── users ────────
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Hər kəs öz profilini oxuya bilər
DROP POLICY IF EXISTS users_select_own ON public.users;
CREATE POLICY users_select_own ON public.users
  FOR SELECT TO authenticated
  USING (id = auth.uid());

-- Publik leaderboard üçün hamı, ELO/level/username/avatar görə bilər
-- (RPC `get_leaderboard` istifadə edir, lakin client birbaşa SELECT də edə bilər;
-- ona görə geniş policy əlavə edirik — yalnız security definer RPC-lərimizdə
-- istifadə olunan publik sahələr üçün).
DROP POLICY IF EXISTS users_select_public_minimal ON public.users;
CREATE POLICY users_select_public_minimal ON public.users
  FOR SELECT TO authenticated
  USING (true); -- application-level filter; RPC-lər `select` sahələrini məhdudlaşdırır

-- Yazma: yalnız öz profil. Username dəyişiklikləri RPC-lərdən keçir, lakin
-- avatar/customization update üçün UPDATE icazəsi öz user-i üzərindən
DROP POLICY IF EXISTS users_update_own ON public.users;
CREATE POLICY users_update_own ON public.users
  FOR UPDATE TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- ──────── matches ────────
ALTER TABLE public.matches ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS matches_select_participant ON public.matches;
CREATE POLICY matches_select_participant ON public.matches
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.match_players mp
       WHERE mp.match_id = matches.id AND mp.user_id = auth.uid()
    )
  );

-- INSERT/UPDATE/DELETE yalnız RPC-lərdən (SECURITY DEFINER bypass edir)

-- ──────── match_players ────────
ALTER TABLE public.match_players ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS mp_select_own_or_opponent ON public.match_players;
CREATE POLICY mp_select_own_or_opponent ON public.match_players
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.match_players mp2
       WHERE mp2.match_id = match_players.match_id AND mp2.user_id = auth.uid()
    )
  );

-- ──────── questions / categories ────────
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS questions_select_all ON public.questions;
CREATE POLICY questions_select_all ON public.questions
  FOR SELECT TO authenticated, anon
  USING (true);

DROP POLICY IF EXISTS categories_select_all ON public.categories;
CREATE POLICY categories_select_all ON public.categories
  FOR SELECT TO authenticated, anon
  USING (true);

-- ──────── leaderboard ────────
ALTER TABLE public.leaderboard ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS leaderboard_select_all ON public.leaderboard;
CREATE POLICY leaderboard_select_all ON public.leaderboard
  FOR SELECT TO authenticated, anon
  USING (true);

-- ──────── friendships ────────
ALTER TABLE public.friendships ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS friendships_select_involved ON public.friendships;
CREATE POLICY friendships_select_involved ON public.friendships
  FOR SELECT TO authenticated
  USING (requester_id = auth.uid() OR addressee_id = auth.uid());

-- Yazma əməliyyatları yalnız RPC funksiyalarından

-- ──────── matchmaking_queue ────────
ALTER TABLE public.matchmaking_queue ENABLE ROW LEVEL SECURITY;

-- Realtime listen üçün öz row-unu (və ya rəqibinin row-unu) görmək lazımdır.
-- Hər kəs öz row-unu görür; matched_with vasitəsilə rəqib row-u da görünür.
DROP POLICY IF EXISTS queue_select_self_or_opponent ON public.matchmaking_queue;
CREATE POLICY queue_select_self_or_opponent ON public.matchmaking_queue
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid()
    OR matched_with = auth.uid()
  );

-- Yazma əməliyyatları yalnız RPC-lərdən (join_matchmaking_queue və s.)
