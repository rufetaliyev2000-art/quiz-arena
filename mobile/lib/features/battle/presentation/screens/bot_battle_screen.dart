import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gguiz_battle/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/data/quiz_questions.dart';
import '../../../../core/providers/local_game_stats_provider.dart';
import '../../../home/data/user_repository.dart';
import '../../../home/providers/user_provider.dart';
import '../../../missions/data/daily_mission.dart';
import '../../../missions/providers/daily_missions_provider.dart';
import '../widgets/level_up_overlay.dart';

class BotBattleScreen extends ConsumerStatefulWidget {
  const BotBattleScreen({super.key});

  @override
  ConsumerState<BotBattleScreen> createState() => _BotBattleScreenState();
}

class _BotBattleScreenState extends ConsumerState<BotBattleScreen> with TickerProviderStateMixin {
  static const _totalTime = 15;
  static const _botAccuracy = 0.65;
  static const _questionsPerGame = 10;

  final _random = Random();
  String _locale = 'az';
  int _currentQ = 0;
  int _playerScore = 0;
  int _botScore = 0;
  int _timeLeft = _totalTime;
  int? _playerAnswer;
  int? _botAnswer;
  bool _answered = false;
  bool _botAnswered = false;
  bool _showResult = false;
  bool _rewardSaved = false;

  Timer? _timer;
  Timer? _botTimer;
  late List<QuizQuestion> _questions;
  late AnimationController _timerCtrl;

  @override
  void initState() {
    super.initState();
    _questions = pickRandomQuestions(_questionsPerGame);
    _timerCtrl = AnimationController(vsync: this, duration: const Duration(seconds: _totalTime));
    _startRound();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = Localizations.localeOf(context).languageCode;
  }

