import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gguiz_battle/app_localizations.dart';
import '../../../../core/data/quiz_questions.dart';
import '../../../../core/providers/local_game_stats_provider.dart';
import '../../../friends/providers/friend_provider.dart';
import '../../../home/data/user_repository.dart';
import '../../../home/providers/user_provider.dart';
import '../../../missions/data/daily_mission.dart';
import '../../../missions/providers/daily_missions_provider.dart';
import '../../../profile/data/profile_customization.dart';
import '../../../profile/providers/profile_customization_provider.dart';
import '../../../profile/presentation/widgets/profile_avatar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/battle_socket_service.dart';
import '../widgets/level_up_overlay.dart';

class BattleMatchArgs {
  final String matchId;
  final String userId;
  final String username;
  final List<int> questionIndices;
  final String opponentName;
  final int opponentElo;
  final String opponentUserId;
  final String opponentFriendCode;
  final ProfileCustomization opponentCustomization;
  final BattleSocketService socket;

  BattleMatchArgs({
    required this.matchId,
    required this.userId,
    required this.username,
    required this.questionIndices,
    required this.opponentName,
    required this.opponentElo,
    required this.opponentUserId,
    required this.opponentFriendCode,
    this.opponentCustomization = const ProfileCustomization(),
    required this.socket,
  });
}

class BattleMatchScreen extends ConsumerStatefulWidget {
  final BattleMatchArgs args;
  const BattleMatchScreen({super.key, required this.args});

  @override
  ConsumerState<BattleMatchScreen> createState() => _BattleMatchScreenState();
}

class _BattleMatchScreenState extends ConsumerState<BattleMatchScreen> {
  static const _totalTime = 15;
  static const _revealDuration = Duration(milliseconds: 1800);
  static const _introDuration = Duration(milliseconds: 3200);

  late final List<QuizQuestion> _questions;
  String _locale = 'az';
  int _currentQ = 0;
  int _myScore = 0;
  int _opponentScore = 0;
  int _opponentCorrect = 0;
  int _myCorrect = 0;
  int _timeLeft = _totalTime;
  int? _myAnswer;
  int? _opponentAnswer;
  int? _myAnswerTimeMs;
  int? _opponentAnswerTimeMs;
  bool _answered = false;
  bool _opponentAnswered = false;
  bool _revealing = false; // hər iki cavab bitib reveal mərhələsidir
  bool _showResult = false;
  bool _showIntro = true;
  bool _friendRequestSent = false;
  bool _friendRequestLoading = false;
  Map<String, dynamic>? _matchResult;
  Timer? _timer;
  Timer? _introTimer;
  DateTime? _questionStart;

