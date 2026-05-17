import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../core/constants/api_constants.dart';
import '../../../core/providers/app_providers.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// [cancelled] yalnız istifadəçinin sosial girişi ləğv etməsi üçündür — UI səssiz keçməlidir.
/// Digər kodlar həmişə istifadəçiyə xəta mesajı göstərməlidir.
enum AuthErrorCode { none, invalidCredentials, userExists, network, generic, cancelled }

class AuthState {
  final AuthStatus status;
  final String? username;
  final AuthErrorCode errorCode;
  /// Backend 403 device_mismatch qaytarıbsa true. Router bunu görüb
  /// `/claim-device` ekranına yönləndirir. OTP claim uğurla bitəndə
  /// `clearDeviceMismatch()` ilə təmizlənir.
  final bool deviceMismatch;

  const AuthState({
    this.status = AuthStatus.unknown,
    this.username,
    this.errorCode = AuthErrorCode.none,
    this.deviceMismatch = false,
  });

  String? get errorMessage => errorCode == AuthErrorCode.none ? null : errorCode.name;

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    AuthErrorCode? errorCode,
    bool? deviceMismatch,
  }) {
    return AuthState(
      status: status ?? this.status,
      username: username ?? this.username,
      errorCode: errorCode ?? AuthErrorCode.none,
      deviceMismatch: deviceMismatch ?? this.deviceMismatch,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final repo = ref.watch(authRepositoryProvider);

    // Supabase session expire/refresh-fail edəndə avtomatik unauthenticated et —
    // əks halda splash köhnə session-a güvənib home-a yönləndirir və profile boş gəlir.
    final sub = sb.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == sb.AuthChangeEvent.signedOut) {
        state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
      } else if (event == sb.AuthChangeEvent.signedIn ||
          event == sb.AuthChangeEvent.tokenRefreshed) {
        final user = data.session?.user;
        if (user != null) {
          state = AsyncData(AuthState(
            status: AuthStatus.authenticated,
            username: (user.userMetadata?['username'] as String?) ?? user.email,
          ));
        }
      }
    });
    ref.onDispose(sub.cancel);

    final user = repo.currentUser;
    final session = sb.Supabase.instance.client.auth.currentSession;
    // currentUser var, lakin session-da refresh token yoxdursa — sahib olmayan
    // state; bu halda unauthenticated qaytar ki, splash login-ə yönləndirsin.
    if (user != null && session?.refreshToken == null) {
      try { await repo.signOut(); } catch (_) {}
      return const AuthState(status: AuthStatus.unauthenticated);
    }
    return AuthState(
      status: user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
      username: (user?.userMetadata?['username'] as String?) ?? user?.email,
    );
  }

  Future<void> login(String identifier, String password) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      // Supabase Auth yalnız email/password dəstəkləyir — identifier email kimi qəbul olunur
      final res = await repo.signInWithEmail(email: identifier, password: password);
      state = AsyncData(AuthState(
        status: AuthStatus.authenticated,
        username: (res.user?.userMetadata?['username'] as String?) ?? res.user?.email,
      ));
    } on sb.AuthException catch (e) {
      state = AsyncData(AuthState(status: AuthStatus.unauthenticated, errorCode: _mapAuthError(e)));
    } catch (_) {
      state = AsyncData(const AuthState(status: AuthStatus.unauthenticated, errorCode: AuthErrorCode.generic));
    }
  }

  Future<AuthErrorCode> register(String username, String email, String password) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final res = await repo.signUpWithEmail(
        email: email,
        password: password,
        username: username,
      );
      if (res.user != null) {
        state = AsyncData(AuthState(
          status: AuthStatus.authenticated,
          username: username,
        ));
        return AuthErrorCode.none;
      }
      state = AsyncData(const AuthState(status: AuthStatus.unauthenticated, errorCode: AuthErrorCode.generic));
      return AuthErrorCode.generic;
    } on sb.AuthException catch (e) {
      final code = _mapAuthError(e);
      state = AsyncData(AuthState(status: AuthStatus.unauthenticated, errorCode: code));
      return code;
    } catch (_) {
      state = AsyncData(const AuthState(status: AuthStatus.unauthenticated, errorCode: AuthErrorCode.generic));
      return AuthErrorCode.generic;
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    try { await GoogleSignIn().signOut(); } catch (_) {}
    try { await FacebookAuth.instance.logOut(); } catch (_) {}
    await repo.signOut();
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }

  /// Dio interceptor 403 `device_mismatch` görəndə çağırır. State-də flag
  /// qaldırılır; router bunu listen edib `/claim-device` ekranına aparır.
  void markDeviceMismatch() {
    final cur = state.value ?? const AuthState();
    if (cur.deviceMismatch) return;
    state = AsyncData(cur.copyWith(deviceMismatch: true));
  }

  /// OTP claim uğurla bitirildi — bayrağı sıfırla ki, splash yenidən normal
  /// yönləndirsin.
  void clearDeviceMismatch() {
    final cur = state.value ?? const AuthState();
    if (!cur.deviceMismatch) return;
    state = AsyncData(cur.copyWith(deviceMismatch: false));
  }

  /// Native Google sign-in: google_sign_in plugin idToken alır,
  /// sonra Supabase Auth-a signInWithIdToken ilə ötürülür.
  /// `serverClientId` = Web Client ID (Supabase Auth bu ID ilə idToken-i yoxlayır).
  Future<AuthErrorCode> signInWithGoogle({String? serverClientId}) async {
    state = const AsyncLoading();
    try {
      final google = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: serverClientId ?? ApiConstants.googleWebClientId,
      );
      final account = await google.signIn();
      if (account == null) {
        debugPrint('[auth.google] cancelled by user');
        state = AsyncData(const AuthState(status: AuthStatus.unauthenticated));
        return AuthErrorCode.cancelled;
      }
      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;
      debugPrint('[auth.google] idToken=${idToken != null}, accessToken=${accessToken != null}');
      if (idToken == null) {
        debugPrint('[auth.google] idToken null — Web Client ID/SHA-1 konfiqurasiyası yoxla');
        state = AsyncData(const AuthState(status: AuthStatus.unauthenticated, errorCode: AuthErrorCode.generic));
        return AuthErrorCode.generic;
      }
      debugPrint('[auth.google] Supabase signInWithIdToken çağırılır...');
      final res = await ref.read(authRepositoryProvider).signInWithGoogleIdToken(
            idToken: idToken,
            accessToken: accessToken,
          );
      debugPrint('[auth.google] Supabase OK — user.id=${res.user?.id}, email=${res.user?.email}');
      state = AsyncData(AuthState(
        status: AuthStatus.authenticated,
        username: (res.user?.userMetadata?['username'] as String?) ?? res.user?.email,
      ));
      return AuthErrorCode.none;
    } on sb.AuthException catch (e) {
      debugPrint('[auth.google] Supabase auth error: ${e.message}');
      final code = _mapAuthError(e);
      state = AsyncData(AuthState(status: AuthStatus.unauthenticated, errorCode: code));
      return code;
    } catch (e, st) {
      debugPrint('[auth.google] failed: $e\n$st');
      state = AsyncData(const AuthState(status: AuthStatus.unauthenticated, errorCode: AuthErrorCode.generic));
      return AuthErrorCode.generic;
    }
  }

  /// Apple ilə giriş (yalnız iOS/macOS).
  Future<AuthErrorCode> signInWithApple() async {
    state = const AsyncLoading();
    try {
      final credential = await SignInWithApple.getAppleIDCredential(scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ]);
      final token = credential.identityToken;
      if (token == null) {
        state = AsyncData(const AuthState(status: AuthStatus.unauthenticated, errorCode: AuthErrorCode.generic));
        return AuthErrorCode.generic;
      }
      final res = await ref.read(authRepositoryProvider).signInWithAppleIdToken(idToken: token);
      state = AsyncData(AuthState(
        status: AuthStatus.authenticated,
        username: (res.user?.userMetadata?['username'] as String?) ?? res.user?.email,
      ));
      return AuthErrorCode.none;
    } on SignInWithAppleAuthorizationException catch (e) {
      debugPrint('[auth.apple] cancelled/denied: ${e.code}');
      state = AsyncData(const AuthState(status: AuthStatus.unauthenticated));
      return AuthErrorCode.cancelled;
    } on sb.AuthException catch (e) {
      debugPrint('[auth.apple] Supabase auth error: ${e.message}');
      final code = _mapAuthError(e);
      state = AsyncData(AuthState(status: AuthStatus.unauthenticated, errorCode: code));
      return code;
    } catch (e, st) {
      debugPrint('[auth.apple] failed: $e\n$st');
      state = AsyncData(const AuthState(status: AuthStatus.unauthenticated, errorCode: AuthErrorCode.generic));
      return AuthErrorCode.generic;
    }
  }

  /// Facebook girişi: idToken Supabase-də dəstəkləmir, OAuth flow lazımdır.
  /// Hələlik FacebookAuth ilə accessToken alınır, backend tərəfdə verify edilməlidir.
  /// Sadəlik üçün hələlik unimplemented — istifadəçiyə UI-da gizlədəcəyik.
  Future<AuthErrorCode> signInWithFacebook() async {
    debugPrint('[auth.facebook] Supabase signInWithIdToken Facebook-u dəstəkləmir');
    return AuthErrorCode.generic;
  }

  AuthErrorCode _mapAuthError(sb.AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials') ||
        msg.contains('email not confirmed')) {
      return AuthErrorCode.invalidCredentials;
    }
    if (msg.contains('user already registered') ||
        msg.contains('already registered') ||
        msg.contains('duplicate')) {
      return AuthErrorCode.userExists;
    }
    if (msg.contains('network') || msg.contains('timeout')) {
      return AuthErrorCode.network;
    }
    return AuthErrorCode.generic;
  }
}
