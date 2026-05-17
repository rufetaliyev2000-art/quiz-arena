-- ============================================================================
-- Friends RPC funksiyaları — friend_code lookup, request, accept, remove,
-- block, list, blocked, pending. Bütün dəyişikliklər iki tərəfli notify-ə
-- səbəb olur (Realtime: postgres_changes friendships table).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.friend_public_profile(p_user_id uuid)
RETURNS TABLE(id uuid, username text, friend_code text, avatar text, level integer, elo integer)
LANGUAGE sql
STABLE
AS $$
  SELECT u.id, u.username, u.friend_code, u.avatar, u.level, u.elo
    FROM public.users u WHERE u.id = p_user_id;
$$;

GRANT EXECUTE ON FUNCTION public.friend_public_profile(uuid) TO authenticated;

-- ──────── find_user_by_code ────────
CREATE OR REPLACE FUNCTION public.find_user_by_code(p_code text)
RETURNS TABLE(id uuid, username text, friend_code text, avatar text, level integer, elo integer)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  v_norm text := upper(trim(p_code));
BEGIN
  IF v_norm !~ '^[A-Z2-9]{6}$' THEN
    RAISE EXCEPTION 'invalid_code_format' USING ERRCODE = '22023';
  END IF;
  RETURN QUERY
  SELECT u.id, u.username, u.friend_code, u.avatar, u.level, u.elo
    FROM public.users u WHERE u.friend_code = v_norm;
END$$;

GRANT EXECUTE ON FUNCTION public.find_user_by_code(text) TO authenticated;

