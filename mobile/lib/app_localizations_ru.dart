// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get tagline => 'ЗНАЙ . ИГРАЙ . ПОБЕЖДАЙ';

  @override
  String get welcomeBack => 'С возвращением!';

  @override
  String get usernameOrEmail => 'Имя пользователя или Email';

  @override
  String get password => 'Пароль';

  @override
  String get fieldRequired => 'Обязательно';

  @override
  String get minSixChars => 'Мин 6 символов';

  @override
  String get loginButton => 'ВОЙТИ';

  @override
  String get dontHaveAccount => 'Нет аккаунта? ';

  @override
  String get registerLink => 'Регистрация';

  @override
  String get createAccountTitle => 'Создать аккаунт';

  @override
  String get joinBattleArena => 'Присоединяйся к арене Gguiz Battle';

  @override
  String get usernameField => 'Имя пользователя';

  @override
  String get minThreeChars => 'Мин 3 символа';

  @override
  String get usernameFormatError => 'Только буквы, цифры и _';

  @override
  String get emailField => 'Email';

  @override
  String get invalidEmail => 'Неверный email';

  @override
  String get passwordWithMin => 'Пароль (мин 6 символов)';

  @override
  String get createAccountButton => 'СОЗДАТЬ АККАУНТ';

  @override
  String get alreadyHaveAccount => 'Уже есть аккаунт? ';

  @override
  String get loginLink => 'Войти';

  @override
  String get daily => 'ЕЖЕДНЕВНЫЙ';

  @override
  String get tournament => 'ТУРНИР';

  @override
  String get winBigRewards => 'Выигрывай большие награды!';

  @override
  String get startsIn => 'Начинается через';

  @override
  String get joinNow => 'УЧАСТВОВАТЬ';

  @override
  String get playModes => 'РЕЖИМЫ ИГРЫ';

  @override
  String get seeAll => 'Все';

  @override
  String get quickBattle => 'Быстрый бой';

  @override
  String get practice => 'Тренировка';

  @override
  String get battleRoyaleTitle => 'БАТЛ\nРОЯЛЬ';

  @override
  String get lastOneWins => 'Побеждает последний';

  @override
  String get dailyMissions => 'ЕЖЕДНЕВНЫЕ ЗАДАНИЯ';

  @override
  String get mission1 => 'Сыграй 3 матча';

  @override
  String get mission2 => 'Выиграй 1 матч';

  @override
  String get mission3 => 'Ответь правильно на 10 вопросов';

  @override
  String missionPlayMatch(int count) {
    return 'Сыграй $count матчей';
  }

  @override
  String missionWinMatch(int count) {
    return 'Выиграй $count матчей';
  }

  @override
  String missionAnswerCorrect(int count) {
    return 'Ответь правильно на $count вопросов';
  }

  @override
  String missionFastAnswer(int count) {
    return 'Ответь на $count вопросов за 5 секунд';
  }

  @override
  String missionWinStreak(int count) {
    return 'Выиграй $count матчей подряд';
  }

  @override
  String missionRefreshIn(String time) {
    return 'Обновится через: $time';
  }

  @override
  String get missionClaim => 'Забрать';

  @override
  String get missionClaimed => 'Получено';

  @override
  String missionRewardXp(int xp) {
    return '+$xp XP';
  }

  @override
  String missionRewardCoins(int coins) {
    return '+$coins монет';
  }

  @override
  String get leaderboard => 'Рейтинг';

  @override
  String get view => 'Смотреть';

  @override
  String get topPlayers => 'Лучшие игроки';

  @override
  String get rankDiamond => 'Алмаз';

  @override
  String get rankPlatinum => 'Платина';

  @override
  String get rankGoldII => 'Золото II';

  @override
  String get rankSilver => 'Серебро';

  @override
  String get rankBronze => 'Бронза';

  @override
  String get levelLabel => 'Уровень';

  @override
  String get eloLabel => 'ELO';

  @override
  String get coinsLabel => 'Монеты';

  @override
  String get totalWins => 'Всего побед';

  @override
  String get losses => 'Поражения';

  @override
  String get totalXP => 'Всего XP';

  @override
  String get winRate => '% побед';

  @override
  String get achievementsTitle => 'Достижения';

  @override
  String get achievementFirstWin => 'Первая победа';

  @override
  String get achievementTenWins => '10 побед';

  @override
  String get achievementSpeedDemon => 'Демон скорости';

  @override
  String get achievementFiftyWins => '50 побед';

  @override
  String get recentMatchesTitle => 'Последние матчи';

  @override
  String get matchHistorySoon => 'История матчей скоро';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get notificationsLabel => 'Уведомления';

  @override
  String get languageLabel => 'Язык';

  @override
  String get privacyPolicyLabel => 'Политика конфиденциальности';

  @override
  String get logoutLabel => 'Выйти';

  @override
  String errorMessage(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get oneVsOneBattle => 'Бой 1 на 1';

  @override
  String get youLabel => 'Вы';

  @override
  String get eloRankedMatch => 'Рейтинговый матч ELO';

  @override
  String get findingOpponent => 'Поиск соперника...';

  @override
  String get matchingSimilarElo => 'Подбираем игроков с похожим ELO';

  @override
  String get findMatchButton => 'НАЙТИ СОПЕРНИКА';

  @override
  String get cancelSearch => 'Отмена';

  @override
  String get noOpponentFoundYet => 'Соперник пока не найден';

  @override
  String get playWithBotInstead => 'Играть с ботом';

  @override
  String get maxLevelBadge => 'Максимальный уровень';

  @override
  String get levelUpTitle => 'НОВЫЙ УРОВЕНЬ!';

  @override
  String levelUpSubtitle(int level) {
    return 'Вы достигли $level уровня!';
  }

  @override
  String get continueButton => 'ПРОДОЛЖИТЬ';

  @override
  String get levelTier1 => 'НОВИЧОК';

  @override
  String get levelTier2 => 'ОПЫТНЫЙ';

  @override
  String get levelTier3 => 'ЗНАТОК';

  @override
  String get levelTier4 => 'МАСТЕР';

  @override
  String get levelTier5 => 'ЭКСПЕРТ';

  @override
  String get levelTier6 => 'ЧЕМПИОН';

  @override
  String get levelTier7 => 'ЛЕГЕНДА';

  @override
  String get orContinueWith => 'ИЛИ';

  @override
  String get continueWithGoogle => 'Продолжить с Google';

  @override
  String get continueWithApple => 'Продолжить с Apple';

  @override
  String get continueWithFacebook => 'Продолжить с Facebook';

  @override
  String get socialLoginFailed => 'Не удалось войти. Попробуйте снова.';

  @override
  String get coinBalanceTitle => 'Баланс монет';

  @override
  String get xpBalanceTitle => 'Баланс XP';

  @override
  String get goToShop => 'В магазин';

  @override
  String get closeAction => 'Закрыть';

  @override
  String get notificationsTitle => 'Уведомления';

  @override
  String get noNotifications => 'У вас пока нет уведомлений';

  @override
  String get errorInvalidCredentials => 'Неверное имя пользователя или пароль';

  @override
  String get errorUserExists =>
      'Это имя пользователя или email уже зарегистрированы';

  @override
  String get errorNetwork => 'Нет соединения с сервером. Проверьте интернет';

  @override
  String get errorGeneric => 'Произошла ошибка. Попробуйте снова';

  @override
  String get confirmPasswordField => 'Повторите пароль';

  @override
  String get passwordsDoNotMatch => 'Пароли не совпадают';

  @override
  String get otpTitle => 'Подтверждение email';

  @override
  String otpSubtitle(String email) {
    return 'Мы отправили 6-значный код на $email';
  }

  @override
  String get otpInputHint => 'Код подтверждения';

  @override
  String get otpVerifyButton => 'ПОДТВЕРДИТЬ';

  @override
  String get otpResendButton => 'Отправить код заново';

  @override
  String get otpInvalid => 'Неверный или просроченный код';

  @override
  String get otpResent => 'Код отправлен';

  @override
  String get winsLabel => 'Победы';

  @override
  String get lossesLabel => 'Поражения';

  @override
  String get winRateLabel => '% Побед';

  @override
  String get leaderboardTitle => 'Рейтинг';

  @override
  String get youInParens => '(Вы)';

  @override
  String winsText(int count) {
    return '$count побед';
  }

  @override
  String get leaderboardEmpty => 'Пока нет игроков';

  @override
  String get leaderboardEmptyHint => 'Играйте, чтобы стать первым!';

  @override
  String get leaderboardError => 'Не удалось загрузить рейтинг';

  @override
  String scoreLabel(int score) {
    return 'Счёт: $score';
  }

  @override
  String get quizComplete => 'Тест завершён!';

  @override
  String earnedLabel(int xp, int coins) {
    return '+ $xp XP   + $coins Монет';
  }

  @override
  String get doneButton => 'Готово';

  @override
  String get friendsTitle => 'Друзья';

  @override
  String get addButton => 'Добавить';

  @override
  String get searchPlayersHint => 'Поиск игроков...';

  @override
  String friendsTab(int count) {
    return 'Друзья ($count)';
  }

  @override
  String requestsTab(int count) {
    return 'Заявки ($count)';
  }

  @override
  String blockedTab(int count) {
    return 'Заблокированные ($count)';
  }

  @override
  String get onlineStatus => 'В сети';

  @override
  String get offlineStatus => 'Не в сети';

  @override
  String get challengeButton => 'Вызов';

  @override
  String get addFriendTitle => 'Добавить друга';

  @override
  String get addFriendHint => 'Введите ID-код друга';

  @override
  String get addFriendButton => 'Отправить запрос';

  @override
  String get yourFriendCode => 'Твой ID-код';

  @override
  String get copyCodeAction => 'Копировать';

  @override
  String get codeCopied => 'Код скопирован';

  @override
  String get shareCodeHint => 'Поделись этим кодом с друзьями';

  @override
  String get friendCodeFormatError => 'Код должен содержать 6 символов';

  @override
  String get friendRequestSent => 'Запрос отправлен';

  @override
  String get friendRequestAccepted => 'Запрос принят';

  @override
  String get friendRemoved => 'Друг удалён';

  @override
  String get friendBlocked => 'Пользователь заблокирован';

  @override
  String get friendUnblocked => 'Разблокирован';

  @override
  String get noFriendsYet => 'Пока нет друзей';

  @override
  String get noFriendsHint => 'Нажми кнопку выше и введи ID-код';

  @override
  String get noRequestsYet => 'Новых запросов нет';

  @override
  String get noBlockedYet => 'Нет заблокированных';

  @override
  String get incomingRequests => 'Входящие';

  @override
  String get outgoingRequests => 'Исходящие';

  @override
  String get errorAlreadyFriends => 'Уже в друзьях';

  @override
  String get errorAlreadyPending => 'Запрос уже отправлен';

  @override
  String get errorBlocked => 'Этот пользователь вас заблокировал';

  @override
  String get errorCannotFriendSelf => 'Нельзя добавить себя';

  @override
  String get errorUserNotFound => 'Пользователь с таким кодом не найден';

  @override
  String get errorInvalidCodeFormat => 'Неверный формат кода';

  @override
  String get acceptAction => 'Принять';

  @override
  String get declineAction => 'Отклонить';

  @override
  String get removeFriendAction => 'Удалить';

  @override
  String get blockAction => 'Блокировать';

  @override
  String get unblockAction => 'Разблокировать';

  @override
  String get messageAction => 'Сообщение';

  @override
  String get cancelAction => 'Отмена';

  @override
  String get chatTitle => 'Чат';

  @override
  String get chatInputHint => 'Напиши сообщение...';

  @override
  String get chatSendButton => 'Отправить';

  @override
  String get chatPeerLeft => 'Собеседник вышел';

  @override
  String get chatPeerTyping => 'печатает...';

  @override
  String get chatEphemeralNotice => 'Сообщения удаляются при закрытии чата';

  @override
  String get chatNoMessages => 'Пока нет сообщений';

  @override
  String get chatNotFriends => 'Можно общаться только с друзьями';

  @override
  String get shopTitle => 'Магазин';

  @override
  String get coinPacksSection => 'ПАКЕТЫ МОНЕТ';

  @override
  String get powerUpsSection => 'УСИЛИТЕЛИ';

  @override
  String get specialOffer => 'СПЕЦПРЕДЛОЖЕНИЕ';

  @override
  String get starterBundle => 'Стартовый набор';

  @override
  String get starterBundleDesc => '5000 монет + 50 кристаллов + 3 подсказки';

  @override
  String get popularBadge => 'ПОПУЛЯРНО';

  @override
  String get starterPack => 'Стартовый';

  @override
  String get popularPack => 'Популярный';

  @override
  String get proPack => 'Про';

  @override
  String get elitePack => 'Элитный';

  @override
  String coinsUnit(String amount) {
    return '$amount монет';
  }

  @override
  String get fiftyFiftyLifeline => 'Подсказка 50/50';

  @override
  String get extraTimePowerup => 'Доп. время +10с';

  @override
  String get skipQuestionPowerup => 'Пропустить вопрос';

  @override
  String get tournamentsTitle => 'Турниры';

  @override
  String get tournamentSubtitle => 'Борись за славу и награды';

  @override
  String get allFilter => 'Все';

  @override
  String get liveFilter => 'В эфире';

  @override
  String get upcomingFilter => 'Ближайшие';

  @override
  String get myEntriesFilter => 'Мои заявки';

  @override
  String get dailyChampionship => 'Ежедневный чемпионат';

  @override
  String get weekendRoyale => 'Выходной Рояль';

  @override
  String get speedQuizBlitz => 'Быстрый блиц';

  @override
  String get knowledgeMasters => 'Мастера знаний';

  @override
  String playersCount(int count) {
    return '$count игроков';
  }

  @override
  String coinsPrize(String amount) {
    return 'Приз ${amount}k монет';
  }

  @override
  String get liveBadge => 'ПРЯМОЙ ЭФИР';

  @override
  String get joinButton => 'Участвовать';

  @override
  String get navHome => 'Главная';

  @override
  String get navTournaments => 'Турниры';

  @override
  String get navShop => 'Магазин';

  @override
  String get navFriends => 'Друзья';

  @override
  String get navProfile => 'Профиль';

  @override
  String get languageSelectorTitle => 'Выберите язык';

  @override
  String get azerbaijani => 'Azərbaycan';

  @override
  String get russian => 'Русский';

  @override
  String get turkish => 'Türkçe';

  @override
  String get english => 'English';

  @override
  String get botBattle => 'Против бота';

  @override
  String get botBattleSubtitle => 'Сыграй с ИИ';

  @override
  String get soloPlay => 'Соло режим';

  @override
  String get soloSubtitle => 'Тренировка в одиночку';

  @override
  String get botLabel => 'БОТ';

  @override
  String get botThinking => 'Бот думает...';

  @override
  String get botAnswered => 'Бот ответил';

  @override
  String get youWon => 'Вы победили!';

  @override
  String get botWon => 'Бот победил';

  @override
  String get opponentThinking => 'думает...';

  @override
  String get opponentAnswered => 'ответил';

  @override
  String get opponentWon => 'Соперник победил';

  @override
  String get youLost => 'Вы проиграли';

  @override
  String get drawResult => 'Ничья!';

  @override
  String get yourScore => 'Ваш счёт';

  @override
  String get botScore => 'Счёт бота';

  @override
  String get playAgain => 'Играть снова';

  @override
  String get battleResult => 'Результат матча';

  @override
  String xpEarned(int xp) {
    return '+$xp XP';
  }

  @override
  String coinsEarned(int coins) {
    return '+$coins Монет';
  }

  @override
  String get usernameSetupTitle => 'Выберите имя пользователя';

  @override
  String get usernameSetupSubtitle =>
      'Имя, которое увидят другие — позже его можно изменить';

  @override
  String get usernameSetupHint => 'Имя пользователя';

  @override
  String get usernameSetupContinue => 'ПРОДОЛЖИТЬ';

  @override
  String get usernameSetupErrorTaken => 'Это имя уже занято';

  @override
  String get usernameSetupErrorFormat => 'Только буквы, цифры и _';

  @override
  String get usernameSetupErrorMinLen => 'Минимум 3 символа';

  @override
  String get usernameSetupSaveFailed => 'Не удалось сохранить';

  @override
  String get profileLoadFailed => 'Не удалось загрузить профиль';

  @override
  String get opponentDisconnectedMessage => 'Соперник отключился';

  @override
  String get alreadyInMatchMessage => 'Вы уже в матче';

  @override
  String get connectionLostMessage => 'Соединение прервано';

  @override
  String get battleStartingTitle => 'БИТВА НАЧИНАЕТСЯ';

  @override
  String get battleWord => 'БИТВА!';

  @override
  String get sendFriendRequestLabel => 'Добавить в друзья';

  @override
  String get friendRequestSentLabel => 'Запрос отправлен';

  @override
  String get matchHistoryEmpty => 'История матчей пуста';

  @override
  String get matchHistoryError => 'Не удалось загрузить историю';

  @override
  String get matchOutcomeWin => 'ПОБЕДА';

  @override
  String get matchOutcomeLoss => 'ПОРАЖЕНИЕ';

  @override
  String get matchOutcomeDraw => 'НИЧЬЯ';

  @override
  String get matchOutcomeSolo => 'СОЛО';

  @override
  String get matchType1v1 => '1v1';

  @override
  String get matchTypeTournament => 'Турнир';

  @override
  String get matchTypeSolo => 'Соло';

  @override
  String get editProfileTitle => 'Изменить профиль';

  @override
  String get chooseAvatar => 'Выберите аватар';

  @override
  String get chooseFrame => 'Рамка';

  @override
  String get chooseColor => 'Цвет';

  @override
  String get useInitialLetter => 'Буква';

  @override
  String get saveAction => 'Сохранить';

  @override
  String get profileUpdated => 'Профиль обновлён';

  @override
  String get editProfileTooltip => 'Изменить профиль';

  @override
  String get usernameAvailable => 'Имя свободно';

  @override
  String get signupOtpTitle => 'Подтвердите email';

  @override
  String get signupOtpSubtitle =>
      'Введите 6-значный код, отправленный на вашу почту';

  @override
  String get signupOtpVerify => 'ПОДТВЕРДИТЬ';

  @override
  String get signupOtpResend => 'Отправить код снова';

  @override
  String signupOtpResendIn(int seconds) {
    return 'Повторно через $seconds с';
  }

  @override
  String get signupOtpInvalid => 'Код неверен или истёк';

  @override
  String get signupOtpSent => 'Код отправлен на ваш email';

  @override
  String get otpCodeLength => 'Введите все 6 цифр';

  @override
  String get claimDeviceTitle => 'Привязать это устройство';

  @override
  String get claimDeviceSubtitle =>
      'Ваш аккаунт активен на другом устройстве. Введите код из почты, чтобы привязать это устройство.';

  @override
  String get claimDeviceContinue => 'ПРИВЯЗАТЬ УСТРОЙСТВО';

  @override
  String get claimDeviceLogout => 'Выйти';

  @override
  String get claimDeviceSuccess => 'Устройство привязано';

  @override
  String get claimDeviceActiveLabel => 'Активное сейчас';
}
