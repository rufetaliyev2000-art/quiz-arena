// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Azerbaijani (`az`).
class AppLocalizationsAz extends AppLocalizations {
  AppLocalizationsAz([String locale = 'az']) : super(locale);

  @override
  String get tagline => 'BİL . OYNA . QAZAN';

  @override
  String get welcomeBack => 'Xoş gəldiniz!';

  @override
  String get usernameOrEmail => 'İstifadəçi adı və ya E-poçt';

  @override
  String get password => 'Şifrə';

  @override
  String get fieldRequired => 'Mütləqdir';

  @override
  String get minSixChars => 'Min 6 simvol';

  @override
  String get loginButton => 'GİRİŞ';

  @override
  String get dontHaveAccount => 'Hesabınız yoxdur? ';

  @override
  String get registerLink => 'Qeydiyyat';

  @override
  String get createAccountTitle => 'Hesab Yarat';

  @override
  String get joinBattleArena => 'Gguiz Battle döyüş arenasına qoşul';

  @override
  String get usernameField => 'İstifadəçi adı';

  @override
  String get minThreeChars => 'Min 3 simvol';

  @override
  String get usernameFormatError => 'Yalnız hərf, rəqəm və _';

  @override
  String get emailField => 'E-poçt';

  @override
  String get invalidEmail => 'Yanlış e-poçt';

  @override
  String get passwordWithMin => 'Şifrə (min 6 simvol)';

  @override
  String get createAccountButton => 'HESAB YARAT';

  @override
  String get alreadyHaveAccount => 'Artıq hesabınız var? ';

  @override
  String get loginLink => 'Daxil ol';

  @override
  String get daily => 'GÜNDƏLİK';

  @override
  String get tournament => 'TURNIR';

  @override
  String get winBigRewards => 'Böyük mükafatlar qazan!';

  @override
  String get startsIn => 'Başlayır';

  @override
  String get joinNow => 'İNDİ QOŞUL';

  @override
  String get playModes => 'OYUN REJİMLƏRİ';

  @override
  String get seeAll => 'Hamısı';

  @override
  String get quickBattle => 'Sürətli Döyüş';

  @override
  String get practice => 'Məşq';

  @override
  String get battleRoyaleTitle => 'DÖYÜŞ\nROYAL';

  @override
  String get lastOneWins => 'Son Qalan Qazanır';

  @override
  String get dailyMissions => 'GÜNDƏLİK MİSSİYALAR';

  @override
  String get mission1 => '3 matç oyna';

  @override
  String get mission2 => '1 matç qazan';

  @override
  String get mission3 => '10 sualı düzgün cavabla';

  @override
  String missionPlayMatch(int count) {
    return '$count matç oyna';
  }

  @override
  String missionWinMatch(int count) {
    return '$count matç qazan';
  }

  @override
  String missionAnswerCorrect(int count) {
    return '$count sualı düzgün cavabla';
  }

  @override
  String missionFastAnswer(int count) {
    return '5 saniyə ərzində $count düzgün cavab ver';
  }

  @override
  String missionWinStreak(int count) {
    return '$count ardıcıl qələbə qazan';
  }

  @override
  String missionRefreshIn(String time) {
    return 'Yenilənir: $time';
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
    return '+$coins sikkə';
  }

  @override
  String get leaderboard => 'Reytinq';

  @override
  String get view => 'Göstər';

  @override
  String get topPlayers => 'Ən Yaxşı Oyunçular';

  @override
  String get rankDiamond => 'Almaz';

  @override
  String get rankPlatinum => 'Platin';

  @override
  String get rankGoldII => 'Qızıl II';

  @override
  String get rankSilver => 'Gümüş';

  @override
  String get rankBronze => 'Tunc';

  @override
  String get levelLabel => 'Səviyyə';

  @override
  String get eloLabel => 'ELO';

  @override
  String get coinsLabel => 'Sikkə';

  @override
  String get totalWins => 'Cəmi Qələbə';

  @override
  String get losses => 'Məğlubiyyət';

  @override
  String get totalXP => 'Cəmi XP';

  @override
  String get winRate => 'Qazanma %';

  @override
  String get achievementsTitle => 'Nailiyyətlər';

