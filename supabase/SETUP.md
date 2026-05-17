# Supabase Setup Təlimatı

Bu fayl Railway-i tamamilə silib Supabase-ə köçmə üçün addım-addım təlimatdır.

## 1. Migration fayllarını run et

`supabase/migrations/` qovluğundakı bütün `.sql` fayllarını **sıra ilə** run et.
İki yol var:

### A. Supabase CLI (lokal) ilə
```powershell
npm install -g supabase
supabase login           # browser açılır, hesabınızla daxil olun
supabase link --project-ref odjfodvdrmcmdsollhfk
supabase db push         # bütün migration-ları sıralı run edir
```

### B. Dashboard SQL Editor ilə
https://supabase.com/dashboard/project/odjfodvdrmcmdsollhfk/sql

Hər faylı **20260517000001 → 20260517000007** sırası ilə kopyala-yapışdır → **Run**.

## 2. SMTP konfiqurasiyası (OTP email göndərimi)

Dashboard → **Authentication** → **Email Templates** → **SMTP Settings**:
- Enable Custom SMTP: ✅
- Host: `smtp.gmail.com`
- Port: `465`
- Username: `gguizbattle@gmail.com`
- Password: `<Gmail App Password>` (https://myaccount.google.com/apppasswords — 2FA aktiv olmalıdır)
- Sender email: `gguizbattle@gmail.com`
- Sender name: `Gguiz Battle`
- Minimum interval: `60` saniyə

**Email Templates** → **Magic Link** template-də:
```html
<h2>Gguiz Battle təsdiq kodu</h2>
<p>Təsdiq kodunuz: <b>{{ .Token }}</b></p>
<p>Kod 10 dəqiqə ərzində etibarlıdır.</p>
```

## 3. URL Configuration

Dashboard → **Authentication** → **URL Configuration**:
- Site URL: `gguiz://app`
- Redirect URLs: `gguiz://app/**`, `http://localhost:*`

## 4. Realtime Publication

Dashboard → **Database** → **Replication** → **supabase_realtime**:
Aşağıdakı cədvəllər ✅ olmalıdır (migration-larda avtomatik əlavə olunub):
- `matchmaking_queue`
- `matches`
- `match_players`
- `friendships`

Yoxsa "Source" düyməsindən tıklayıb əlavə edin.

## 5. Storage (avatar upload üçün, gələcəkdə)

Dashboard → **Storage** → **New Bucket**:
- Name: `avatars`
- Public: ✅ (avatarlar publik görünür)

## 6. Railway servisi sil

Bütün dəyişikliklər test edildikdən sonra:

1. Railway dashboard: https://railway.app/
2. `quiz-arena-backend` servisi → Settings → Delete service
3. PostgreSQL plugin (varsa) silinə bilər — DB Supabase-də artıq mövcuddur

## 7. Yoxlama

Mobile-də son APK install et, login ol, aşağıdakıları test et:
- [ ] Sosial giriş işləyir (Google)
- [ ] Profile yüklənir
- [ ] Leaderboard real datadır
- [ ] 1v1 matchmaking iki cihazda eyni anda pair tapır
- [ ] Match nəticəsi ELO/coin/xp düzgün yenilənir
- [ ] Match history profil ekranında görünür
- [ ] Friend request göndər/qəbul et işləyir
- [ ] Signup OTP email gəlir (gguizbattle@gmail.com-dan)
- [ ] /claim-device axını işləyir
