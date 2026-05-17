-- ────────────────────────────────────────────────────────────────────
-- public.users tərəfini Supabase Auth ilə düzgün sinxron et
-- ────────────────────────────────────────────────────────────────────
-- Problemlər:
--   1) public.users.id-də hələ `uuid_generate_v4()` default qalmışdı —
--      trigger NEW.id ötürür, default məsələ deyil, amma təmiz olsun.
--   2) public.users.id → auth.users(id) FK YOX idi → auth.users-dən
--      silinəndə public.users-də zombi sətir qalırdı. CASCADE əlavə.
--   3) auth.users-də olmayan zombi profillər təmizlənir ki, FK əlavə edə bilək.
-- ────────────────────────────────────────────────────────────────────

-- 1) id default-u sil
ALTER TABLE public.users ALTER COLUMN id DROP DEFAULT;

-- 2) Zombi sətirləri sil (auth.users-də qarşılığı olmayanlar)
DELETE FROM public.users p
WHERE NOT EXISTS (SELECT 1 FROM auth.users a WHERE a.id = p.id);

-- 3) FK yaradıla bilməsi üçün əvvəlcə köhnə FK varsa drop et
ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_id_fkey;

-- 4) FK + ON DELETE CASCADE əlavə et
ALTER TABLE public.users
  ADD CONSTRAINT users_id_fkey
  FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