  @override
  String get achievementFirstWin => 'İlk Qələbə';

  @override
  String get achievementTenWins => '10 Qələbə';

  @override
  String get achievementSpeedDemon => 'Sürət Devi';

  @override
  String get achievementFiftyWins => '50 Qələbə';

  @override
  String get recentMatchesTitle => 'Son Matçlar';

  @override
  String get matchHistorySoon => 'Matç tarixi tezliklə';

  @override
  String get settingsTitle => 'Parametrlər';

  @override
  String get notificationsLabel => 'Bildirişlər';

  @override
  String get languageLabel => 'Dil';

  @override
  String get privacyPolicyLabel => 'Gizlilik Siyasəti';

  @override
  String get logoutLabel => 'Çıxış';

  @override
  String errorMessage(String message) {
    return 'Xəta: $message';
  }

  @override
  String get oneVsOneBattle => '1v1 Döyüş';

  @override
  String get youLabel => 'Siz';

  @override
  String get eloRankedMatch => 'ELO Reytinq Matçı';

  @override
  String get findingOpponent => 'Rəqib axtarılır...';

  @override
  String get matchingSimilarElo => 'Oxşar ELO oyunçuları ilə uyğunlaşdırılır';

  @override
  String get findMatchButton => 'RƏQİB AXTAR';

  @override
  String get cancelSearch => 'Ləğv et';

  @override
  String get noOpponentFoundYet => 'Hələ rəqib tapılmır';

  @override
  String get playWithBotInstead => 'Bot ilə oyna';

  @override
  String get maxLevelBadge => 'Maks level';

  @override
  String get levelUpTitle => 'YENİ SƏVİYYƏ!';

  @override
  String levelUpSubtitle(int level) {
    return 'Səviyyə $level-ə yüksəldiniz!';
  }

  @override
  String get continueButton => 'DAVAM ET';

  @override
  String get levelTier1 => 'YENİ BAŞLAYAN';

  @override
  String get levelTier2 => 'TƏCRÜBƏLİ';

  @override
  String get levelTier3 => 'BİLİCİ';

  @override
  String get levelTier4 => 'USTA';

  @override
  String get levelTier5 => 'EKSPERT';

  @override
  String get levelTier6 => 'ÇEMPİON';

  @override
  String get levelTier7 => 'ƏFSANƏVİ';

  @override
  String get orContinueWith => 'VƏ YA';

  @override
  String get continueWithGoogle => 'Google ilə davam et';

  @override
  String get continueWithApple => 'Apple ilə davam et';

  @override
  String get continueWithFacebook => 'Facebook ilə davam et';

  @override
  String get socialLoginFailed => 'Giriş alınmadı. Yenidən cəhd edin.';

  @override
  String get coinBalanceTitle => 'Sikkə Balansı';

  @override
  String get xpBalanceTitle => 'XP Balansı';

  @override
  String get goToShop => 'Mağazaya keç';

  @override
  String get closeAction => 'Bağla';

  @override
  String get notificationsTitle => 'Bildirişlər';

  @override
  String get noNotifications => 'Hələ bildirişiniz yoxdur';

  @override
  String get errorInvalidCredentials => 'İstifadəçi adı və ya şifrə yanlışdır';

  @override
  String get errorUserExists =>
      'Bu istifadəçi adı və ya e-poçt artıq qeydiyyatdan keçib';

  @override
  String get errorNetwork =>
      'Server bağlantısı yoxdur. İnternet bağlantınızı yoxlayın';

  @override
  String get errorGeneric => 'Xəta baş verdi. Yenidən cəhd edin';

  @override
  String get confirmPasswordField => 'Şifrəni təkrar yaz';

  @override
  String get passwordsDoNotMatch => 'Şifrələr uyğun gəlmir';

  @override
  String get otpTitle => 'E-poçt təsdiqi';

  @override
  String otpSubtitle(String email) {
    return '$email ünvanına 6 rəqəmli kod göndərdik';
  }

  @override
  String get otpInputHint => 'Təsdiq kodu';

  @override
  String get otpVerifyButton => 'TƏSDİQ ET';

  @override
  String get otpResendButton => 'Kodu yenidən göndər';