  @override
  void initState() {
    super.initState();
    _questions = pickQuestionsByIndices(widget.args.questionIndices);

    widget.args.socket.onAnswerReceived(_onOpponentAnswer);
    widget.args.socket.onMatchResult(_onMatchResult);
    widget.args.socket.onOpponentDisconnected(_onOpponentDisconnected);

    // VS intro ekranı bitdikdə oyun başlasın
    _introTimer = Timer(_introDuration, () {
      if (!mounted) return;
      setState(() => _showIntro = false);
      _startRound();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = Localizations.localeOf(context).languageCode;
  }

  void _startRound() {
    setState(() {
      _answered = false;
      _opponentAnswered = false;
      _myAnswer = null;
      _opponentAnswer = null;
      _myAnswerTimeMs = null;
      _opponentAnswerTimeMs = null;
      _revealing = false;
      _timeLeft = _totalTime;
    });
    _questionStart = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        // Vaxt bitdi — cavab verməyibsə "cavabsız" göndər
        if (!_answered) {
          _submitMyAnswer(-1);
        }
        // Vaxt bitdiyi üçün reveal-i məcburi başlat (rəqib gözlədilməz)
        _tryReveal(force: true);
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _selectAnswer(int index) {
    if (_answered || _revealing) return;
    _submitMyAnswer(index);
    _tryReveal();
  }

  /// Mənim seçimimi göndərir və `_answered` state qoyur — xal hesablanmır,
  /// yalnız reveal vaxtı hesablanır.
  void _submitMyAnswer(int index) {
    final correct = _questions[_currentQ].correct;
    final isCorrect = index == correct;
    final timeMs = DateTime.now().difference(_questionStart!).inMilliseconds;
    setState(() {
      _myAnswer = index;
      _answered = true;
      _myAnswerTimeMs = timeMs;
    });
    widget.args.socket.submitAnswer(
      matchId: widget.args.matchId,
      questionIndex: _currentQ,
      answer: index >= 0 ? String.fromCharCode(65 + index) : '',
      isCorrect: isCorrect,
      timeMs: timeMs,
    );
  }

  void _onOpponentAnswer(Map<String, dynamic> data) {
    if (data['questionIndex'] != _currentQ) return;
    // Backend səhvən geri echo etsə öz cavabımızı opponent kimi saymayaq.
    final fromSocketId = data['socketId'] as String?;
    if (fromSocketId != null && fromSocketId == widget.args.socket.socketId) return;

    final answerStr = data['answer'] as String? ?? '';
    final oppIndex = answerStr.isEmpty ? -1 : (answerStr.codeUnitAt(0) - 65);
    final timeMs = (data['timeMs'] as num?)?.toInt() ?? 15000;

    setState(() {
      _opponentAnswered = true;
      _opponentAnswer = oppIndex;
      _opponentAnswerTimeMs = timeMs;
    });
    _tryReveal();
  }

  /// Hər iki cavab gəlibsə və ya vaxt bitibsə reveal-ə keç.
  void _tryReveal({bool force = false}) {
    if (_revealing) return;
    if (!force && !(_answered && _opponentAnswered)) return;

    _timer?.cancel();
    final q = _questions[_currentQ];
    final myCorrect = _myAnswer == q.correct;
    final oppCorrect = _opponentAnswer == q.correct;

    setState(() {
      _revealing = true;
      if (myCorrect) {
        _myCorrect++;
        _myScore += _scoreFor(_myAnswerTimeMs ?? 15000);
      }
      if (oppCorrect) {
        _opponentCorrect++;
        _opponentScore += _scoreFor(_opponentAnswerTimeMs ?? 15000);
      }
    });

    if (myCorrect) {
      final notifier = ref.read(dailyMissionsProvider.notifier);
      notifier.incrementProgress(MissionType.answerCorrect, 1);
      if ((_myAnswerTimeMs ?? 15000) < 5000) {
        notifier.incrementProgress(MissionType.fastAnswer, 1);
      }
    }

    Future.delayed(_revealDuration, _nextOrComplete);
  }

  /// Score formula: doğru cavab = 100 + sürət bonusu (qalan saniyə * 10).
  /// Cavabsız (-1) vaxtı 15000 olur, score = 0 olmalıdır — yalnız doğru index üçün çağrılır.
  int _scoreFor(int timeMs) {
    final remaining = ((15000 - timeMs) / 1000).clamp(0, 15).round();
    return 100 + remaining * 10;
  }

  void _nextOrComplete() {
    if (!mounted) return;
    if (_currentQ < _questions.length - 1) {
      setState(() => _currentQ++);
      _startRound();
    } else {
      widget.args.socket.completeMatch(
        matchId: widget.args.matchId,
        userId: widget.args.userId,
        score: _myScore,
        correctAnswers: _myCorrect,
        opponentUserId: widget.args.opponentUserId,
        opponentScore: _opponentScore,
        opponentCorrect: _opponentCorrect,
      );
    }
  }

  bool _resultProcessed = false;

  void _onMatchResult(Map<String, dynamic> data) {
    if (!mounted) return;
    if (_resultProcessed) return;
    _resultProcessed = true;
    final myReward = (data['rewards'] as Map?)?[widget.args.userId];
    int? leveledFrom;
    int? leveledTo;
    if (myReward != null) {
      final xp = (myReward['xp'] as num).toInt();
      final coins = (myReward['coins'] as num).toInt();
      final winnerId = data['winnerId'] as String?;
      final outcome = winnerId == null
          ? GameOutcome.draw
          : (winnerId == widget.args.userId ? GameOutcome.win : GameOutcome.loss);

      final profile = ref.read(userProfileProvider).valueOrNull;
      final bonusXp = ref.read(localGameStatsProvider).bonusXp;
      final oldTotalXp = (profile?.xp ?? 0) + bonusXp;
      final oldLevel = UserProfile.levelFromXp(oldTotalXp);

      ref.read(localGameStatsProvider.notifier).addReward(
            xp: xp,
            coins: coins,
            outcome: outcome,
          );
      final missions = ref.read(dailyMissionsProvider.notifier);
      missions.incrementProgress(MissionType.playMatch, 1);
      if (outcome == GameOutcome.win) {
        missions.incrementProgress(MissionType.winMatch, 1);
      }
      missions.updateStreak(outcome == GameOutcome.win);

      final newLevel = UserProfile.levelFromXp(oldTotalXp + xp);
      if (newLevel > oldLevel) {
        leveledFrom = oldLevel;
        leveledTo = newLevel;
      }
    }
    setState(() {
      _matchResult = data;
      _showResult = true;
    });
    if (leveledFrom != null && leveledTo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showLevelUpOverlay(context, oldLevel: leveledFrom!, newLevel: leveledTo!);
        }
      });
    }
  }

