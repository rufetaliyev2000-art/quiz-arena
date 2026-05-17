import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gguiz_battle/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/device_id_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../home/providers/user_provider.dart';

/// Sosial girişdən sonra göstərilir — bu cihazı yeganə aktiv cihaz kimi qeyd
/// edir. OTP göndərimi Supabase Auth (`signInWithOtp`) tərəfindən, verify isə
/// `verifyOtp`. Uğurlu verify sonra `claim_device` RPC backend bayraqları set
/// edir (signup_otp_verified=true, active_device_id=current).
class SignupOtpScreen extends ConsumerStatefulWidget {
  const SignupOtpScreen({super.key});

  @override
  ConsumerState<SignupOtpScreen> createState() => _SignupOtpScreenState();
}

class _SignupOtpScreenState extends ConsumerState<SignupOtpScreen> {
  final _ctrl = TextEditingController();
  bool _sending = false;
  bool _verifying = false;
  String? _error;
  String? _info;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendOtp(initial: true));
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _startCooldown() {
    setState(() => _cooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _cooldown -= 1);
      if (_cooldown <= 0) t.cancel();
    });
  }

  String? _myEmail() {
    return ref.read(supabaseClientProvider).auth.currentUser?.email;
  }

  Future<void> _sendOtp({bool initial = false}) async {
    if (_sending || _cooldown > 0) return;
    final email = _myEmail();
    if (email == null) {
      setState(() => _error = AppLocalizations.of(context)!.errorGeneric);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      if (!initial) _info = null;
    });
    try {
      await ref.read(supabaseClientProvider).auth.signInWithOtp(
            email: email,
            shouldCreateUser: false,
          );
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _sending = false;
        _info = l10n.signupOtpSent;
      });
      _startCooldown();
    } on AuthException catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _sending = false;
        _error = e.message.toLowerCase().contains('rate')
            ? l10n.errorGeneric
            : l10n.signupOtpInvalid;
      });
    } catch (_) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _sending = false;
        _error = l10n.errorGeneric;
      });
    }
  }

  Future<void> _verify() async {
    final l10n = AppLocalizations.of(context)!;
    final code = _ctrl.text.trim();
    final email = _myEmail();
    if (code.length != 6) {
      setState(() => _error = l10n.otpCodeLength);
      return;
    }
    if (email == null) {
      setState(() => _error = l10n.errorGeneric);
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
      _info = null;
    });
    try {
      final supabase = ref.read(supabaseClientProvider);
      await supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );
      // OTP doğrulandı → bu cihazı claim et (signup_otp_verified=true,
      // active_device_id=current).
      final deviceId = await ref.read(deviceIdServiceProvider).get();
      await supabase.rpc('claim_device', params: {
        'p_device_id': deviceId,
        'p_device_label': deviceLabel(),
      });
      if (!mounted) return;
      ref.invalidate(userProfileProvider);
      context.go('/setup-username');
    } on AuthException catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = l10n.signupOtpInvalid;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = l10n.errorGeneric;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientBackground),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Icon(Icons.mark_email_read_rounded, size: 64, color: AppColors.primaryLight)
                    .animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                const SizedBox(height: 20),
                Text(l10n.signupOtpTitle, style: AppTextStyles.displayMedium, textAlign: TextAlign.center)
                    .animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                const SizedBox(height: 10),
                Text(l10n.signupOtpSubtitle,
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center)
                    .animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 36),
                if (_error != null) ...[
                  _banner(_error!, AppColors.error, Icons.error_outline_rounded),
                  const SizedBox(height: 14),
                ] else if (_info != null) ...[
                  _banner(_info!, AppColors.success, Icons.check_circle_outline_rounded),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _ctrl,
                  style: AppTextStyles.headlineMedium.copyWith(letterSpacing: 8),
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: '______',
                    hintStyle: AppTextStyles.headlineMedium.copyWith(
                      letterSpacing: 8,
                      color: AppColors.textMuted.withValues(alpha: 0.4),
                    ),
                    counterText: '',
                  ),
                ).animate().fadeIn(delay: 300.ms),
                const SizedBox(height: 26),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _verifying ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: _verifying ? null : AppColors.gradientPrimary,
                        color: _verifying ? AppColors.surfaceLight : null,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: _verifying
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(l10n.signupOtpVerify,
                                style: AppTextStyles.labelLarge.copyWith(fontSize: 14, letterSpacing: 2)),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: (_cooldown > 0 || _sending) ? null : () => _sendOtp(),
                    child: Text(
                      _cooldown > 0 ? l10n.signupOtpResendIn(_cooldown) : l10n.signupOtpResend,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _cooldown > 0 ? AppColors.textMuted : AppColors.primaryLight,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _banner(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: AppTextStyles.bodyMedium.copyWith(color: color))),
      ]),
    ).animate().fadeIn(duration: 200.ms);
  }
}
