import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gguiz_battle/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/data/quiz_questions.dart';
import '../../../../core/providers/local_game_stats_provider.dart';
import '../../../missions/data/daily_mission.dart';
import '../../../missions/providers/daily_missions_provider.dart';

class SoloQuizScreen extends ConsumerStatefulWidget {
  const SoloQuizScreen({super.key});

  @override
  ConsumerState<SoloQuizScreen> createState() => _SoloQuizScreenState();
}

class _SoloQuizScreenState extends ConsumerState<SoloQuizScreen> with TickerProviderStateMixin {
  static const _totalTime = 15;
  static const _questionsPerGame = 10;

  String _locale = 'az';
  int _currentQ = 0;
  int _score = 0;
  int _timeLeft = _totalTime;
  int? _selectedAnswer;
  bool _answered = false;
  bool _showResult = false;
  bool _rewardSaved = false;
  Timer? _timer;

  late List<QuizQuestion> _questions;
  late AnimationController _progressCtrl;

  @override
  void initState() {
    super.initState();
    _questions = pickRandomQuestions(_questionsPerGame);
    _progressCtrl = AnimationController(vsync: this, duration: const Duration(seconds: _totalTime));
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _locale = Localizations.localeOf(context).languageCode;
  }

  void _startTimer() {
    _answered = false;
    _selectedAnswer = null;
    _timeLeft = _totalTime;
    _progressCtrl.forward(from: 0);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft <= 1) {
        t.cancel();
        Future.delayed(const Duration(milliseconds: 600), _nextOrResult);
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _selectAnswer(int index) {
    if (_answered) return;
    _timer?.cancel();
    _progressCtrl.stop();
    final isCorrect = index == _questions[_currentQ].correct;
    setState(() {
      _selectedAnswer = index;
      _answered = true;
      if (isCorrect) _score++;
    });
    if (isCorrect) {
      final missions = ref.read(dailyMissionsProvider.notifier);
      missions.incrementProgress(MissionType.answerCorrect, 1);
      if (_timeLeft > _totalTime - 5) {
        missions.incrementProgress(MissionType.fastAnswer, 1);
      }
    }
    Future.delayed(const Duration(milliseconds: 1200), _nextOrResult);
  }

  void _nextOrResult() {
    if (!mounted) return;
    if (_currentQ < _questions.length - 1) {
      setState(() => _currentQ++);
      _startTimer();
    } else {
      setState(() => _showResult = true);
    }
  }

  void _restart() {
    setState(() {
      _questions = pickRandomQuestions(_questionsPerGame);
      _currentQ = 0;
      _score = 0;
      _showResult = false;
      _rewardSaved = false;
    });
    _startTimer();
  }

  void _saveRewardOnce(int xp, int coins) {
    if (_rewardSaved) return;
    _rewardSaved = true;
    final outcome = _score >= (_questions.length * 0.7).round()
        ? GameOutcome.win
        : GameOutcome.loss;
    ref.read(localGameStatsProvider.notifier).addReward(
          xp: xp,
          coins: coins,
          outcome: outcome,
        );
    // Solo "match" sayılır, lakin winMatch və streak yalnız 1v1/bot üçün.
    ref.read(dailyMissionsProvider.notifier).incrementProgress(MissionType.playMatch, 1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressCtrl.dispose();
    super.dispose();
  }

  Color _optionColor(int index) {
    if (!_answered) return AppColors.surfaceLight;
    final correct = _questions[_currentQ].correct;
    if (index == correct) return AppColors.correctAnswer.withValues(alpha: 0.25);
    if (index == _selectedAnswer && index != correct) return AppColors.wrongAnswer.withValues(alpha: 0.25);
    return AppColors.surfaceLight;
  }

  Color _optionBorder(int index) {
    if (!_answered) return const Color(0xFF2A2A40);
    final correct = _questions[_currentQ].correct;
    if (index == correct) return AppColors.correctAnswer;
    if (index == _selectedAnswer && index != correct) return AppColors.wrongAnswer;
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
                _buildProgressBar(l10n),
                const SizedBox(height: 24),
                _buildQuestionCard(q.questionFor(_locale)),
                const SizedBox(height: 20),
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

  Widget _buildProgressBar(AppLocalizations l10n) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.scoreLabel(_score), style: AppTextStyles.bodyMedium),
            Text('+${_score * 100} XP', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accent)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (_currentQ + 1) / _questions.length,
            backgroundColor: AppColors.surfaceLight,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            minHeight: 6,
          ),
        ),
      ],
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _selectAnswer(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _optionColor(index),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _optionBorder(index), width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: labelColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                child: Center(child: Text(label, style: AppTextStyles.labelLarge.copyWith(color: labelColor))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Text(text, style: AppTextStyles.optionText)),
              if (_answered && index == _questions[_currentQ].correct)
                const Icon(Icons.check_circle, color: AppColors.correctAnswer, size: 20),
              if (_answered && index == _selectedAnswer && index != _questions[_currentQ].correct)
                const Icon(Icons.cancel, color: AppColors.wrongAnswer, size: 20),
            ],
          ),
        ),
      ),
    ).animate(key: ValueKey('$_currentQ-$index')).fadeIn(delay: Duration(milliseconds: 100 + index * 80)).slideX(begin: 0.1);
  }

  Widget _buildResultScreen(AppLocalizations l10n) {
    final percent = (_score / _questions.length * 100).round();
    final isGood = percent >= 70;
    final earnedXp = _score * 100;
    final earnedCoins = _score * 50;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveRewardOnce(earnedXp, earnedCoins);
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  isGood ? '🏆' : '📚',
                  style: const TextStyle(fontSize: 72),
                ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                const SizedBox(height: 16),
                Text(l10n.quizComplete, style: AppTextStyles.headlineLarge).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  '$percent%',
                  style: AppTextStyles.headlineLarge.copyWith(
                    fontSize: 48,
                    color: isGood ? AppColors.success : AppColors.accent,
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStat('✅', '$_score', l10n.totalWins),
                      Container(width: 1, height: 50, color: const Color(0xFF2A2A40)),
                      _buildStat('❌', '${_questions.length - _score}', l10n.losses),
                      Container(width: 1, height: 50, color: const Color(0xFF2A2A40)),
                      _buildStat('📊', '$percent%', l10n.winRate),
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

  Widget _buildStat(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: AppTextStyles.headlineLarge.copyWith(fontSize: 22)),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