  @override
  String get otpInvalid => 'Yanlış və ya köhnəlmiş kod';

  @override
  String get otpResent => 'Kod göndərildi';

  @override
  String get winsLabel => 'Qələbə';

  @override
  String get lossesLabel => 'Məğlubiyyət';

  @override
  String get winRateLabel => 'Q. Faizi';

  @override
  String get leaderboardTitle => 'Reytinq';

  @override
  String get youInParens => '(Siz)';

  @override
  String winsText(int count) {
    return '$count qələbə';
  }

  @override
  String get leaderboardEmpty => 'Hələ heç bir oyunçu yoxdur';

  @override
  String get leaderboardEmptyHint => 'Birinci olmaq üçün oyna!';

  @override
  String get leaderboardError => 'Reytinq yüklənmədi';

  @override
  String scoreLabel(int score) {
    return 'Xal: $score';
  }

  @override
  String get quizComplete => 'Test Tamamlandı!';

  @override
  String earnedLabel(int xp, int coins) {
    return '+ $xp XP   + $coins Sikkə';
  }

  @override
  String get doneButton => 'Hazır';

  @override
  String get friendsTitle => 'Dostlar';

  @override
  String get addButton => 'Əlavə et';

  @override
  String get searchPlayersHint => 'Oyunçu axtar...';

  @override
  String friendsTab(int count) {
    return 'Dostlar ($count)';
  }

  @override
  String requestsTab(int count) {
    return 'Sorğular ($count)';
  }

  @override
  String blockedTab(int count) {
    return 'Bloklananlar ($count)';
  }

  @override
  String get onlineStatus => 'Onlayn';

  @override
  String get offlineStatus => 'Oflayn';

  @override
  String get challengeButton => 'Çağırış';

  @override
  String get addFriendTitle => 'Dost Əlavə Et';

  @override
  String get addFriendHint => 'Dostunun ID kodunu daxil et';

  @override
  String get addFriendButton => 'Sorğu Göndər';

  @override
  String get yourFriendCode => 'Sənin ID kodun';

  @override
  String get copyCodeAction => 'Kopyala';

  @override
  String get codeCopied => 'Kod kopyalandı';

  @override
  String get shareCodeHint => 'Bu kodu dostlarınla paylaş';

  @override
  String get friendCodeFormatError => 'Kod 6 simvol olmalıdır';

  @override
  String get friendRequestSent => 'Sorğu göndərildi';

  @override
  String get friendRequestAccepted => 'Sorğu qəbul edildi';

  @override
  String get friendRemoved => 'Dost siyahıdan silindi';

  @override
  String get friendBlocked => 'İstifadəçi bloklandı';

  @override
  String get friendUnblocked => 'Blokdan çıxarıldı';

  @override
  String get noFriendsYet => 'Hələ dostun yoxdur';

  @override
  String get noFriendsHint => 'Yuxarıdakı düymə ilə ID kodu daxil et';

  @override
  String get noRequestsYet => 'Yeni sorğu yoxdur';

  @override
  String get noBlockedYet => 'Bloklanmış oyunçu yoxdur';

  @override
  String get incomingRequests => 'Mənə gələn';

  @override
  String get outgoingRequests => 'Mənim göndərdiyim';

  @override
  String get errorAlreadyFriends => 'Artıq dostsunuz';

  @override
  String get errorAlreadyPending => 'Sorğu artıq göndərilib';

  @override
  String get errorBlocked => 'Bu istifadəçi sizi bloklayıb';

  @override
  String get errorCannotFriendSelf => 'Özünə sorğu göndərə bilməzsən';

  @override
  String get errorUserNotFound => 'Bu kodla istifadəçi tapılmadı';

  @override
  String get errorInvalidCodeFormat => 'Yanlış kod formatı';

  @override
  String get acceptAction => 'Qəbul et';

  @override
  String get declineAction => 'Rədd et';

  @override
  String get removeFriendAction => 'Sil';

  @override
  String get blockAction => 'Bloklа';

  @override
  String get unblockAction => 'Blokdan çıxar';

  @override
  String get messageAction => 'Mesaj';

  @override
  String get cancelAction => 'Ləğv et';

