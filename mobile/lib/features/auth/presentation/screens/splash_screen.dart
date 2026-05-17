import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gguiz_battle/app_localizations.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/gguiz_logo.dart';
import '../../../home/providers/user_provider.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Minimum splash gÃ¶zlÉ™mÉ™si 1.5s, sonra dÉ™rhal yoxla
    Future.delayed(const Duration(milliseconds: 1500), _maybeNavigate);
    // Maksimum 4s sonra fallback /login
    Future.delayed(const Duration(seconds: 4), _forceNavigateToLogin);
  }

  void _maybeNavigate() {
    if (_navigated || !mounted) return;
    final authState = ref.read(authProvider);
    final s = authState.value;
    if (s == null) return; // hələ Loading

    // Authenticated deyilsə birbaşa login-ə.
    if (s.status != AuthStatus.authenticated) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/login');
      });
      return;
    }

    // Cihaz uyğunsuzluğu varsa router redirect /claim-device-ə aparacaq —
    // burada ekstra GET /users/me etməyə ehtiyac yoxdur (yenə 403 olacaq).
    if (s.deviceMismatch) {
      _navigated = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/claim-device');
      });
      return;
    }

    // Profile-i yüklə və signupOtpVerified / usernameSet bayraqlarına görə yönlən.
    _navigated = true;
    _resolveAndNavigate();
  }

  Future<void> _resolveAndNavigate() async {
    try {
      final profile = await ref.read(userProfileProvider.future);
      if (!mounted) return;
      String target;
      if (!profile.signupOtpVerified) {
        target = '/signup-otp';
      } else if (!profile.usernameSet) {
        target = '/setup-username';
      } else {
        target = '/home';
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(target);
      });
    } catch (_) {
      // /users/me 403 device_mismatch atırsa interceptor authProvider-i
      // işarələyəcək — listener bunu görüb yenidən _maybeNavigate çağırır.
      // Şəbəkə xətasında /home-a yönləndiririk (offline UserProfile fallback).
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/home');
      });
    }
  }

  void _forceNavigateToLogin() {
    if (_navigated || !mounted) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.go('/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authProvider, (_, __) => _maybeNavigate());

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.06),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GguizLogo(size: 120)
                    .animate()
                    .scale(duration: 700.ms, curve: Curves.elasticOut)
                    .fadeIn(duration: 500.ms),
                const SizedBox(height: 28),
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.primary, AppColors.cyan],
                  ).createShader(bounds),
                  child: Text(
                    'GGUIZ BATTLE',
                    style: AppTextStyles.displayLarge.copyWith(
                      color: Colors.white,
                      letterSpacing: 6,
                      fontSize: 32,
                    ),
                  ),
                )
                    .animate()
                    .slideY(begin: 0.4, duration: 600.ms, delay: 300.ms, curve: Curves.easeOut)
                    .fadeIn(duration: 600.ms, delay: 300.ms),
                const SizedBox(height: 8),
                Text(
                  l10n.tagline,
                  style: AppTextStyles.bodyMedium.copyWith(
                    letterSpacing: 4,
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ).animate().fadeIn(duration: 600.ms, delay: 700.ms),
                const SizedBox(height: 80),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (i) {
                    return Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(delay: Duration(milliseconds: 1000 + i * 150))
                        .fadeIn(duration: 400.ms)
                        .then()
                        .fadeOut(duration: 400.ms)
                        .animate(onPlay: (c) => c.repeat(reverse: true));
                  }),
                ).animate().fadeIn(duration: 400.ms, delay: 900.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