  void _onOpponentDisconnected() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.opponentDisconnectedMessage), backgroundColor: AppColors.error),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _introTimer?.cancel();
    widget.args.socket.clearListeners();
    widget.args.socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_showIntro) return _buildIntroScreen(l10n);
    if (_showResult) return _buildResultScreen(l10n);

    final q = _questions[_currentQ];
    final options = q.optionsFor(_locale);
    final optionLabels = ['A', 'B', 'C', 'D'];
    final optionColors = [AppColors.optionA, AppColors.optionB, AppColors.optionC, AppColors.optionD];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildTopBar(l10n),
                const SizedBox(height: 14),
                _buildScoreRow(l10n),
                const SizedBox(height: 16),
                _buildQuestionCard(q.questionFor(_locale)),
                const SizedBox(height: 16),
                _buildOpponentStatus(l10n),
                const SizedBox(height: 14),
                ...options.asMap().entries.map((e) =>
                    _buildOption(e.key, e.value, optionLabels[e.key], optionColors[e.key])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: AppColors.surfaceLight, borderRadius: BorderRadius.circular(20)),
          child: Text('${_currentQ + 1}/${_questions.length}', style: AppTextStyles.labelLarge),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: _timeLeft <= 5 ? AppColors.error.withValues(alpha: 0.2) : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _timeLeft <= 5 ? AppColors.error : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(Icons.timer, color: _timeLeft <= 5 ? AppColors.error : AppColors.accent, size: 16),
              const SizedBox(width: 4),
              Text('$_timeLeft', style: AppTextStyles.timerText.copyWith(
                fontSize: 16,
                color: _timeLeft <= 5 ? AppColors.error : AppColors.accent,
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRow(AppLocalizations l10n) {
    final myCustomization = ref.watch(profileCustomizationProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.gradientCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                ProfileAvatar(
                  username: widget.args.username,
                  customization: myCustomization,
                  size: 40,
                ),
                const SizedBox(height: 4),
                Text(widget.args.username,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryLight),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('$_myScore',
                    style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.accentOrange),
            ),
            child: Text('VS', style: AppTextStyles.titleMedium.copyWith(color: AppColors.accentOrange)),
          ),
          Expanded(
            child: Column(
              children: [
                ProfileAvatar(
                  username: widget.args.opponentName,
                  customization: widget.args.opponentCustomization,
                  size: 40,
                ),
                const SizedBox(height: 4),
                Text(widget.args.opponentName,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('$_opponentScore',
                    style: AppTextStyles.headlineLarge.copyWith(color: AppColors.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.gradientCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(question, style: AppTextStyles.questionText),
    ).animate(key: ValueKey(_currentQ)).fadeIn().slideY(begin: -0.1);
  }

  Widget _buildOpponentStatus(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _opponentAnswered ? AppColors.success.withValues(alpha: 0.1) : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _opponentAnswered ? AppColors.success : const Color(0xFF2A2A50)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_rounded, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Text(
            _opponentAnswered ? '${widget.args.opponentName} ${l10n.opponentAnswered}' : '${widget.args.opponentName} ${l10n.opponentThinking}',
            style: AppTextStyles.bodySmall.copyWith(
              color: _opponentAnswered ? AppColors.success : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(int index, String text, String label, Color labelColor) {
    final correct = _questions[_currentQ].correct;
    Color bg = AppColors.surfaceLight;
    Color border = const Color(0xFF2A2A40);
    Widget? badge;

    // Sual mərhələsində: yalnız mənim seçimimi göstər (sönük), rəqibinki gizli
    if (!_revealing) {
      if (_answered && index == _myAnswer) {
        bg = AppColors.primary.withValues(alpha: 0.15);
        border = AppColors.primary;
      }
    } else {
      // Reveal mərhələsi: doğru = yaşıl, mənim/rəqibin yanlış seçimi = qırmızı
      if (index == correct) {
        bg = AppColors.correctAnswer.withValues(alpha: 0.25);
        border = AppColors.correctAnswer;
      } else if (index == _myAnswer || index == _opponentAnswer) {
        bg = AppColors.wrongAnswer.withValues(alpha: 0.25);
        border = AppColors.wrongAnswer;
      }
      // İkonlar — kimin seçimi olduğunu göstər
      badge = _buildSelectionBadge(index);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _selectAnswer(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: labelColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(label, style: AppTextStyles.labelLarge.copyWith(color: labelColor))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: AppTextStyles.optionText)),
              if (badge != null) badge,
            ],
          ),
        ),
      ),
    );
  }

  /// Reveal mərhələsində — bu option-u kim seçib (mən, rəqib və ya hər ikisi)?
  Widget? _buildSelectionBadge(int index) {
    final mineHere = _myAnswer == index;
    final oppHere = _opponentAnswer == index;
    if (!mineHere && !oppHere) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mineHere)
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('SİZ', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        if (oppHere)
          Container(
            margin: const EdgeInsets.only(left: 6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('RƏQİB', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }

  Widget _buildResultScreen(AppLocalizations l10n) {
    final r = _matchResult ?? {};
    final winnerId = r['winnerId'] as String?;
    final isWin = winnerId == widget.args.userId;
    final isDraw = r['isDraw'] == true || winnerId == null;
    final reward = (r['rewards'] as Map?)?[widget.args.userId];
    final newElo = (r['newElo'] as Map?)?[widget.args.userId];
    final eloChange = (r['eloChange'] as Map?)?[widget.args.userId];
    final xp = (reward?['xp'] as num?)?.toInt() ?? 0;
    final coins = (reward?['coins'] as num?)?.toInt() ?? 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isDraw ? Icons.handshake_rounded : (isWin ? Icons.emoji_events_rounded : Icons.heart_broken_rounded),
                  size: 96,
                  color: isDraw ? AppColors.accent : (isWin ? AppColors.gold : AppColors.error),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(
                  isDraw ? l10n.drawResult : (isWin ? l10n.youWon : l10n.youLost),
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: isDraw ? AppColors.accent : (isWin ? AppColors.success : AppColors.error),
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientCard,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _stat(widget.args.username, '$_myScore', AppColors.primary)),
                      Container(width: 1, height: 50, color: const Color(0xFF2A2A40)),
                      Expanded(child: _stat(widget.args.opponentName, '$_opponentScore', AppColors.error)),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 16),
                if (newElo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.rankGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.rankGold.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'ELO: $newElo (${(eloChange as num) >= 0 ? '+' : ''}$eloChange)',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.rankGold, fontWeight: FontWeight.w700),
                    ),
                  ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _badge(l10n.xpEarned(xp), AppColors.accent),
                    const SizedBox(width: 12),
                    _badge(l10n.coinsEarned(coins), AppColors.gold),
                  ],
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 24),
                _buildFriendRequestButton(l10n).animate().fadeIn(delay: 650.ms),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(l10n.doneButton, style: AppTextStyles.labelLarge.copyWith(fontSize: 15, letterSpacing: 2)),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroScreen(AppLocalizations l10n) {
    final myCustomization = ref.watch(profileCustomizationProvider);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n.battleStartingTitle,
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted, letterSpacing: 3),
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: _buildIntroPlayer(
                        widget.args.username,
                        myCustomization,
                        AppColors.primary,
                      ).animate().slideX(begin: -1.0, duration: 600.ms, curve: Curves.easeOut).fadeIn(),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.accentOrange, width: 2),
                      ),
                      child: Text(
                        'VS',
                        style: AppTextStyles.headlineLarge.copyWith(color: AppColors.accentOrange),
                      ),
                    ).animate().scale(delay: 400.ms, duration: 500.ms, curve: Curves.elasticOut),
                    Expanded(
                      child: _buildIntroPlayer(
                        widget.args.opponentName,
                        widget.args.opponentCustomization,
                        AppColors.error,
                      ).animate().slideX(begin: 1.0, duration: 600.ms, curve: Curves.easeOut).fadeIn(),
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Text(
                  l10n.battleWord,
                  style: AppTextStyles.headlineLarge.copyWith(
                    color: AppColors.accentOrange,
                    fontSize: 56,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                )
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 400.ms)
                    .scale(begin: const Offset(0.5, 0.5), duration: 600.ms, curve: Curves.elasticOut)
                    .then(delay: 600.ms)
                    .shake(hz: 4, duration: 600.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIntroPlayer(
    String name,
    ProfileCustomization customization,
    Color nameColor,
  ) {
    return Column(
      children: [
        ProfileAvatar(
          username: name,
          customization: customization,
          size: 84,
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: AppTextStyles.titleMedium.copyWith(color: nameColor, fontWeight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _sendFriendRequest(AppLocalizations l10n) async {
    if (_friendRequestSent || _friendRequestLoading) return;
    final code = widget.args.opponentFriendCode;
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() {
      _friendRequestLoading = true;
    });
    try {
      await ref.read(friendsProvider.notifier).sendRequest(code);
      if (!mounted) return;
      setState(() {
        _friendRequestSent = true;
        _friendRequestLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.friendRequestSent), backgroundColor: AppColors.success),
      );
    } on PostgrestException catch (e) {
      if (!mounted) return;
      final m = e.message;
      String msg;
      bool treatAsSuccess = false;
      if (m.contains('already_friends')) {
        msg = l10n.errorAlreadyFriends; treatAsSuccess = true;
      } else if (m.contains('already_pending')) {
        msg = l10n.errorAlreadyPending; treatAsSuccess = true;
      } else if (m.contains('cannot_friend_self')) {
        msg = l10n.errorCannotFriendSelf;
      } else if (m.contains('user_not_found')) {
        msg = l10n.errorUserNotFound;
      } else if (m.contains('blocked')) {
        msg = l10n.errorBlocked;
      } else {
        msg = l10n.errorGeneric;
      }
      setState(() {
        _friendRequestLoading = false;
        if (treatAsSuccess) _friendRequestSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: treatAsSuccess ? AppColors.accent : AppColors.error),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _friendRequestLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneric), backgroundColor: AppColors.error),
      );
    }
  }

  Widget _buildFriendRequestButton(AppLocalizations l10n) {
    final disabled = widget.args.opponentFriendCode.isEmpty;
    final label = _friendRequestSent ? l10n.friendRequestSentLabel : l10n.sendFriendRequestLabel;
    final icon = _friendRequestSent ? Icons.check_rounded : Icons.person_add_alt_1_rounded;
    final bg = _friendRequestSent
        ? AppColors.success.withValues(alpha: 0.15)
        : AppColors.primary.withValues(alpha: 0.15);
    final fg = _friendRequestSent ? AppColors.success : AppColors.primary;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: (disabled || _friendRequestSent || _friendRequestLoading)
            ? null
            : () => _sendFriendRequest(l10n),
        icon: _friendRequestLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              )
            : Icon(icon, color: fg, size: 18),
        label: Text(label, style: AppTextStyles.labelLarge.copyWith(color: fg, fontSize: 14)),
        style: OutlinedButton.styleFrom(
          backgroundColor: bg,
          side: BorderSide(color: fg.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.headlineLarge.copyWith(color: color)),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: AppTextStyles.bodyMedium.copyWith(color: color, fontWeight: FontWeight.w700)),
    );
  }
}