  @override
  String get chatTitle => 'Mesajlaşma';

  @override
  String get chatInputHint => 'Mesaj yaz...';

  @override
  String get chatSendButton => 'Göndər';

  @override
  String get chatPeerLeft => 'Söhbətdaş ayrıldı';

  @override
  String get chatPeerTyping => 'yazır...';

  @override
  String get chatEphemeralNotice => 'Mesajlar yazışmanı bağladıqda silinir';

  @override
  String get chatNoMessages => 'Hələ heç bir mesaj yoxdur';

  @override
  String get chatNotFriends => 'Yalnız dostlarla mesajlaşa bilərsən';

  @override
  String get shopTitle => 'Mağaza';

  @override
  String get coinPacksSection => 'SİKKƏ PAKETLƏRİ';

  @override
  String get powerUpsSection => 'GÜCLƏNDİRİCİLƏR';

  @override
  String get specialOffer => 'XÜSUSİ TƏKLİF';

  @override
  String get starterBundle => 'Başlanğıc Paketi';

  @override
  String get starterBundleDesc => '5000 sikkə + 50 daş + 3 ipucu';

  @override
  String get popularBadge => 'MƏŞHUR';

  @override
  String get starterPack => 'Başlanğıc';

  @override
  String get popularPack => 'Məşhur';

  @override
  String get proPack => 'Pro';

  @override
  String get elitePack => 'Elit';

  @override
  String coinsUnit(String amount) {
    return '$amount sikkə';
  }

  @override
  String get fiftyFiftyLifeline => '50/50 İpucu';

  @override
  String get extraTimePowerup => 'Əlavə Vaxt +10s';

  @override
  String get skipQuestionPowerup => 'Sualı Keç';

  @override
  String get tournamentsTitle => 'Turnirlər';

  @override
  String get tournamentSubtitle => 'Şöhrət və mükafatlar üçün yarış';

  @override
  String get allFilter => 'Hamısı';

  @override
  String get liveFilter => 'Canlı';

  @override
  String get upcomingFilter => 'Gələcək';

  @override
  String get myEntriesFilter => 'Qeydiyyatlarım';

  @override
  String get dailyChampionship => 'Günlük Çempionat';

  @override
  String get weekendRoyale => 'Həftəsonu Royal';

  @override
  String get speedQuizBlitz => 'Sürətli Bilik Blitzi';

  @override
  String get knowledgeMasters => 'Bilik Ustadları';

  @override
  String playersCount(int count) {
    return '$count oyunçu';
  }

  @override
  String coinsPrize(String amount) {
    return '${amount}k sikkə mükafatı';
  }

  @override
  String get liveBadge => 'CANLI';

  @override
  String get joinButton => 'Qoşul';

  @override
  String get navHome => 'Ana Səhifə';

  @override
  String get navTournaments => 'Turnirlər';

  @override
  String get navShop => 'Mağaza';

  @override
  String get navFriends => 'Dostlar';

  @override
  String get navProfile => 'Profil';

  @override
  String get languageSelectorTitle => 'Dil seçin';

  @override
  String get azerbaijani => 'Azərbaycan';

  @override
  String get russian => 'Русский';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'English';

  @override
  String get botBattle => 'Bota Qarşı';

  @override
  String get botBattleSubtitle => 'AI ilə yarış';

  @override
  String get soloPlay => 'Tək Oyna';

  @override
  String get soloSubtitle => 'Öz başına məşq et';

  @override
  String get botLabel => 'BOT';

  @override
  String get botThinking => 'Bot düşünür...';

  @override
  String get botAnswered => 'Bot cavabladı';

  @override
  String get youWon => 'Siz Qazandınız!';

  @override
  String get botWon => 'Bot Qazandı';

  @override
  String get opponentThinking => 'düşünür...';

  @override
  String get opponentAnswered => 'cavabladı';

  @override
  String get opponentWon => 'Rəqib Qazandı';

  @override
  String get youLost => 'Siz Uduzdunuz';

  @override
  String get drawResult => 'Bərabərlik!';

  @override
  String get yourScore => 'Sizin Xal';

  @override
  String get botScore => 'Bot Xalı';

  @override
  String get playAgain => 'Yenidən Oyna';

