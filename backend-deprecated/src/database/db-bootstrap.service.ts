import { Injectable, OnModuleInit, Logger } from '@nestjs/common';
import { InjectDataSource } from '@nestjs/typeorm';
import { DataSource } from 'typeorm';

/**
 * Backend boot-da kritik DB-state təminatlarını idempotent tətbiq edir.
 *
 * Səbəb: TypeORM `synchronize: true` modu hər boot-da əl ilə əlavə edilən
 * FK / constraint / function-ləri silə bilər. Burada hər boot-da onları
 * yenidən qoyuruq — beləliklə Supabase Dashboard-dan istifadəçi silinəndə
 * CASCADE həmişə işləyir, trigger həmişə friend_code generate edir.
 */
@Injectable()
export class DbBootstrapService implements OnModuleInit {
  private readonly log = new Logger(DbBootstrapService.name);

  constructor(@InjectDataSource() private ds: DataSource) {}

  async onModuleInit() {
    try {
      // 1) public.users.id default-u sil (yeni id auth.users-dən gəlir)
      await this.ds.query(`ALTER TABLE public.users ALTER COLUMN id DROP DEFAULT`).catch(() => {});

      // 2) auth.users-də qarşılığı olmayan zombi profilləri sil
      await this.ds.query(
        `DELETE FROM public.users p WHERE NOT EXISTS (SELECT 1 FROM auth.users a WHERE a.id = p.id)`,
      );

      // 3) FK + CASCADE bərpası (TypeORM synchronize silmiş ola bilər)
      await this.ds.query(`ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_id_fkey`);
      await this.ds.query(
        `ALTER TABLE public.users ADD CONSTRAINT users_id_fkey
         FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE`,
      );

      // 4) gen_friend_code funksiyası
      await this.ds.query(`
        CREATE OR REPLACE FUNCTION public.gen_friend_code()
        RETURNS TEXT LANGUAGE plpgsql AS $$
        DECLARE
          chars TEXT := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
          result TEXT; i INT; attempt INT := 0;
        BEGIN
          LOOP
            result := '';
            FOR i IN 1..6 LOOP
              result := result || substr(chars, 1 + floor(random() * length(chars))::int, 1);
            END LOOP;
            IF NOT EXISTS (SELECT 1 FROM public.users WHERE friend_code = result) THEN
              RETURN result;
            END IF;
            attempt := attempt + 1;
            IF attempt > 100 THEN RAISE EXCEPTION 'Could not generate unique friend_code'; END IF;
          END LOOP;
        END;
        $$;
      `);

      // 5) handle_new_user trigger funksiyası (friend_code + username_set ilə)
      await this.ds.query(`
        CREATE OR REPLACE FUNCTION public.handle_new_user()
        RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
        DECLARE
          derived_username TEXT; candidate TEXT; attempt INT := 0; fc TEXT;
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
            NEW.id, candidate, NEW.email,
            NEW.raw_user_meta_data->>'avatar_url',
            NEW.email_confirmed_at IS NOT NULL, fc, FALSE
          )
          ON CONFLICT (id) DO NOTHING;
          RETURN NEW;
        END;
        $$;
      `);

      // 6) Trigger
      await this.ds.query(`DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users`);
      await this.ds.query(
        `CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users
         FOR EACH ROW EXECUTE FUNCTION public.handle_new_user()`,
      );

      // 7) xp → level auto-compute trigger. Supabase Studio-dan adminin XP-ni
      // dəyişməsi level-i də avtomatik yeniləsin (manual SQL tələb olunmasın).
      // Quadratic curve: N = floor((1 + sqrt(1 + 8*xp/1000))/2), capped at [1, 100].
      await this.ds.query(`
        CREATE OR REPLACE FUNCTION public.compute_level_from_xp()
        RETURNS TRIGGER LANGUAGE plpgsql AS $$
        BEGIN
          IF NEW.xp IS DISTINCT FROM OLD.xp THEN
            NEW.level := LEAST(100, GREATEST(1,
              FLOOR((1 + SQRT(1 + 8 * NEW.xp / 1000.0)) / 2)::int
            ));
          END IF;
          RETURN NEW;
        END;
        $$;
      `);
      await this.ds.query(`DROP TRIGGER IF EXISTS auto_compute_level ON public.users`);
      await this.ds.query(
        `CREATE TRIGGER auto_compute_level BEFORE UPDATE ON public.users
         FOR EACH ROW EXECUTE FUNCTION public.compute_level_from_xp()`,
      );

      this.log.log('DB bootstrap: FK + trigger reinstalled idempotently');
    } catch (e) {
      this.log.error('DB bootstrap failed', e as Error);
    }
  }
}