  void _startRound() {
    _answered = false;
    _botAnswered = false;
    _playerAnswer = null;
    _botAnswer = null;
    _timeLeft = _totalTime;
    _timerCtrl.forward(from: 0);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        _botTimer?.cancel();
        if (!_botAnswered) {
          setState(() {
            _botAnswer = null;
            _botAnswered = true;
          });
        }
        Future.delayed(const Duration(milliseconds: 600), _nextOrResult);
      } else {
        setState(() => _timeLeft--);
      }
    });

    final botDelay = Duration(milliseconds: 2000 + _random.nextInt(6000));
    _botTimer = Timer(botDelay, () {
      if (!_answered && mounted) {
        final q = _questions[_currentQ];
        final correct = _random.nextDouble() < _botAccuracy;
        int botChoice;
        if (correct) {
          botChoice = q.correct;
        } else {
          final wrong = List.generate(4, (i) => i)..remove(q.correct);
          botChoice = wrong[_random.nextInt(wrong.length)];
        }
        setState(() {
          _botAnswer = botChoice;
          _botAnswered = true;
          if (botChoice == q.correct) _botScore++;
        });
      }
    });
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    _timer?.cancel();
    _botTimer?.cancel();
    _timerCtrl.stop();
    final q = _questions[_currentQ];
    final isCorrect = index == q.correct;
    setState(() {
      _playerAnswer = index;
      _answered = true;
      if (isCorrect) _playerScore++;
    });
    if (isCorrect) {
      final missions = ref.read(dailyMissionsProvider.notifier);
      missions.incrementProgress(MissionType.answerCorrect, 1);
      // 5 san ərzində: keçən vaxt < 5 → _timeLeft > 10
      if (_timeLeft > _totalTime - 5) {
        missions.incrementProgress(MissionType.fastAnswer, 1);
      }
    }
    if (!_botAnswered) {
      final botDelay = Duration(milliseconds: 500 + _random.nextInt(1500));
      Timer(botDelay, () {
        if (mounted) {
          final correct = _random.nextDouble() < _botAccuracy;
          int botChoice;
          if (correct) {
            botChoice = q.correct;
          } else {
            final wrong = List.generate(4, (i) => i)..remove(q.correct);
            botChoice = wrong[_random.nextInt(wrong.length)];
          }
          setState(() {
            _botAnswer = botChoice;
            _botAnswered = true;
            if (botChoice == q.correct) _botScore++;
          });
          Future.delayed(const Duration(milliseconds: 800), _nextOrResult);
        }
      });
    } else {
      Future.delayed(const Duration(milliseconds: 1200), _nextOrResult);
    }
  }

  void _nextOrResult() {
    if (!mounted) return;
    if (_currentQ < _questions.length - 1) {
      setState(() => _currentQ++);
      _startRound();
    } else {
      setState(() => _showResult = true);
    }
  }

  void _restart() {
    setState(() {
      _questions = pickRandomQuestions(_questionsPerGame);
      _currentQ = 0;
      _playerScore = 0;
      _botScore = 0;
      _showResult = false;
      _rewardSaved = false;
    });
    _startRound();
  }

  Future<void> _saveRewardOnce(int xp, int coins, GameOutcome outcome) async {
    if (_rewardSaved) return;
    _rewardSaved = true;

    // Level-up detection: pre-reward total XP
    final profile = ref.read(userProfileProvider).valueOrNull;
    final bonusXp = ref.read(localGameStatsProvider).bonusXp;
    final oldTotalXp = (profile?.xp ?? 0) + bonusXp;
    final oldLevel = UserProfile.levelFromXp(oldTotalXp);

    await ref.read(localGameStatsProvider.notifier).addReward(
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
    if (newLevel > oldLevel && mounted) {
      await showLevelUpOverlay(context, oldLevel: oldLevel, newLevel: newLevel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _botTimer?.cancel();
    _timerCtrl.dispose();
    super.dispose();
  }

  Color _optionColor(int index) {
    if (!_answered) return AppColors.surfaceLight;
    final correct = _questions[_currentQ].correct;
    if (index == correct) return AppColors.correctAnswer.withValues(alpha: 0.25);
    if (index == _playerAnswer && index != correct) return AppColors.wrongAnswer.withValues(alpha: 0.25);
    return AppColors.surfaceLight;
  }

  Color _optionBorder(int index) {
    if (!_answered) return const Color(0xFF2A2A40);
    final correct = _questions[_currentQ].correct;
    if (index == correct) return AppColors.correctAnswer;
    if (index == _playerAnswer && index != correct) return AppColors.wrongAnswer;
    return const Color(0xFF2A2A40);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                _buildTopBar(context, l10n),
                const SizedBox(height: 16),
                _buildScoreRow(l10n),
                const SizedBox(height: 16),
                _buildQuestionCard(q.questionFor(_locale)),
                const SizedBox(height: 20),
                _buildBotStatus(l10n),
                const SizedBox(height: 14),
                ...options.asMap().entries.map((e) =>
                  _buildOption(e.key, e.value, optionLabels[e.key], optionColors[e.key])
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            _timer?.cancel();
            _botTimer?.cancel();
            context.go('/home');
          },
        ),
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
              Text(
                '$_timeLeft',
                style: AppTextStyles.timerText.copyWith(
                  fontSize: 16,
                  color: _timeLeft <= 5 ? AppColors.error : AppColors.accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRow(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                Text(l10n.youLabel, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primaryLight)),
                const SizedBox(height: 4),
                Text('$_playerScore', style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary)),
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
                Text(l10n.botLabel, style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
                const SizedBox(height: 4),
                Text('$_botScore', style: AppTextStyles.headlineLarge.copyWith(color: AppColors.error)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotStatus(AppLocalizations l10n) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _botAnswered
            ? (_botAnswer == _questions[_currentQ].correct
                ? AppColors.correctAnswer.withValues(alpha: 0.1)
                : AppColors.error.withValues(alpha: 0.1))
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _botAnswered
              ? (_botAnswer == _questions[_currentQ].correct ? AppColors.correctAnswer : AppColors.error)
              : const Color(0xFF2A2A50),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('??', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            _botAnswered ? l10n.botAnswered : l10n.botThinking,
            style: AppTextStyles.bodySmall.copyWith(
              color: _botAnswered
                  ? (_botAnswer == _questions[_currentQ].correct ? AppColors.correctAnswer : AppColors.error)
                  : AppColors.textMuted,
            ),
          ),
          if (!_botAnswered) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(color: AppColors.textMuted, strokeWidth: 2),
            ),
          ],
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
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 20)],
      ),
      child: Text(question, style: AppTextStyles.questionText),
    ).animate(key: ValueKey(_currentQ)).fadeIn().slideY(begin: -0.1);
  }

  Widget _buildOption(int index, String text, String label, Color labelColor) {
    final isBotChoice = _botAnswered && _botAnswer == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _selectAnswer(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _optionColor(index),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _optionBorder(index), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: labelColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(child: Text(label, style: AppTextStyles.labelLarge.copyWith(color: labelColor))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: AppTextStyles.optionText)),
              if (_answered && index == _questions[_currentQ].correct)
                const Icon(Icons.check_circle, color: AppColors.correctAnswer, size: 18),
              if (_answered && index == _playerAnswer && index != _questions[_currentQ].correct)
                const Icon(Icons.cancel, color: AppColors.wrongAnswer, size: 18),
              if (isBotChoice && _answered) ...[
                const SizedBox(width: 4),
                const Text('??', style: TextStyle(fontSize: 14)),
              ],
            ],
          ),
        ),
      ),
    ).animate(key: ValueKey('$_currentQ-$index')).fadeIn(delay: Duration(milliseconds: 80 + index * 60)).slideX(begin: 0.1);
  }

  Widget _buildResultScreen(AppLocalizations l10n) {
    final isWin = _playerScore > _botScore;
    final isDraw = _playerScore == _botScore;
    final resultText = isDraw ? l10n.drawResult : (isWin ? l10n.youWon : l10n.botWon);
    final earnedXp = isWin ? 200 : (isDraw ? 100 : 50);
    final earnedCoins = isWin ? 150 : (isDraw ? 75 : 25);
    final outcome = isWin ? GameOutcome.win : (isDraw ? GameOutcome.draw : GameOutcome.loss);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveRewardOnce(earnedXp, earnedCoins, outcome);
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isWin ? '🏆' : (isDraw ? '🤝' : '??'),
                  style: const TextStyle(fontSize: 72),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(resultText, style: AppTextStyles.headlineLarge.copyWith(
                  color: isWin ? AppColors.success : (isDraw ? AppColors.accent : AppColors.error),
                )).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildResultStat(l10n.yourScore, '$_playerScore/${_questions.length}', AppColors.primary)),
                      Container(width: 1, height: 60, color: const Color(0xFF2A2A40)),
                      Expanded(child: _buildResultStat(l10n.botScore, '$_botScore/${_questions.length}', AppColors.error)),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        l10n.xpEarned(earnedXp),
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        l10n.coinsEarned(earnedCoins),
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.gold, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _restart,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: AppColors.gradientPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(l10n.playAgain, style: AppTextStyles.labelLarge.copyWith(fontSize: 15, letterSpacing: 2)),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(l10n.doneButton, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.headlineLarge.copyWith(color: color)),
      ],
    );
  }
}
