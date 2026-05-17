-- ============================================================================
-- Migration: schema alignment
-- Date: 2026-05-17
-- Purpose:
--   Mövcud `public.users` cədvəli TypeORM tərəfindən yaradılıb (synchronize:true).
--   Bu migration onu Supabase Auth-a tam uyğunlaşdırır:
--     1. `public.users.id` Foreign Key auth.users.id-ə bağlanır (cascade delete).
--     2. Yeni matchmaking_queue cədvəli + Realtime publication.
--     3. Köhnə backend-də mövcud olmayan, lakin Supabase axınında lazımi
--        sahələri əlavə edirik (default-larla, idempotent).
--
-- Bu fayl SQL Editor-də run edilməlidir. Lokal CLI varsa:
--   supabase db push
-- ============================================================================

-- Yalnız mövcud deyilsə yaradılan sahələrlə davam et. ALTER TABLE IF EXISTS-lər
-- mövcud TypeORM sxeminə zərər vurmamağa zəmanət verir.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS signup_otp_verified boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS active_device_id text,
  ADD COLUMN IF NOT EXISTS active_device_label text,
  ADD COLUMN IF NOT EXISTS active_device_claimed_at timestamptz;

-- `public.users.id` artıq UUID-dir; auth.users.id ilə eyni olduğunu zəmanət edən
-- FK var (DB trigger backend boot zamanı qurub). Burada təkrar yaratmırıq.
-- Lakin əgər FK yoxdursa, daha güvənli bir constraint əlavə edirik:
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'users_id_fkey_auth'
  ) THEN
    BEGIN
      ALTER TABLE public.users
        ADD CONSTRAINT users_id_fkey_auth
        FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
    EXCEPTION WHEN duplicate_object THEN
      NULL; -- artıq var, atla
    END;
  END IF;
END$$;

-- ============================================================================
-- matchmaking_queue: Socket.IO yaddaş queue-sunun Supabase ekvivalenti.
-- Realtime publication açıqdır → mobile bütün INSERT/UPDATE/DELETE-i görür.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.matchmaking_queue (
  user_id uuid PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
  elo integer NOT NULL,
  username text NOT NULL,
  friend_code text NOT NULL DEFAULT '',
  customization jsonb NOT NULL DEFAULT '{}'::jsonb,
  joined_at timestamptz NOT NULL DEFAULT now(),
  -- pair tapıldıqda set olunur; Realtime listener bunu görüb match-i başlayır.
  matched_with uuid REFERENCES public.users(id) ON DELETE SET NULL,
  match_id uuid REFERENCES public.matches(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS matchmaking_queue_elo_idx
  ON public.matchmaking_queue (elo)
  WHERE matched_with IS NULL;

CREATE INDEX IF NOT EXISTS matchmaking_queue_joined_at_idx
  ON public.matchmaking_queue (joined_at)
  WHERE matched_with IS NULL;

-- Realtime publication-a əlavə et (Supabase-də əksər cədvəllər avtomatik
-- daxildir, lakin yeni cədvəl üçün manual əlavə tələb oluna bilər).
ALTER PUBLICATION supabase_realtime ADD TABLE public.matchmaking_queue;

-- ============================================================================
-- match_player score-larını real-time görmək üçün matches və match_players
-- da Realtime publication-da olmalıdır (varsa atlanır).
-- ============================================================================
DO $$
BEGIN
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.matches;
  EXCEPTION WHEN duplicate_object THEN NULL; END;
  BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.match_players;
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- ============================================================================
-- Match cədvəlinə question_indices əlavə (mobile-də göstərilən 10 sual indeksi)
-- ============================================================================
ALTER TABLE public.matches
  ADD COLUMN IF NOT EXISTS question_indices integer[] DEFAULT '{}';