  @override
  String get battleResult => 'Matç Nəticəsi';

  @override
  String xpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String coinsEarned(int coins) {
    return '+$coins Sikkə';
  }

  @override
  String get usernameSetupTitle => 'İstifadəçi adı seç';

  @override
  String get usernameSetupSubtitle =>
      'Sizi tanıyacağımız ad — sonra dəyişə bilərsiniz';

  @override
  String get usernameSetupHint => 'İstifadəçi adı';

  @override
  String get usernameSetupContinue => 'DAVAM ET';

  @override
  String get usernameSetupErrorTaken => 'Bu ad artıq tutulub';

  @override
  String get usernameSetupErrorFormat => 'Yalnız hərf, rəqəm və _';

  @override
  String get usernameSetupErrorMinLen => 'Min 3 simvol';

  @override
  String get usernameSetupSaveFailed => 'Yadda saxlamaq alınmadı';

  @override
  String get profileLoadFailed => 'Profil yüklənmədi';

  @override
  String get opponentDisconnectedMessage => 'Rəqib bağlantını kəsdi';

  @override
  String get alreadyInMatchMessage => 'Artıq bir matçdasınız';

  @override
  String get connectionLostMessage => 'Bağlantı kəsildi';

  @override
  String get battleStartingTitle => 'DÖYÜŞ BAŞLAYIR';

  @override
  String get battleWord => 'DÖYÜŞ!';

  @override
  String get sendFriendRequestLabel => 'Dostluq göndər';

  @override
  String get friendRequestSentLabel => 'Sorğu göndərildi';

  @override
  String get matchHistoryEmpty => 'Hələ matç tarixçəsi yoxdur';

  @override
  String get matchHistoryError => 'Tarixçə yüklənmədi';

  @override
  String get matchOutcomeWin => 'QALİB';

  @override
  String get matchOutcomeLoss => 'MƏĞLUB';

  @override
  String get matchOutcomeDraw => 'HEÇ-HEÇƏ';

  @override
  String get matchOutcomeSolo => 'SOLO';

  @override
  String get matchType1v1 => '1v1';

  @override
  String get matchTypeTournament => 'Turnir';

  @override
  String get matchTypeSolo => 'Solo';

  @override
  String get editProfileTitle => 'Profili Düzəlt';

  @override
  String get chooseAvatar => 'Avatar seç';

  @override
  String get chooseFrame => 'Çərçivə';

  @override
  String get chooseColor => 'Rəng';

  @override
  String get useInitialLetter => 'İlk hərf';

  @override
  String get saveAction => 'Yadda saxla';

  @override
  String get profileUpdated => 'Profil yeniləndi';

  @override
  String get editProfileTooltip => 'Profili düzəlt';

  @override
  String get usernameAvailable => 'Ad uyğundur';

  @override
  String get signupOtpTitle => 'Email-i təsdiqlə';

  @override
  String get signupOtpSubtitle =>
      'Email ünvanınıza göndərilən 6-rəqəmli kodu daxil edin';

  @override
  String get signupOtpVerify => 'TƏSDİQLƏ';

  @override
  String get signupOtpResend => 'Kodu yenidən göndər';

  @override
  String signupOtpResendIn(int seconds) {
    return '$seconds san sonra yenidən göndər';
  }

  @override
  String get signupOtpInvalid => 'Kod yanlışdır və ya vaxtı keçib';

  @override
  String get signupOtpSent => 'Kod email ünvanınıza göndərildi';

  @override
  String get otpCodeLength => 'Tam 6 rəqəm tələb olunur';

  @override
  String get claimDeviceTitle => 'Yeni cihaz qeyd et';

  @override
  String get claimDeviceSubtitle =>
      'Hesabınız başqa cihazda aktivdir. Bu cihazı qeyd etmək üçün email-ə göndərilən kodu daxil edin.';

  @override
  String get claimDeviceContinue => 'BU CİHAZI QEYD ET';

  @override
  String get claimDeviceLogout => 'Çıxış et';

  @override
  String get claimDeviceSuccess => 'Cihaz uğurla qeyd olundu';

  @override
  String get claimDeviceActiveLabel => 'Hazırda aktiv';
}
