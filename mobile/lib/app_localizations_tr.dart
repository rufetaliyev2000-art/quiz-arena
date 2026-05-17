// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get tagline => 'BİL . OYNA . KAZAN';

  @override
  String get welcomeBack => 'Tekrar Hoşgeldin!';

  @override
  String get usernameOrEmail => 'Kullanıcı Adı veya Email';

  @override
  String get password => 'Şifre';

  @override
  String get fieldRequired => 'Zorunlu';

  @override
  String get minSixChars => 'Min 6 karakter';

  @override
  String get loginButton => 'GİRİŞ';

  @override
  String get dontHaveAccount => 'Hesabın yok mu? ';

  @override
  String get registerLink => 'Kayıt Ol';

  @override
  String get createAccountTitle => 'Hesap Oluştur';

  @override
  String get joinBattleArena => 'Gguiz Battle savaş arenasına katıl';

  @override
  String get usernameField => 'Kullanıcı Adı';

  @override
  String get minThreeChars => 'Min 3 karakter';

  @override
  String get usernameFormatError => 'Sadece harf, rakam ve _';

  @override
  String get emailField => 'Email';

  @override
  String get invalidEmail => 'Geçersiz email';

  @override
  String get passwordWithMin => 'Şifre (min 6 karakter)';

  @override
  String get createAccountButton => 'HESAP OLUŞTUR';

  @override
  String get alreadyHaveAccount => 'Zaten hesabın var mı? ';

  @override
  String get loginLink => 'Giriş';

  @override
  String get daily => 'GÜNLÜK';

  @override
  String get tournament => 'TURNUVA';

  @override
  String get winBigRewards => 'Büyük ödüller kazan!';

  @override
  String get startsIn => 'Başlıyor';

  @override
  String get joinNow => 'ŞİMDİ KATIL';

  @override
  String get playModes => 'OYUN MODLARI';

  @override
  String get seeAll => 'Tümü';

  @override
  String get quickBattle => 'Hızlı Savaş';

  @override
  String get practice => 'Antrenman';

  @override
  String get battleRoyaleTitle => 'BATTLE\nROYALE';

  @override
  String get lastOneWins => 'Son Kalan Kazanır';

  @override
  String get dailyMissions => 'GÜNLÜK GÖREVLER';

  @override
  String get mission1 => '3 maç oyna';

  @override
  String get mission2 => '1 maç kazan';

  @override
  String get mission3 => '10 soruyu doğru cevapla';

  @override
  String missionPlayMatch(int count) {
    return '$count maç oyna';
  }

  @override
  String missionWinMatch(int count) {
    return '$count maç kazan';
  }

  @override
  String missionAnswerCorrect(int count) {
    return '$count soruyu doğru cevapla';
  }

  @override
  String missionFastAnswer(int count) {
    return '5 saniyede $count doğru cevap ver';
  }

  @override
  String missionWinStreak(int count) {
    return 'Üst üste $count maç kazan';
  }

  @override
  String missionRefreshIn(String time) {
    return 'Yenileniyor: $time';
  }

  @override
  String get missionClaim => 'Al';

  @override
  String get missionClaimed => 'Alındı';

  @override
  String missionRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String missionRewardCoins(int coins) {
    return '+$coins jeton';
  }

  @override
  String get leaderboard => 'Sıralama';

  @override
  String get view => 'Görüntüle';

  @override
  String get topPlayers => 'En İyi Oyuncular';

  @override
  String get rankDiamond => 'Elmas';

  @override
  String get rankPlatinum => 'Platin';

  @override
  String get rankGoldII => 'Altın II';

  @override
  String get rankSilver => 'Gümüş';

  @override
  String get rankBronze => 'Bronz';

  @override
  String get levelLabel => 'Seviye';

  @override
  String get eloLabel => 'ELO';

  @override
  String get coinsLabel => 'Jeton';

  @override
  String get totalWins => 'Toplam Galibiyet';

  @override
  String get losses => 'Mağlubiyetler';

  @override
  String get totalXP => 'Toplam XP';

  @override
  String get winRate => 'Galibiyet %';

  @override
  String get achievementsTitle => 'Başarılar';

  @override
  String get achievementFirstWin => 'İlk Galibiyet';

  @override
  String get achievementTenWins => '10 Galibiyet';

  @override
  String get achievementSpeedDemon => 'Hız Canavarı';

  @override
  String get achievementFiftyWins => '50 Galibiyet';

  @override
  String get recentMatchesTitle => 'Son Maçlar';

  @override
  String get matchHistorySoon => 'Maç geçmişi yakında';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get notificationsLabel => 'Bildirimler';

  @override
  String get languageLabel => 'Dil';

  @override
  String get privacyPolicyLabel => 'Gizlilik Politikası';

  @override
  String get logoutLabel => 'Çıkış';

  @override
  String errorMessage(String message) {
    return 'Hata: $message';
  }

  @override
  String get oneVsOneBattle => '1v1 Savaş';

  @override
  String get youLabel => 'Sen';

  @override
  String get eloRankedMatch => 'ELO Dereceli Maç';

  @override
  String get findingOpponent => 'Rakip aranıyor...';

  @override
  String get matchingSimilarElo => 'Benzer ELO oyuncularıyla eşleştiriliyor';

  @override
  String get findMatchButton => 'RAKİP BUL';

  @override
  String get cancelSearch => 'İptal';

  @override
  String get noOpponentFoundYet => 'Henüz rakip bulunamadı';

  @override
  String get playWithBotInstead => 'Botla oyna';

  @override
  String get maxLevelBadge => 'Maksimum seviye';

  @override
  String get levelUpTitle => 'YENİ SEVİYE!';

  @override
  String levelUpSubtitle(int level) {
    return '$level. seviyeye ulaştınız!';
  }

  @override
  String get continueButton => 'DEVAM ET';

  @override
  String get levelTier1 => 'YENİ BAŞLAYAN';

  @override
  String get levelTier2 => 'DENEYİMLİ';

  @override
  String get levelTier3 => 'BİLGE';

  @override
  String get levelTier4 => 'USTA';

  @override
  String get levelTier5 => 'UZMAN';

  @override
  String get levelTier6 => 'ŞAMPİYON';

  @override
  String get levelTier7 => 'EFSANE';

  @override
  String get orContinueWith => 'VEYA';

  @override
  String get continueWithGoogle => 'Google ile devam et';

  @override
  String get continueWithApple => 'Apple ile devam et';

  @override
  String get continueWithFacebook => 'Facebook ile devam et';

  @override
  String get socialLoginFailed => 'Giriş başarısız. Tekrar deneyin.';

  @override
  String get coinBalanceTitle => 'Jeton Bakiyesi';

  @override
  String get xpBalanceTitle => 'XP Bakiyesi';

  @override
  String get goToShop => 'Mağazaya Git';

  @override
  String get closeAction => 'Kapat';

  @override
  String get notificationsTitle => 'Bildirimler';

  @override
  String get noNotifications => 'Henüz bildiriminiz yok';

  @override
  String get errorInvalidCredentials => 'Kullanıcı adı veya şifre yanlış';

  @override
  String get errorUserExists => 'Bu kullanıcı adı veya email zaten kayıtlı';

  @override
  String get errorNetwork =>
      'Sunucuya ulaşılamıyor. İnternet bağlantınızı kontrol edin';

  @override
  String get errorGeneric => 'Bir hata oluştu. Tekrar deneyin';

  @override
  String get confirmPasswordField => 'Şifreyi tekrarla';

  @override
  String get passwordsDoNotMatch => 'Şifreler eşleşmiyor';

  @override
  String get otpTitle => 'E-posta doğrulama';

  @override
  String otpSubtitle(String email) {
    return '$email adresine 6 haneli kod gönderdik';
  }

  @override
  String get otpInputHint => 'Doğrulama kodu';

  @override
  String get otpVerifyButton => 'DOĞRULA';

  @override
  String get otpResendButton => 'Kodu yeniden gönder';

  @override
  String get otpInvalid => 'Geçersiz veya süresi dolmuş kod';

  @override
  String get otpResent => 'Kod gönderildi';

  @override
  String get winsLabel => 'Galibiyet';

  @override
  String get lossesLabel => 'Mağlubiyet';

  @override
  String get winRateLabel => 'G. Oranı';

  @override
  String get leaderboardTitle => 'Sıralama';

  @override
  String get youInParens => '(Sen)';

  @override
  String winsText(int count) {
    return '$count galibiyet';
  }

  @override
  String get leaderboardEmpty => 'Henüz oyuncu yok';

  @override
  String get leaderboardEmptyHint => 'İlk olmak için oyna!';

  @override
  String get leaderboardError => 'Sıralama yüklenemedi';

  @override
  String scoreLabel(int score) {
    return 'Puan: $score';
  }

  @override
  String get quizComplete => 'Test Tamamlandı!';

  @override
  String earnedLabel(int xp, int coins) {
    return '+ $xp XP   + $coins Jeton';
  }

  @override
  String get doneButton => 'Tamam';

  @override
  String get friendsTitle => 'Arkadaşlar';

  @override
  String get addButton => 'Ekle';

  @override
  String get searchPlayersHint => 'Oyuncu ara...';

  @override
  String friendsTab(int count) {
    return 'Arkadaşlar ($count)';
  }

  @override
  String requestsTab(int count) {
    return 'İstekler ($count)';
  }

  @override
  String blockedTab(int count) {
    return 'Engellenenler ($count)';
  }

  @override
  String get onlineStatus => 'Çevrimiçi';

  @override
  String get offlineStatus => 'Çevrimdışı';

  @override
  String get challengeButton => 'Meydan Oku';

  @override
  String get addFriendTitle => 'Arkadaş Ekle';

  @override
  String get addFriendHint => 'Arkadaşının ID kodunu gir';

  @override
  String get addFriendButton => 'İstek Gönder';

  @override
  String get yourFriendCode => 'ID kodun';

  @override
  String get copyCodeAction => 'Kopyala';

  @override
  String get codeCopied => 'Kod kopyalandı';

  @override
  String get shareCodeHint => 'Bu kodu arkadaşlarınla paylaş';

  @override
  String get friendCodeFormatError => 'Kod 6 karakter olmalı';

  @override
  String get friendRequestSent => 'İstek gönderildi';

  @override
  String get friendRequestAccepted => 'İstek kabul edildi';

  @override
  String get friendRemoved => 'Arkadaş silindi';

  @override
  String get friendBlocked => 'Kullanıcı engellendi';

  @override
  String get friendUnblocked => 'Engel kaldırıldı';

  @override
  String get noFriendsYet => 'Henüz arkadaşın yok';

  @override
  String get noFriendsHint => 'Yukarıdaki düğme ile ID kodu gir';

  @override
  String get noRequestsYet => 'Yeni istek yok';

  @override
  String get noBlockedYet => 'Engelli oyuncu yok';

  @override
  String get incomingRequests => 'Gelen';

  @override
  String get outgoingRequests => 'Gönderdiklerim';

  @override
  String get errorAlreadyFriends => 'Zaten arkadaşsınız';

  @override
  String get errorAlreadyPending => 'İstek zaten gönderildi';

  @override
  String get errorBlocked => 'Bu kullanıcı sizi engellemiş';

  @override
  String get errorCannotFriendSelf => 'Kendine istek gönderemezsin';

  @override
  String get errorUserNotFound => 'Bu kod ile kullanıcı bulunamadı';

  @override
  String get errorInvalidCodeFormat => 'Geçersiz kod formatı';

  @override
  String get acceptAction => 'Kabul Et';

  @override
  String get declineAction => 'Reddet';

  @override
  String get removeFriendAction => 'Sil';

  @override
  String get blockAction => 'Engelle';

  @override
  String get unblockAction => 'Engeli Kaldır';

  @override
  String get messageAction => 'Mesaj';

  @override
  String get cancelAction => 'İptal';

  @override
  String get chatTitle => 'Sohbet';

  @override
  String get chatInputHint => 'Mesaj yaz...';

  @override
  String get chatSendButton => 'Gönder';

  @override
  String get chatPeerLeft => 'Karşı taraf ayrıldı';

  @override
  String get chatPeerTyping => 'yazıyor...';

  @override
  String get chatEphemeralNotice => 'Sohbeti kapattığında mesajlar silinir';

  @override
  String get chatNoMessages => 'Henüz mesaj yok';

  @override
  String get chatNotFriends => 'Sadece arkadaşlarla sohbet edebilirsin';

  @override
  String get shopTitle => 'Mağaza';

  @override
  String get coinPacksSection => 'JETON PAKETLERİ';

  @override
  String get powerUpsSection => 'GÜÇLENDİRİCİLER';

  @override
  String get specialOffer => 'ÖZEL TEKLİF';

  @override
  String get starterBundle => 'Başlangıç Paketi';

  @override
  String get starterBundleDesc => '5000 jeton + 50 taş + 3 joker';

  @override
  String get popularBadge => 'POPÜLER';

  @override
  String get starterPack => 'Başlangıç';

  @override
  String get popularPack => 'Popüler';

  @override
  String get proPack => 'Pro';

  @override
  String get elitePack => 'Elit';

  @override
  String coinsUnit(String amount) {
    return '$amount jeton';
  }

  @override
  String get fiftyFiftyLifeline => '50/50 Joker';

  @override
  String get extraTimePowerup => 'Ekstra Süre +10s';

  @override
  String get skipQuestionPowerup => 'Soruyu Geç';

  @override
  String get tournamentsTitle => 'Turnuvalar';

  @override
  String get tournamentSubtitle => 'Şan ve ödüller için yarış';

  @override
  String get allFilter => 'Tümü';

  @override
  String get liveFilter => 'Canlı';

  @override
  String get upcomingFilter => 'Yaklaşan';

  @override
  String get myEntriesFilter => 'Kayıtlarım';

  @override
  String get dailyChampionship => 'Günlük Şampiyonluk';

  @override
  String get weekendRoyale => 'Hafta Sonu Royale';

  @override
  String get speedQuizBlitz => 'Hızlı Quiz Blitz';

  @override
  String get knowledgeMasters => 'Bilgi Ustaları';

  @override
  String playersCount(int count) {
    return '$count oyuncu';
  }

  @override
  String coinsPrize(String amount) {
    return '${amount}k jeton ödülü';
  }

  @override
  String get liveBadge => 'CANLI';

  @override
  String get joinButton => 'Katıl';

  @override
  String get navHome => 'Ana Sayfa';

  @override
  String get navTournaments => 'Turnuvalar';

  @override
  String get navShop => 'Mağaza';

  @override
  String get navFriends => 'Arkadaşlar';

  @override
  String get navProfile => 'Profil';

  @override
  String get languageSelectorTitle => 'Dil Seçin';

  @override
  String get azerbaijani => 'Azərbaycan';

  @override
  String get russian => 'Русский';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'English';

  @override
  String get botBattle => 'Bota Karşı';

  @override
  String get botBattleSubtitle => 'AI ile yarış';

  @override
  String get soloPlay => 'Tek Oyna';

  @override
  String get soloSubtitle => 'Kendi başına antrenman yap';

  @override
  String get botLabel => 'BOT';

  @override
  String get botThinking => 'Bot düşünüyor...';

  @override
  String get botAnswered => 'Bot cevapladı';

  @override
  String get youWon => 'Kazandınız!';

  @override
  String get botWon => 'Bot Kazandı';

  @override
  String get opponentThinking => 'düşünüyor...';

  @override
  String get opponentAnswered => 'cevapladı';

  @override
  String get opponentWon => 'Rakip Kazandı';

  @override
  String get youLost => 'Kaybettiniz';

  @override
  String get drawResult => 'Beraberlik!';

  @override
  String get yourScore => 'Puanınız';

  @override
  String get botScore => 'Bot Puanı';

  @override
  String get playAgain => 'Tekrar Oyna';

  @override
  String get battleResult => 'Maç Sonucu';

  @override
  String xpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String coinsEarned(int coins) {
    return '+$coins Jeton';
  }

  @override
  String get usernameSetupTitle => 'Kullanıcı adı seçin';

  @override
  String get usernameSetupSubtitle =>
      'Diğerlerinin göreceği ad — daha sonra değiştirebilirsiniz';

  @override
  String get usernameSetupHint => 'Kullanıcı adı';

  @override
  String get usernameSetupContinue => 'DEVAM';

  @override
  String get usernameSetupErrorTaken => 'Bu ad zaten alınmış';

  @override
  String get usernameSetupErrorFormat => 'Sadece harf, rakam ve _';

  @override
  String get usernameSetupErrorMinLen => 'En az 3 karakter';

  @override
  String get usernameSetupSaveFailed => 'Kaydedilemedi';

  @override
  String get profileLoadFailed => 'Profil yüklenemedi';

  @override
  String get opponentDisconnectedMessage => 'Rakip bağlantıyı kesti';

  @override
  String get alreadyInMatchMessage => 'Zaten bir maçtasınız';

  @override
  String get connectionLostMessage => 'Bağlantı kesildi';

  @override
  String get battleStartingTitle => 'DÜELLO BAŞLIYOR';

  @override
  String get battleWord => 'DÜELLO!';

  @override
  String get sendFriendRequestLabel => 'Arkadaşlık gönder';

  @override
  String get friendRequestSentLabel => 'İstek gönderildi';

  @override
  String get matchHistoryEmpty => 'Henüz maç geçmişi yok';

  @override
  String get matchHistoryError => 'Geçmiş yüklenemedi';

  @override
  String get matchOutcomeWin => 'GALİP';

  @override
  String get matchOutcomeLoss => 'MAĞLUP';

  @override
  String get matchOutcomeDraw => 'BERABERE';

  @override
  String get matchOutcomeSolo => 'SOLO';

  @override
  String get matchType1v1 => '1v1';

  @override
  String get matchTypeTournament => 'Turnuva';

  @override
  String get matchTypeSolo => 'Solo';

  @override
  String get editProfileTitle => 'Profili Düzenle';

  @override
  String get chooseAvatar => 'Avatar seç';

  @override
  String get chooseFrame => 'Çerçeve';

  @override
  String get chooseColor => 'Renk';

  @override
  String get useInitialLetter => 'İlk harf';

  @override
  String get saveAction => 'Kaydet';

  @override
  String get profileUpdated => 'Profil güncellendi';

  @override
  String get editProfileTooltip => 'Profili düzenle';

  @override
  String get usernameAvailable => 'Kullanıcı adı uygun';

  @override
  String get signupOtpTitle => 'E-postayı doğrulayın';

  @override
  String get signupOtpSubtitle =>
      'E-posta adresinize gönderilen 6 haneli kodu girin';

  @override
  String get signupOtpVerify => 'DOĞRULA';

  @override
  String get signupOtpResend => 'Kodu tekrar gönder';

  @override
  String signupOtpResendIn(int seconds) {
    return '$seconds sn sonra tekrar gönder';
  }

  @override
  String get signupOtpInvalid => 'Kod geçersiz veya süresi dolmuş';

  @override
  String get signupOtpSent => 'Kod e-posta adresinize gönderildi';

  @override
  String get otpCodeLength => 'Tüm 6 rakamı girin';

  @override
  String get claimDeviceTitle => 'Bu cihazı bağla';

  @override
  String get claimDeviceSubtitle =>
      'Hesabınız başka bir cihazda aktif. Bu cihazı bağlamak için e-postaya gelen kodu girin.';

  @override
  String get claimDeviceContinue => 'BU CİHAZI BAĞLA';

  @override
  String get claimDeviceLogout => 'Çıkış yap';

  @override
  String get claimDeviceSuccess => 'Cihaz bağlandı';

  @override
  String get claimDeviceActiveLabel => 'Şu an aktif';
}