-- ──────── send_friend_request ────────
CREATE OR REPLACE FUNCTION public.send_friend_request(p_code text)
RETURNS TABLE(id uuid, status text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_target_id uuid;
  v_existing public.friendships;
  v_new public.friendships;
  v_norm text := upper(trim(p_code));
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000';
  END IF;

  SELECT u.id INTO v_target_id FROM public.users u WHERE u.friend_code = v_norm;
  IF v_target_id IS NULL THEN
    RAISE EXCEPTION 'user_not_found' USING ERRCODE = 'P0002';
  END IF;
  IF v_target_id = v_uid THEN
    RAISE EXCEPTION 'cannot_friend_self' USING ERRCODE = '22023';
  END IF;

  -- Blok yoxlaması
  IF EXISTS (
    SELECT 1 FROM public.friendships f
     WHERE (f.requester_id = v_target_id AND f.addressee_id = v_uid AND f.status = 'blocked')
        OR (f.requester_id = v_uid AND f.addressee_id = v_target_id AND f.status = 'blocked')
  ) THEN
    RAISE EXCEPTION 'blocked' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_existing FROM public.friendships f
   WHERE (f.requester_id = v_uid AND f.addressee_id = v_target_id)
      OR (f.requester_id = v_target_id AND f.addressee_id = v_uid)
   LIMIT 1;

  IF v_existing.id IS NOT NULL THEN
    IF v_existing.status = 'accepted' THEN
      RAISE EXCEPTION 'already_friends' USING ERRCODE = '23505';
    END IF;
    IF v_existing.status = 'pending' THEN
      IF v_existing.requester_id = v_target_id AND v_existing.addressee_id = v_uid THEN
        -- Onlar əvvəlcədən bizə göndərib — accept et
        UPDATE public.friendships SET status = 'accepted', updated_at = now()
         WHERE id = v_existing.id;
        id := v_existing.id; status := 'accepted'; RETURN NEXT; RETURN;
      END IF;
      RAISE EXCEPTION 'already_pending' USING ERRCODE = '23505';
    END IF;
  END IF;

  INSERT INTO public.friendships (requester_id, addressee_id, status)
  VALUES (v_uid, v_target_id, 'pending')
  RETURNING * INTO v_new;

  id := v_new.id;
  status := v_new.status;
  RETURN NEXT;
END$$;

GRANT EXECUTE ON FUNCTION public.send_friend_request(text) TO authenticated;

-- ──────── accept_friend_request ────────
CREATE OR REPLACE FUNCTION public.accept_friend_request(p_friendship_id uuid)
RETURNS TABLE(id uuid, status text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_f public.friendships;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000'; END IF;
  SELECT * INTO v_f FROM public.friendships WHERE id = p_friendship_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'friendship_not_found' USING ERRCODE = 'P0002'; END IF;
  IF v_f.addressee_id <> v_uid THEN RAISE EXCEPTION 'not_your_request' USING ERRCODE = '42501'; END IF;
  IF v_f.status <> 'pending' THEN RAISE EXCEPTION 'not_pending' USING ERRCODE = '22023'; END IF;

  UPDATE public.friendships SET status = 'accepted', updated_at = now() WHERE id = p_friendship_id;
  id := p_friendship_id; status := 'accepted'; RETURN NEXT;
END$$;

GRANT EXECUTE ON FUNCTION public.accept_friend_request(uuid) TO authenticated;

-- ──────── remove_friendship ────────
CREATE OR REPLACE FUNCTION public.remove_friendship(p_friendship_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_f public.friendships;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000'; END IF;
  SELECT * INTO v_f FROM public.friendships WHERE id = p_friendship_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'friendship_not_found' USING ERRCODE = 'P0002'; END IF;
  IF v_f.requester_id <> v_uid AND v_f.addressee_id <> v_uid THEN
    RAISE EXCEPTION 'not_yours' USING ERRCODE = '42501';
  END IF;
  DELETE FROM public.friendships WHERE id = p_friendship_id;
END$$;

GRANT EXECUTE ON FUNCTION public.remove_friendship(uuid) TO authenticated;

-- ──────── block_user ────────
CREATE OR REPLACE FUNCTION public.block_user(p_code text)
RETURNS TABLE(id uuid, status text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_target_id uuid;
  v_existing public.friendships;
  v_norm text := upper(trim(p_code));
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000'; END IF;
  SELECT u.id INTO v_target_id FROM public.users u WHERE u.friend_code = v_norm;
  IF v_target_id IS NULL THEN RAISE EXCEPTION 'user_not_found' USING ERRCODE = 'P0002'; END IF;
  IF v_target_id = v_uid THEN RAISE EXCEPTION 'cannot_block_self' USING ERRCODE = '22023'; END IF;

  SELECT * INTO v_existing FROM public.friendships f
   WHERE (f.requester_id = v_uid AND f.addressee_id = v_target_id)
      OR (f.requester_id = v_target_id AND f.addressee_id = v_uid)
   LIMIT 1;

  IF v_existing.id IS NULL THEN
    INSERT INTO public.friendships (requester_id, addressee_id, status)
    VALUES (v_uid, v_target_id, 'blocked')
    RETURNING friendships.id, friendships.status INTO id, status;
  ELSE
    UPDATE public.friendships
       SET requester_id = v_uid, addressee_id = v_target_id, status = 'blocked', updated_at = now()
     WHERE id = v_existing.id
     RETURNING friendships.id, friendships.status INTO id, status;
  END IF;
  RETURN NEXT;
END$$;

GRANT EXECUTE ON FUNCTION public.block_user(text) TO authenticated;

-- ──────── unblock_user ────────
CREATE OR REPLACE FUNCTION public.unblock_user(p_friendship_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_f public.friendships;
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000'; END IF;
  SELECT * INTO v_f FROM public.friendships WHERE id = p_friendship_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'friendship_not_found' USING ERRCODE = 'P0002'; END IF;
  IF v_f.status <> 'blocked' THEN RAISE EXCEPTION 'not_blocked' USING ERRCODE = '22023'; END IF;
  IF v_f.requester_id <> v_uid THEN RAISE EXCEPTION 'only_blocker_can_unblock' USING ERRCODE = '42501'; END IF;
  DELETE FROM public.friendships WHERE id = p_friendship_id;
END$$;

GRANT EXECUTE ON FUNCTION public.unblock_user(uuid) TO authenticated;

-- ──────── list_friends ────────
CREATE OR REPLACE FUNCTION public.list_friends()
RETURNS TABLE(
  friendship_id uuid,
  id uuid,
  username text,
  friend_code text,
  avatar text,
  level integer,
  elo integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000'; END IF;
  RETURN QUERY
  SELECT
    f.id AS friendship_id,
    u.id, u.username, u.friend_code, u.avatar, u.level, u.elo
  FROM public.friendships f
  JOIN public.users u ON u.id = CASE WHEN f.requester_id = v_uid THEN f.addressee_id ELSE f.requester_id END
  WHERE (f.requester_id = v_uid OR f.addressee_id = v_uid)
    AND f.status = 'accepted'
  ORDER BY f.updated_at DESC;
END$$;

GRANT EXECUTE ON FUNCTION public.list_friends() TO authenticated;

-- ──────── list_pending_requests ────────
CREATE OR REPLACE FUNCTION public.list_pending_requests()
RETURNS TABLE(
  direction text,
  friendship_id uuid,
  id uuid,
  username text,
  friend_code text,
  avatar text,
  level integer,
  elo integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000'; END IF;
  RETURN QUERY
  SELECT
    CASE WHEN f.addressee_id = v_uid THEN 'incoming' ELSE 'outgoing' END AS direction,
    f.id AS friendship_id,
    u.id, u.username, u.friend_code, u.avatar, u.level, u.elo
  FROM public.friendships f
  JOIN public.users u ON u.id = CASE WHEN f.addressee_id = v_uid THEN f.requester_id ELSE f.addressee_id END
  WHERE (f.requester_id = v_uid OR f.addressee_id = v_uid)
    AND f.status = 'pending'
  ORDER BY f.created_at DESC;
END$$;

GRANT EXECUTE ON FUNCTION public.list_pending_requests() TO authenticated;

-- ──────── list_blocked ────────
CREATE OR REPLACE FUNCTION public.list_blocked()
RETURNS TABLE(
  friendship_id uuid,
  id uuid,
  username text,
  friend_code text,
  avatar text,
  level integer,
  elo integer
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000'; END IF;
  RETURN QUERY
  SELECT f.id AS friendship_id, u.id, u.username, u.friend_code, u.avatar, u.level, u.elo
  FROM public.friendships f
  JOIN public.users u ON u.id = f.addressee_id
  WHERE f.requester_id = v_uid AND f.status = 'blocked'
  ORDER BY f.updated_at DESC;
END$$;

GRANT EXECUTE ON FUNCTION public.list_blocked() TO authenticated;
