-- ============================================================================
-- Device claim RPC funksiyaları.
-- Supabase Auth-da artıq email mövcuddur. Bu RPC-lər yalnız `active_device_id`
-- işarələmə ilə məşğul olur — OTP göndərimi mobile tərəfindən Supabase Auth
-- (signInWithOtp) ilə həll olunur, sonra mobile sadəcə bu RPC çağırır.
-- ============================================================================

-- ──────── get_device_status ────────
CREATE OR REPLACE FUNCTION public.get_device_status(p_device_id text)
RETURNS TABLE(
  signup_otp_verified boolean,
  has_active_device boolean,
  current_is_active boolean,
  active_device_label text
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_user public.users;
  v_req_id text := COALESCE(trim(p_device_id), '');
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000'; END IF;
  SELECT * INTO v_user FROM public.users WHERE id = v_uid;
  IF NOT FOUND THEN RAISE EXCEPTION 'user_not_found' USING ERRCODE = 'P0002'; END IF;

  signup_otp_verified := v_user.signup_otp_verified;
  has_active_device := v_user.active_device_id IS NOT NULL;
  current_is_active := v_user.active_device_id IS NOT NULL AND v_user.active_device_id = v_req_id;
  active_device_label := v_user.active_device_label;
  RETURN NEXT;
END$$;

GRANT EXECUTE ON FUNCTION public.get_device_status(text) TO authenticated;

-- ──────── claim_device ────────
-- Bu cihazı yeganə aktiv cihaz kimi qeyd edir. İstifadəçi əvvəlcə Supabase
-- Auth-da OTP təsdiq etməlidir (mobile signInWithOtp + verifyOtp), bu RPC
-- yalnız uğurlu auth sonrası çağrılır.
CREATE OR REPLACE FUNCTION public.claim_device(p_device_id text, p_device_label text DEFAULT NULL)
RETURNS public.users
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_user public.users;
  v_id text := COALESCE(trim(p_device_id), '');
  v_label text := NULLIF(COALESCE(trim(p_device_label), ''), '');
BEGIN
  IF v_uid IS NULL THEN RAISE EXCEPTION 'not_authenticated' USING ERRCODE = '28000'; END IF;
  IF v_id = '' THEN RAISE EXCEPTION 'missing_device_id' USING ERRCODE = '22023'; END IF;

  UPDATE public.users
     SET active_device_id = v_id,
         active_device_label = v_label,
         active_device_claimed_at = now(),
         signup_otp_verified = true,
         email_verified = true
   WHERE id = v_uid
   RETURNING * INTO v_user;
  RETURN v_user;
END$$;

GRANT EXECUTE ON FUNCTION public.claim_device(text, text) TO authenticated;

-- ──────── check_device: hər API çağırışından əvvəl client çağırır ────────
-- Cari cihaz active_device_id ilə uyğun deyilsə FALSE qaytarır → mobile
-- /claim-device-ə yönləndirir. active_device_id=NULL olarsa keçir (ilk daxil
-- olan istifadəçi və ya sıfırlanmış hesab).
CREATE OR REPLACE FUNCTION public.check_device(p_device_id text)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_active text;
  v_req text := COALESCE(trim(p_device_id), '');
BEGIN
  IF v_uid IS NULL THEN RETURN false; END IF;
  SELECT active_device_id INTO v_active FROM public.users WHERE id = v_uid;
  IF v_active IS NULL THEN RETURN true; END IF;
  RETURN v_active = v_req;
END$$;

GRANT EXECUTE ON FUNCTION public.check_device(text) TO authenticated;
