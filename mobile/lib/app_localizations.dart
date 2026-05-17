import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_az.dart';
import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'lib/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('az'),
    Locale('en'),
    Locale('ru'),
    Locale('tr'),
  ];

  /// No description provided for @tagline.
  ///
  /// In az, this message translates to:
  /// **'BİL . OYNA . QAZAN'**
  String get tagline;

  /// No description provided for @welcomeBack.
  ///
  /// In az, this message translates to:
  /// **'Xoş gəldiniz!'**
  String get welcomeBack;

  /// No description provided for @usernameOrEmail.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi adı və ya E-poçt'**
  String get usernameOrEmail;

  /// No description provided for @password.
  ///
  /// In az, this message translates to:
  /// **'Şifrə'**
  String get password;

  /// No description provided for @fieldRequired.
  ///
  /// In az, this message translates to:
  /// **'Mütləqdir'**
  String get fieldRequired;

  /// No description provided for @minSixChars.
  ///
  /// In az, this message translates to:
  /// **'Min 6 simvol'**
  String get minSixChars;

  /// No description provided for @loginButton.
  ///
  /// In az, this message translates to:
  /// **'GİRİŞ'**
  String get loginButton;

  /// No description provided for @dontHaveAccount.
  ///
  /// In az, this message translates to:
  /// **'Hesabınız yoxdur? '**
  String get dontHaveAccount;

  /// No description provided for @registerLink.
  ///
  /// In az, this message translates to:
  /// **'Qeydiyyat'**
  String get registerLink;

  /// No description provided for @createAccountTitle.
  ///
  /// In az, this message translates to:
  /// **'Hesab Yarat'**
  String get createAccountTitle;

  /// No description provided for @joinBattleArena.
  ///
  /// In az, this message translates to:
  /// **'Gguiz Battle döyüş arenasına qoşul'**
  String get joinBattleArena;

  /// No description provided for @usernameField.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi adı'**
  String get usernameField;

  /// No description provided for @minThreeChars.
  ///
  /// In az, this message translates to:
  /// **'Min 3 simvol'**
  String get minThreeChars;

  /// No description provided for @usernameFormatError.
  ///
  /// In az, this message translates to:
  /// **'Yalnız hərf, rəqəm və _'**
  String get usernameFormatError;

  /// No description provided for @emailField.
  ///
  /// In az, this message translates to:
  /// **'E-poçt'**
  String get emailField;

  /// No description provided for @invalidEmail.
  ///
  /// In az, this message translates to:
  /// **'Yanlış e-poçt'**
  String get invalidEmail;

  /// No description provided for @passwordWithMin.
  ///
  /// In az, this message translates to:
  /// **'Şifrə (min 6 simvol)'**
  String get passwordWithMin;

  /// No description provided for @createAccountButton.
  ///
  /// In az, this message translates to:
  /// **'HESAB YARAT'**
  String get createAccountButton;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In az, this message translates to:
  /// **'Artıq hesabınız var? '**
  String get alreadyHaveAccount;

  /// No description provided for @loginLink.
  ///
  /// In az, this message translates to:
  /// **'Daxil ol'**
  String get loginLink;

  /// No description provided for @daily.
  ///
  /// In az, this message translates to:
  /// **'GÜNDƏLİK'**
  String get daily;

  /// No description provided for @tournament.
  ///
  /// In az, this message translates to:
  /// **'TURNIR'**
  String get tournament;

  /// No description provided for @winBigRewards.
  ///
  /// In az, this message translates to:
  /// **'Böyük mükafatlar qazan!'**
  String get winBigRewards;

  /// No description provided for @startsIn.
  ///
  /// In az, this message translates to:
  /// **'Başlayır'**
  String get startsIn;

  /// No description provided for @joinNow.
  ///
  /// In az, this message translates to:
  /// **'İNDİ QOŞUL'**
  String get joinNow;

  /// No description provided for @playModes.
  ///
  /// In az, this message translates to:
  /// **'OYUN REJİMLƏRİ'**
  String get playModes;

  /// No description provided for @seeAll.
  ///
  /// In az, this message translates to:
  /// **'Hamısı'**
  String get seeAll;

  /// No description provided for @quickBattle.
  ///
  /// In az, this message translates to:
  /// **'Sürətli Döyüş'**
  String get quickBattle;

  /// No description provided for @practice.
  ///
  /// In az, this message translates to:
  /// **'Məşq'**
  String get practice;

  /// No description provided for @battleRoyaleTitle.
  ///
  /// In az, this message translates to:
  /// **'DÖYÜŞ\nROYAL'**
  String get battleRoyaleTitle;

  /// No description provided for @lastOneWins.
  ///
  /// In az, this message translates to:
  /// **'Son Qalan Qazanır'**
  String get lastOneWins;

  /// No description provided for @dailyMissions.
  ///
  /// In az, this message translates to:
  /// **'GÜNDƏLİK MİSSİYALAR'**
  String get dailyMissions;

  /// No description provided for @mission1.
  ///
  /// In az, this message translates to:
  /// **'3 matç oyna'**
  String get mission1;

  /// No description provided for @mission2.
  ///
  /// In az, this message translates to:
  /// **'1 matç qazan'**
  String get mission2;

  /// No description provided for @mission3.
  ///
  /// In az, this message translates to:
  /// **'10 sualı düzgün cavabla'**
  String get mission3;

  /// No description provided for @missionPlayMatch.
  ///
  /// In az, this message translates to:
  /// **'{count} matç oyna'**
  String missionPlayMatch(int count);

  /// No description provided for @missionWinMatch.
  ///
  /// In az, this message translates to:
  /// **'{count} matç qazan'**
  String missionWinMatch(int count);

  /// No description provided for @missionAnswerCorrect.
  ///
  /// In az, this message translates to:
  /// **'{count} sualı düzgün cavabla'**
  String missionAnswerCorrect(int count);

  /// No description provided for @missionFastAnswer.
  ///
  /// In az, this message translates to:
  /// **'5 saniyə ərzində {count} düzgün cavab ver'**
  String missionFastAnswer(int count);

  /// No description provided for @missionWinStreak.
  ///
  /// In az, this message translates to:
  /// **'{count} ardıcıl qələbə qazan'**
  String missionWinStreak(int count);

  /// No description provided for @missionRefreshIn.
  ///
  /// In az, this message translates to:
  /// **'Yenilənir: {time}'**
  String missionRefreshIn(String time);

  /// No description provided for @missionClaim.
  ///
  /// In az, this message translates to:
  /// **'Al'**
  String get missionClaim;

  /// No description provided for @missionClaimed.
  ///
  /// In az, this message translates to:
  /// **'Alındı'**
  String get missionClaimed;

  /// No description provided for @missionRewardXp.
  ///
  /// In az, this message translates to:
  /// **'+{xp} XP'**
  String missionRewardXp(int xp);

  /// No description provided for @missionRewardCoins.
  ///
  /// In az, this message translates to:
  /// **'+{coins} sikkə'**
  String missionRewardCoins(int coins);

  /// No description provided for @leaderboard.
  ///
  /// In az, this message translates to:
  /// **'Reytinq'**
  String get leaderboard;

  /// No description provided for @view.
  ///
  /// In az, this message translates to:
  /// **'Göstər'**
  String get view;

  /// No description provided for @topPlayers.
  ///
  /// In az, this message translates to:
  /// **'Ən Yaxşı Oyunçular'**
  String get topPlayers;

  /// No description provided for @rankDiamond.
  ///
  /// In az, this message translates to:
  /// **'Almaz'**
  String get rankDiamond;

  /// No description provided for @rankPlatinum.
  ///
  /// In az, this message translates to:
  /// **'Platin'**
  String get rankPlatinum;

  /// No description provided for @rankGoldII.
  ///
  /// In az, this message translates to:
  /// **'Qızıl II'**
  String get rankGoldII;

  /// No description provided for @rankSilver.
  ///
  /// In az, this message translates to:
  /// **'Gümüş'**
  String get rankSilver;

  /// No description provided for @rankBronze.
  ///
  /// In az, this message translates to:
  /// **'Tunc'**
  String get rankBronze;

  /// No description provided for @levelLabel.
  ///
  /// In az, this message translates to:
  /// **'Səviyyə'**
  String get levelLabel;

  /// No description provided for @eloLabel.
  ///
  /// In az, this message translates to:
  /// **'ELO'**
  String get eloLabel;

  /// No description provided for @coinsLabel.
  ///
  /// In az, this message translates to:
  /// **'Sikkə'**
  String get coinsLabel;

  /// No description provided for @totalWins.
  ///
  /// In az, this message translates to:
  /// **'Cəmi Qələbə'**
  String get totalWins;

  /// No description provided for @losses.
  ///
  /// In az, this message translates to:
  /// **'Məğlubiyyət'**
  String get losses;

  /// No description provided for @totalXP.
  ///
  /// In az, this message translates to:
  /// **'Cəmi XP'**
  String get totalXP;

  /// No description provided for @winRate.
  ///
  /// In az, this message translates to:
  /// **'Qazanma %'**
  String get winRate;

  /// No description provided for @achievementsTitle.
  ///
  /// In az, this message translates to:
  /// **'Nailiyyətlər'**
  String get achievementsTitle;

  /// No description provided for @achievementFirstWin.
  ///
  /// In az, this message translates to:
  /// **'İlk Qələbə'**
  String get achievementFirstWin;

  /// No description provided for @achievementTenWins.
  ///
  /// In az, this message translates to:
  /// **'10 Qələbə'**
  String get achievementTenWins;

  /// No description provided for @achievementSpeedDemon.
  ///
  /// In az, this message translates to:
  /// **'Sürət Devi'**
  String get achievementSpeedDemon;

  /// No description provided for @achievementFiftyWins.
  ///
  /// In az, this message translates to:
  /// **'50 Qələbə'**
  String get achievementFiftyWins;

  /// No description provided for @recentMatchesTitle.
  ///
  /// In az, this message translates to:
  /// **'Son Matçlar'**
  String get recentMatchesTitle;

  /// No description provided for @matchHistorySoon.
  ///
  /// In az, this message translates to:
  /// **'Matç tarixi tezliklə'**
  String get matchHistorySoon;

  /// No description provided for @settingsTitle.
  ///
  /// In az, this message translates to:
  /// **'Parametrlər'**
  String get settingsTitle;

  /// No description provided for @notificationsLabel.
  ///
  /// In az, this message translates to:
  /// **'Bildirişlər'**
  String get notificationsLabel;

  /// No description provided for @languageLabel.
  ///
  /// In az, this message translates to:
  /// **'Dil'**
  String get languageLabel;

  /// No description provided for @privacyPolicyLabel.
  ///
  /// In az, this message translates to:
  /// **'Gizlilik Siyasəti'**
  String get privacyPolicyLabel;

  /// No description provided for @logoutLabel.
  ///
  /// In az, this message translates to:
  /// **'Çıxış'**
  String get logoutLabel;

  /// No description provided for @errorMessage.
  ///
  /// In az, this message translates to:
  /// **'Xəta: {message}'**
  String errorMessage(String message);

  /// No description provided for @oneVsOneBattle.
  ///
  /// In az, this message translates to:
  /// **'1v1 Döyüş'**
  String get oneVsOneBattle;

  /// No description provided for @youLabel.
  ///
  /// In az, this message translates to:
  /// **'Siz'**
  String get youLabel;

  /// No description provided for @eloRankedMatch.
  ///
  /// In az, this message translates to:
  /// **'ELO Reytinq Matçı'**
  String get eloRankedMatch;

  /// No description provided for @findingOpponent.
  ///
  /// In az, this message translates to:
  /// **'Rəqib axtarılır...'**
  String get findingOpponent;

  /// No description provided for @matchingSimilarElo.
  ///
  /// In az, this message translates to:
  /// **'Oxşar ELO oyunçuları ilə uyğunlaşdırılır'**
  String get matchingSimilarElo;

  /// No description provided for @findMatchButton.
  ///
  /// In az, this message translates to:
  /// **'RƏQİB AXTAR'**
  String get findMatchButton;

  /// No description provided for @cancelSearch.
  ///
  /// In az, this message translates to:
  /// **'Ləğv et'**
  String get cancelSearch;

  /// No description provided for @noOpponentFoundYet.
  ///
  /// In az, this message translates to:
  /// **'Hələ rəqib tapılmır'**
  String get noOpponentFoundYet;

  /// No description provided for @playWithBotInstead.
  ///
  /// In az, this message translates to:
  /// **'Bot ilə oyna'**
  String get playWithBotInstead;

  /// No description provided for @maxLevelBadge.
  ///
  /// In az, this message translates to:
  /// **'Maks level'**
  String get maxLevelBadge;

  /// No description provided for @levelUpTitle.
  ///
  /// In az, this message translates to:
  /// **'YENİ SƏVİYYƏ!'**
  String get levelUpTitle;

  /// No description provided for @levelUpSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Səviyyə {level}-ə yüksəldiniz!'**
  String levelUpSubtitle(int level);

  /// No description provided for @continueButton.
  ///
  /// In az, this message translates to:
  /// **'DAVAM ET'**
  String get continueButton;

  /// No description provided for @levelTier1.
  ///
  /// In az, this message translates to:
  /// **'YENİ BAŞLAYAN'**
  String get levelTier1;

  /// No description provided for @levelTier2.
  ///
  /// In az, this message translates to:
  /// **'TƏCRÜBƏLİ'**
  String get levelTier2;

  /// No description provided for @levelTier3.
  ///
  /// In az, this message translates to:
  /// **'BİLİCİ'**
  String get levelTier3;

  /// No description provided for @levelTier4.
  ///
  /// In az, this message translates to:
  /// **'USTA'**
  String get levelTier4;

  /// No description provided for @levelTier5.
  ///
  /// In az, this message translates to:
  /// **'EKSPERT'**
  String get levelTier5;

  /// No description provided for @levelTier6.
  ///
  /// In az, this message translates to:
  /// **'ÇEMPİON'**
  String get levelTier6;

  /// No description provided for @levelTier7.
  ///
  /// In az, this message translates to:
  /// **'ƏFSANƏVİ'**
  String get levelTier7;

  /// No description provided for @orContinueWith.
  ///
  /// In az, this message translates to:
  /// **'VƏ YA'**
  String get orContinueWith;

  /// No description provided for @continueWithGoogle.
  ///
  /// In az, this message translates to:
  /// **'Google ilə davam et'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In az, this message translates to:
  /// **'Apple ilə davam et'**
  String get continueWithApple;

  /// No description provided for @continueWithFacebook.
  ///
  /// In az, this message translates to:
  /// **'Facebook ilə davam et'**
  String get continueWithFacebook;

  /// No description provided for @socialLoginFailed.
  ///
  /// In az, this message translates to:
  /// **'Giriş alınmadı. Yenidən cəhd edin.'**
  String get socialLoginFailed;

  /// No description provided for @coinBalanceTitle.
  ///
  /// In az, this message translates to:
  /// **'Sikkə Balansı'**
  String get coinBalanceTitle;

  /// No description provided for @xpBalanceTitle.
  ///
  /// In az, this message translates to:
  /// **'XP Balansı'**
  String get xpBalanceTitle;

  /// No description provided for @goToShop.
  ///
  /// In az, this message translates to:
  /// **'Mağazaya keç'**
  String get goToShop;

  /// No description provided for @closeAction.
  ///
  /// In az, this message translates to:
  /// **'Bağla'**
  String get closeAction;

  /// No description provided for @notificationsTitle.
  ///
  /// In az, this message translates to:
  /// **'Bildirişlər'**
  String get notificationsTitle;

  /// No description provided for @noNotifications.
  ///
  /// In az, this message translates to:
  /// **'Hələ bildirişiniz yoxdur'**
  String get noNotifications;

  /// No description provided for @errorInvalidCredentials.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi adı və ya şifrə yanlışdır'**
  String get errorInvalidCredentials;

  /// No description provided for @errorUserExists.
  ///
  /// In az, this message translates to:
  /// **'Bu istifadəçi adı və ya e-poçt artıq qeydiyyatdan keçib'**
  String get errorUserExists;

  /// No description provided for @errorNetwork.
  ///
  /// In az, this message translates to:
  /// **'Server bağlantısı yoxdur. İnternet bağlantınızı yoxlayın'**
  String get errorNetwork;

  /// No description provided for @errorGeneric.
  ///
  /// In az, this message translates to:
  /// **'Xəta baş verdi. Yenidən cəhd edin'**
  String get errorGeneric;

  /// No description provided for @confirmPasswordField.
  ///
  /// In az, this message translates to:
  /// **'Şifrəni təkrar yaz'**
  String get confirmPasswordField;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In az, this message translates to:
  /// **'Şifrələr uyğun gəlmir'**
  String get passwordsDoNotMatch;

  /// No description provided for @otpTitle.
  ///
  /// In az, this message translates to:
  /// **'E-poçt təsdiqi'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In az, this message translates to:
  /// **'{email} ünvanına 6 rəqəmli kod göndərdik'**
  String otpSubtitle(String email);

  /// No description provided for @otpInputHint.
  ///
  /// In az, this message translates to:
  /// **'Təsdiq kodu'**
  String get otpInputHint;

  /// No description provided for @otpVerifyButton.
  ///
  /// In az, this message translates to:
  /// **'TƏSDİQ ET'**
  String get otpVerifyButton;

  /// No description provided for @otpResendButton.
  ///
  /// In az, this message translates to:
  /// **'Kodu yenidən göndər'**
  String get otpResendButton;

  /// No description provided for @otpInvalid.
  ///
  /// In az, this message translates to:
  /// **'Yanlış və ya köhnəlmiş kod'**
  String get otpInvalid;

  /// No description provided for @otpResent.
  ///
  /// In az, this message translates to:
  /// **'Kod göndərildi'**
  String get otpResent;

  /// No description provided for @winsLabel.
  ///
  /// In az, this message translates to:
  /// **'Qələbə'**
  String get winsLabel;

  /// No description provided for @lossesLabel.
  ///
  /// In az, this message translates to:
  /// **'Məğlubiyyət'**
  String get lossesLabel;

  /// No description provided for @winRateLabel.
  ///
  /// In az, this message translates to:
  /// **'Q. Faizi'**
  String get winRateLabel;

  /// No description provided for @leaderboardTitle.
  ///
  /// In az, this message translates to:
  /// **'Reytinq'**
  String get leaderboardTitle;

  /// No description provided for @youInParens.
  ///
  /// In az, this message translates to:
  /// **'(Siz)'**
  String get youInParens;

  /// No description provided for @winsText.
  ///
  /// In az, this message translates to:
  /// **'{count} qələbə'**
  String winsText(int count);

  /// No description provided for @leaderboardEmpty.
  ///
  /// In az, this message translates to:
  /// **'Hələ heç bir oyunçu yoxdur'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardEmptyHint.
  ///
  /// In az, this message translates to:
  /// **'Birinci olmaq üçün oyna!'**
  String get leaderboardEmptyHint;

  /// No description provided for @leaderboardError.
  ///
  /// In az, this message translates to:
  /// **'Reytinq yüklənmədi'**
  String get leaderboardError;

  /// No description provided for @scoreLabel.
  ///
  /// In az, this message translates to:
  /// **'Xal: {score}'**
  String scoreLabel(int score);

  /// No description provided for @quizComplete.
  ///
  /// In az, this message translates to:
  /// **'Test Tamamlandı!'**
  String get quizComplete;

  /// No description provided for @earnedLabel.
  ///
  /// In az, this message translates to:
  /// **'+ {xp} XP   + {coins} Sikkə'**
  String earnedLabel(int xp, int coins);

  /// No description provided for @doneButton.
  ///
  /// In az, this message translates to:
  /// **'Hazır'**
  String get doneButton;

  /// No description provided for @friendsTitle.
  ///
  /// In az, this message translates to:
  /// **'Dostlar'**
  String get friendsTitle;

  /// No description provided for @addButton.
  ///
  /// In az, this message translates to:
  /// **'Əlavə et'**
  String get addButton;

  /// No description provided for @searchPlayersHint.
  ///
  /// In az, this message translates to:
  /// **'Oyunçu axtar...'**
  String get searchPlayersHint;

  /// No description provided for @friendsTab.
  ///
  /// In az, this message translates to:
  /// **'Dostlar ({count})'**
  String friendsTab(int count);

  /// No description provided for @requestsTab.
  ///
  /// In az, this message translates to:
  /// **'Sorğular ({count})'**
  String requestsTab(int count);

  /// No description provided for @blockedTab.
  ///
  /// In az, this message translates to:
  /// **'Bloklananlar ({count})'**
  String blockedTab(int count);

  /// No description provided for @onlineStatus.
  ///
  /// In az, this message translates to:
  /// **'Onlayn'**
  String get onlineStatus;

  /// No description provided for @offlineStatus.
  ///
  /// In az, this message translates to:
  /// **'Oflayn'**
  String get offlineStatus;

  /// No description provided for @challengeButton.
  ///
  /// In az, this message translates to:
  /// **'Çağırış'**
  String get challengeButton;

  /// No description provided for @addFriendTitle.
  ///
  /// In az, this message translates to:
  /// **'Dost Əlavə Et'**
  String get addFriendTitle;

  /// No description provided for @addFriendHint.
  ///
  /// In az, this message translates to:
  /// **'Dostunun ID kodunu daxil et'**
  String get addFriendHint;

  /// No description provided for @addFriendButton.
  ///
  /// In az, this message translates to:
  /// **'Sorğu Göndər'**
  String get addFriendButton;

  /// No description provided for @yourFriendCode.
  ///
  /// In az, this message translates to:
  /// **'Sənin ID kodun'**
  String get yourFriendCode;

  /// No description provided for @copyCodeAction.
  ///
  /// In az, this message translates to:
  /// **'Kopyala'**
  String get copyCodeAction;

  /// No description provided for @codeCopied.
  ///
  /// In az, this message translates to:
  /// **'Kod kopyalandı'**
  String get codeCopied;

  /// No description provided for @shareCodeHint.
  ///
  /// In az, this message translates to:
  /// **'Bu kodu dostlarınla paylaş'**
  String get shareCodeHint;

  /// No description provided for @friendCodeFormatError.
  ///
  /// In az, this message translates to:
  /// **'Kod 6 simvol olmalıdır'**
  String get friendCodeFormatError;

  /// No description provided for @friendRequestSent.
  ///
  /// In az, this message translates to:
  /// **'Sorğu göndərildi'**
  String get friendRequestSent;

  /// No description provided for @friendRequestAccepted.
  ///
  /// In az, this message translates to:
  /// **'Sorğu qəbul edildi'**
  String get friendRequestAccepted;

  /// No description provided for @friendRemoved.
  ///
  /// In az, this message translates to:
  /// **'Dost siyahıdan silindi'**
  String get friendRemoved;

  /// No description provided for @friendBlocked.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi bloklandı'**
  String get friendBlocked;

  /// No description provided for @friendUnblocked.
  ///
  /// In az, this message translates to:
  /// **'Blokdan çıxarıldı'**
  String get friendUnblocked;

  /// No description provided for @noFriendsYet.
  ///
  /// In az, this message translates to:
  /// **'Hələ dostun yoxdur'**
  String get noFriendsYet;

  /// No description provided for @noFriendsHint.
  ///
  /// In az, this message translates to:
  /// **'Yuxarıdakı düymə ilə ID kodu daxil et'**
  String get noFriendsHint;

  /// No description provided for @noRequestsYet.
  ///
  /// In az, this message translates to:
  /// **'Yeni sorğu yoxdur'**
  String get noRequestsYet;

  /// No description provided for @noBlockedYet.
  ///
  /// In az, this message translates to:
  /// **'Bloklanmış oyunçu yoxdur'**
  String get noBlockedYet;

  /// No description provided for @incomingRequests.
  ///
  /// In az, this message translates to:
  /// **'Mənə gələn'**
  String get incomingRequests;

  /// No description provided for @outgoingRequests.
  ///
  /// In az, this message translates to:
  /// **'Mənim göndərdiyim'**
  String get outgoingRequests;

  /// No description provided for @errorAlreadyFriends.
  ///
  /// In az, this message translates to:
  /// **'Artıq dostsunuz'**
  String get errorAlreadyFriends;

  /// No description provided for @errorAlreadyPending.
  ///
  /// In az, this message translates to:
  /// **'Sorğu artıq göndərilib'**
  String get errorAlreadyPending;

  /// No description provided for @errorBlocked.
  ///
  /// In az, this message translates to:
  /// **'Bu istifadəçi sizi bloklayıb'**
  String get errorBlocked;

  /// No description provided for @errorCannotFriendSelf.
  ///
  /// In az, this message translates to:
  /// **'Özünə sorğu göndərə bilməzsən'**
  String get errorCannotFriendSelf;

  /// No description provided for @errorUserNotFound.
  ///
  /// In az, this message translates to:
  /// **'Bu kodla istifadəçi tapılmadı'**
  String get errorUserNotFound;

  /// No description provided for @errorInvalidCodeFormat.
  ///
  /// In az, this message translates to:
  /// **'Yanlış kod formatı'**
  String get errorInvalidCodeFormat;

  /// No description provided for @acceptAction.
  ///
  /// In az, this message translates to:
  /// **'Qəbul et'**
  String get acceptAction;

  /// No description provided for @declineAction.
  ///
  /// In az, this message translates to:
  /// **'Rədd et'**
  String get declineAction;

  /// No description provided for @removeFriendAction.
  ///
  /// In az, this message translates to:
  /// **'Sil'**
  String get removeFriendAction;

  /// No description provided for @blockAction.
  ///
  /// In az, this message translates to:
  /// **'Bloklа'**
  String get blockAction;

  /// No description provided for @unblockAction.
  ///
  /// In az, this message translates to:
  /// **'Blokdan çıxar'**
  String get unblockAction;

  /// No description provided for @messageAction.
  ///
  /// In az, this message translates to:
  /// **'Mesaj'**
  String get messageAction;

  /// No description provided for @cancelAction.
  ///
  /// In az, this message translates to:
  /// **'Ləğv et'**
  String get cancelAction;

  /// No description provided for @chatTitle.
  ///
  /// In az, this message translates to:
  /// **'Mesajlaşma'**
  String get chatTitle;

  /// No description provided for @chatInputHint.
  ///
  /// In az, this message translates to:
  /// **'Mesaj yaz...'**
  String get chatInputHint;

  /// No description provided for @chatSendButton.
  ///
  /// In az, this message translates to:
  /// **'Göndər'**
  String get chatSendButton;

  /// No description provided for @chatPeerLeft.
  ///
  /// In az, this message translates to:
  /// **'Söhbətdaş ayrıldı'**
  String get chatPeerLeft;

  /// No description provided for @chatPeerTyping.
  ///
  /// In az, this message translates to:
  /// **'yazır...'**
  String get chatPeerTyping;

  /// No description provided for @chatEphemeralNotice.
  ///
  /// In az, this message translates to:
  /// **'Mesajlar yazışmanı bağladıqda silinir'**
  String get chatEphemeralNotice;

  /// No description provided for @chatNoMessages.
  ///
  /// In az, this message translates to:
  /// **'Hələ heç bir mesaj yoxdur'**
  String get chatNoMessages;

  /// No description provided for @chatNotFriends.
  ///
  /// In az, this message translates to:
  /// **'Yalnız dostlarla mesajlaşa bilərsən'**
  String get chatNotFriends;

  /// No description provided for @shopTitle.
  ///
  /// In az, this message translates to:
  /// **'Mağaza'**
  String get shopTitle;

  /// No description provided for @coinPacksSection.
  ///
  /// In az, this message translates to:
  /// **'SİKKƏ PAKETLƏRİ'**
  String get coinPacksSection;

  /// No description provided for @powerUpsSection.
  ///
  /// In az, this message translates to:
  /// **'GÜCLƏNDİRİCİLƏR'**
  String get powerUpsSection;

  /// No description provided for @specialOffer.
  ///
  /// In az, this message translates to:
  /// **'XÜSUSİ TƏKLİF'**
  String get specialOffer;

  /// No description provided for @starterBundle.
  ///
  /// In az, this message translates to:
  /// **'Başlanğıc Paketi'**
  String get starterBundle;

  /// No description provided for @starterBundleDesc.
  ///
  /// In az, this message translates to:
  /// **'5000 sikkə + 50 daş + 3 ipucu'**
  String get starterBundleDesc;

  /// No description provided for @popularBadge.
  ///
  /// In az, this message translates to:
  /// **'MƏŞHUR'**
  String get popularBadge;

  /// No description provided for @starterPack.
  ///
  /// In az, this message translates to:
  /// **'Başlanğıc'**
  String get starterPack;

  /// No description provided for @popularPack.
  ///
  /// In az, this message translates to:
  /// **'Məşhur'**
  String get popularPack;

  /// No description provided for @proPack.
  ///
  /// In az, this message translates to:
  /// **'Pro'**
  String get proPack;

  /// No description provided for @elitePack.
  ///
  /// In az, this message translates to:
  /// **'Elit'**
  String get elitePack;

  /// No description provided for @coinsUnit.
  ///
  /// In az, this message translates to:
  /// **'{amount} sikkə'**
  String coinsUnit(String amount);

  /// No description provided for @fiftyFiftyLifeline.
  ///
  /// In az, this message translates to:
  /// **'50/50 İpucu'**
  String get fiftyFiftyLifeline;

  /// No description provided for @extraTimePowerup.
  ///
  /// In az, this message translates to:
  /// **'Əlavə Vaxt +10s'**
  String get extraTimePowerup;

  /// No description provided for @skipQuestionPowerup.
  ///
  /// In az, this message translates to:
  /// **'Sualı Keç'**
  String get skipQuestionPowerup;

  /// No description provided for @tournamentsTitle.
  ///
  /// In az, this message translates to:
  /// **'Turnirlər'**
  String get tournamentsTitle;

  /// No description provided for @tournamentSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Şöhrət və mükafatlar üçün yarış'**
  String get tournamentSubtitle;

  /// No description provided for @allFilter.
  ///
  /// In az, this message translates to:
  /// **'Hamısı'**
  String get allFilter;

  /// No description provided for @liveFilter.
  ///
  /// In az, this message translates to:
  /// **'Canlı'**
  String get liveFilter;

  /// No description provided for @upcomingFilter.
  ///
  /// In az, this message translates to:
  /// **'Gələcək'**
  String get upcomingFilter;

  /// No description provided for @myEntriesFilter.
  ///
  /// In az, this message translates to:
  /// **'Qeydiyyatlarım'**
  String get myEntriesFilter;

  /// No description provided for @dailyChampionship.
  ///
  /// In az, this message translates to:
  /// **'Günlük Çempionat'**
  String get dailyChampionship;

  /// No description provided for @weekendRoyale.
  ///
  /// In az, this message translates to:
  /// **'Həftəsonu Royal'**
  String get weekendRoyale;

  /// No description provided for @speedQuizBlitz.
  ///
  /// In az, this message translates to:
  /// **'Sürətli Bilik Blitzi'**
  String get speedQuizBlitz;

  /// No description provided for @knowledgeMasters.
  ///
  /// In az, this message translates to:
  /// **'Bilik Ustadları'**
  String get knowledgeMasters;

  /// No description provided for @playersCount.
  ///
  /// In az, this message translates to:
  /// **'{count} oyunçu'**
  String playersCount(int count);

  /// No description provided for @coinsPrize.
  ///
  /// In az, this message translates to:
  /// **'{amount}k sikkə mükafatı'**
  String coinsPrize(String amount);

  /// No description provided for @liveBadge.
  ///
  /// In az, this message translates to:
  /// **'CANLI'**
  String get liveBadge;

  /// No description provided for @joinButton.
  ///
  /// In az, this message translates to:
  /// **'Qoşul'**
  String get joinButton;

  /// No description provided for @navHome.
  ///
  /// In az, this message translates to:
  /// **'Ana Səhifə'**
  String get navHome;

  /// No description provided for @navTournaments.
  ///
  /// In az, this message translates to:
  /// **'Turnirlər'**
  String get navTournaments;

  /// No description provided for @navShop.
  ///
  /// In az, this message translates to:
  /// **'Mağaza'**
  String get navShop;

  /// No description provided for @navFriends.
  ///
  /// In az, this message translates to:
  /// **'Dostlar'**
  String get navFriends;

  /// No description provided for @navProfile.
  ///
  /// In az, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @languageSelectorTitle.
  ///
  /// In az, this message translates to:
  /// **'Dil seçin'**
  String get languageSelectorTitle;

  /// No description provided for @azerbaijani.
  ///
  /// In az, this message translates to:
  /// **'Azərbaycan'**
  String get azerbaijani;

  /// No description provided for @russian.
  ///
  /// In az, this message translates to:
  /// **'Русский'**
  String get russian;

  /// No description provided for @turkish.
  ///
  /// In az, this message translates to:
  /// **'Türkçe'**
  String get turkish;

  /// No description provided for @english.
  ///
  /// In az, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @botBattle.
  ///
  /// In az, this message translates to:
  /// **'Bota Qarşı'**
  String get botBattle;

  /// No description provided for @botBattleSubtitle.
  ///
  /// In az, this message translates to:
  /// **'AI ilə yarış'**
  String get botBattleSubtitle;

  /// No description provided for @soloPlay.
  ///
  /// In az, this message translates to:
  /// **'Tək Oyna'**
  String get soloPlay;

  /// No description provided for @soloSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Öz başına məşq et'**
  String get soloSubtitle;

  /// No description provided for @botLabel.
  ///
  /// In az, this message translates to:
  /// **'BOT'**
  String get botLabel;

  /// No description provided for @botThinking.
  ///
  /// In az, this message translates to:
  /// **'Bot düşünür...'**
  String get botThinking;

  /// No description provided for @botAnswered.
  ///
  /// In az, this message translates to:
  /// **'Bot cavabladı'**
  String get botAnswered;

  /// No description provided for @youWon.
  ///
  /// In az, this message translates to:
  /// **'Siz Qazandınız!'**
  String get youWon;

  /// No description provided for @botWon.
  ///
  /// In az, this message translates to:
  /// **'Bot Qazandı'**
  String get botWon;

  /// No description provided for @opponentThinking.
  ///
  /// In az, this message translates to:
  /// **'düşünür...'**
  String get opponentThinking;

  /// No description provided for @opponentAnswered.
  ///
  /// In az, this message translates to:
  /// **'cavabladı'**
  String get opponentAnswered;

  /// No description provided for @opponentWon.
  ///
  /// In az, this message translates to:
  /// **'Rəqib Qazandı'**
  String get opponentWon;

  /// No description provided for @youLost.
  ///
  /// In az, this message translates to:
  /// **'Siz Uduzdunuz'**
  String get youLost;

  /// No description provided for @drawResult.
  ///
  /// In az, this message translates to:
  /// **'Bərabərlik!'**
  String get drawResult;

  /// No description provided for @yourScore.
  ///
  /// In az, this message translates to:
  /// **'Sizin Xal'**
  String get yourScore;

  /// No description provided for @botScore.
  ///
  /// In az, this message translates to:
  /// **'Bot Xalı'**
  String get botScore;

  /// No description provided for @playAgain.
  ///
  /// In az, this message translates to:
  /// **'Yenidən Oyna'**
  String get playAgain;

  /// No description provided for @battleResult.
  ///
  /// In az, this message translates to:
  /// **'Matç Nəticəsi'**
  String get battleResult;

  /// No description provided for @xpEarned.
  ///
  /// In az, this message translates to:
  /// **'+{xp} XP'**
  String xpEarned(int xp);

  /// No description provided for @coinsEarned.
  ///
  /// In az, this message translates to:
  /// **'+{coins} Sikkə'**
  String coinsEarned(int coins);

  /// No description provided for @usernameSetupTitle.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi adı seç'**
  String get usernameSetupTitle;

  /// No description provided for @usernameSetupSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Sizi tanıyacağımız ad — sonra dəyişə bilərsiniz'**
  String get usernameSetupSubtitle;

  /// No description provided for @usernameSetupHint.
  ///
  /// In az, this message translates to:
  /// **'İstifadəçi adı'**
  String get usernameSetupHint;

  /// No description provided for @usernameSetupContinue.
  ///
  /// In az, this message translates to:
  /// **'DAVAM ET'**
  String get usernameSetupContinue;

  /// No description provided for @usernameSetupErrorTaken.
  ///
  /// In az, this message translates to:
  /// **'Bu ad artıq tutulub'**
  String get usernameSetupErrorTaken;

  /// No description provided for @usernameSetupErrorFormat.
  ///
  /// In az, this message translates to:
  /// **'Yalnız hərf, rəqəm və _'**
  String get usernameSetupErrorFormat;

  /// No description provided for @usernameSetupErrorMinLen.
  ///
  /// In az, this message translates to:
  /// **'Min 3 simvol'**
  String get usernameSetupErrorMinLen;

  /// No description provided for @usernameSetupSaveFailed.
  ///
  /// In az, this message translates to:
  /// **'Yadda saxlamaq alınmadı'**
  String get usernameSetupSaveFailed;

  /// No description provided for @profileLoadFailed.
  ///
  /// In az, this message translates to:
  /// **'Profil yüklənmədi'**
  String get profileLoadFailed;

  /// No description provided for @opponentDisconnectedMessage.
  ///
  /// In az, this message translates to:
  /// **'Rəqib bağlantını kəsdi'**
  String get opponentDisconnectedMessage;

  /// No description provided for @alreadyInMatchMessage.
  ///
  /// In az, this message translates to:
  /// **'Artıq bir matçdasınız'**
  String get alreadyInMatchMessage;

  /// No description provided for @connectionLostMessage.
  ///
  /// In az, this message translates to:
  /// **'Bağlantı kəsildi'**
  String get connectionLostMessage;

  /// No description provided for @battleStartingTitle.
  ///
  /// In az, this message translates to:
  /// **'DÖYÜŞ BAŞLAYIR'**
  String get battleStartingTitle;

  /// No description provided for @battleWord.
  ///
  /// In az, this message translates to:
  /// **'DÖYÜŞ!'**
  String get battleWord;

  /// No description provided for @sendFriendRequestLabel.
  ///
  /// In az, this message translates to:
  /// **'Dostluq göndər'**
  String get sendFriendRequestLabel;

  /// No description provided for @friendRequestSentLabel.
  ///
  /// In az, this message translates to:
  /// **'Sorğu göndərildi'**
  String get friendRequestSentLabel;

  /// No description provided for @matchHistoryEmpty.
  ///
  /// In az, this message translates to:
  /// **'Hələ matç tarixçəsi yoxdur'**
  String get matchHistoryEmpty;

  /// No description provided for @matchHistoryError.
  ///
  /// In az, this message translates to:
  /// **'Tarixçə yüklənmədi'**
  String get matchHistoryError;

  /// No description provided for @matchOutcomeWin.
  ///
  /// In az, this message translates to:
  /// **'QALİB'**
  String get matchOutcomeWin;

  /// No description provided for @matchOutcomeLoss.
  ///
  /// In az, this message translates to:
  /// **'MƏĞLUB'**
  String get matchOutcomeLoss;

  /// No description provided for @matchOutcomeDraw.
  ///
  /// In az, this message translates to:
  /// **'HEÇ-HEÇƏ'**
  String get matchOutcomeDraw;

  /// No description provided for @matchOutcomeSolo.
  ///
  /// In az, this message translates to:
  /// **'SOLO'**
  String get matchOutcomeSolo;

  /// No description provided for @matchType1v1.
  ///
  /// In az, this message translates to:
  /// **'1v1'**
  String get matchType1v1;

  /// No description provided for @matchTypeTournament.
  ///
  /// In az, this message translates to:
  /// **'Turnir'**
  String get matchTypeTournament;

  /// No description provided for @matchTypeSolo.
  ///
  /// In az, this message translates to:
  /// **'Solo'**
  String get matchTypeSolo;

  /// No description provided for @editProfileTitle.
  ///
  /// In az, this message translates to:
  /// **'Profili Düzəlt'**
  String get editProfileTitle;

  /// No description provided for @chooseAvatar.
  ///
  /// In az, this message translates to:
  /// **'Avatar seç'**
  String get chooseAvatar;

  /// No description provided for @chooseFrame.
  ///
  /// In az, this message translates to:
  /// **'Çərçivə'**
  String get chooseFrame;

  /// No description provided for @chooseColor.
  ///
  /// In az, this message translates to:
  /// **'Rəng'**
  String get chooseColor;

  /// No description provided for @useInitialLetter.
  ///
  /// In az, this message translates to:
  /// **'İlk hərf'**
  String get useInitialLetter;

  /// No description provided for @saveAction.
  ///
  /// In az, this message translates to:
  /// **'Yadda saxla'**
  String get saveAction;

  /// No description provided for @profileUpdated.
  ///
  /// In az, this message translates to:
  /// **'Profil yeniləndi'**
  String get profileUpdated;

  /// No description provided for @editProfileTooltip.
  ///
  /// In az, this message translates to:
  /// **'Profili düzəlt'**
  String get editProfileTooltip;

  /// No description provided for @usernameAvailable.
  ///
  /// In az, this message translates to:
  /// **'Ad uyğundur'**
  String get usernameAvailable;

  /// No description provided for @signupOtpTitle.
  ///
  /// In az, this message translates to:
  /// **'Email-i təsdiqlə'**
  String get signupOtpTitle;

  /// No description provided for @signupOtpSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Email ünvanınıza göndərilən 6-rəqəmli kodu daxil edin'**
  String get signupOtpSubtitle;

  /// No description provided for @signupOtpVerify.
  ///
  /// In az, this message translates to:
  /// **'TƏSDİQLƏ'**
  String get signupOtpVerify;

  /// No description provided for @signupOtpResend.
  ///
  /// In az, this message translates to:
  /// **'Kodu yenidən göndər'**
  String get signupOtpResend;

  /// No description provided for @signupOtpResendIn.
  ///
  /// In az, this message translates to:
  /// **'{seconds} san sonra yenidən göndər'**
  String signupOtpResendIn(int seconds);

  /// No description provided for @signupOtpInvalid.
  ///
  /// In az, this message translates to:
  /// **'Kod yanlışdır və ya vaxtı keçib'**
  String get signupOtpInvalid;

  /// No description provided for @signupOtpSent.
  ///
  /// In az, this message translates to:
  /// **'Kod email ünvanınıza göndərildi'**
  String get signupOtpSent;

  /// No description provided for @otpCodeLength.
  ///
  /// In az, this message translates to:
  /// **'Tam 6 rəqəm tələb olunur'**
  String get otpCodeLength;

  /// No description provided for @claimDeviceTitle.
  ///
  /// In az, this message translates to:
  /// **'Yeni cihaz qeyd et'**
  String get claimDeviceTitle;

  /// No description provided for @claimDeviceSubtitle.
  ///
  /// In az, this message translates to:
  /// **'Hesabınız başqa cihazda aktivdir. Bu cihazı qeyd etmək üçün email-ə göndərilən kodu daxil edin.'**
  String get claimDeviceSubtitle;

  /// No description provided for @claimDeviceContinue.
  ///
  /// In az, this message translates to:
  /// **'BU CİHAZI QEYD ET'**
  String get claimDeviceContinue;

  /// No description provided for @claimDeviceLogout.
  ///
  /// In az, this message translates to:
  /// **'Çıxış et'**
  String get claimDeviceLogout;

  /// No description provided for @claimDeviceSuccess.
  ///
  /// In az, this message translates to:
  /// **'Cihaz uğurla qeyd olundu'**
  String get claimDeviceSuccess;

  /// No description provided for @claimDeviceActiveLabel.
  ///
  /// In az, this message translates to:
  /// **'Hazırda aktiv'**
  String get claimDeviceActiveLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['az', 'en', 'ru', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'az':
      return AppLocalizationsAz();
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
