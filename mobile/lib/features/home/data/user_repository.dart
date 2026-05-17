import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProfile {
  final String id;
  final String username;
  final String? email;
  final String? avatar;
  final int xp;
  final int level;
  final int coins;
  final int elo;
  final int wins;
  final int losses;
  final bool isPremium;
  final bool usernameSet;
  final bool signupOtpVerified;
  final String friendCode;

  const UserProfile({
    required this.id,
    required this.username,
    this.email,
    this.avatar,
    required this.xp,
    required this.level,
    required this.coins,
    required this.elo,
    required this.wins,
    required this.losses,
    required this.isPremium,
    required this.usernameSet,
    required this.signupOtpVerified,
    required this.friendCode,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
        id: j['id'] as String,
        username: j['username'] as String,
        email: j['email'] as String?,
        avatar: j['avatar'] as String?,
        xp: (j['xp'] as num).toInt(),
        level: (j['level'] as num).toInt(),
        coins: (j['coins'] as num).toInt(),
        elo: (j['elo'] as num).toInt(),
        wins: (j['wins'] as num).toInt(),
        losses: (j['losses'] as num).toInt(),
        isPremium: j['is_premium'] as bool? ?? false,
        usernameSet: j['username_set'] as bool? ?? true,
        signupOtpVerified: j['signup_otp_verified'] as bool? ?? true,
        friendCode: (j['friend_code'] as String?) ?? '',
      );

  factory UserProfile.offline({required String username, String? email}) =>
      UserProfile(
        id: 'offline_user',
        username: username,
        email: email,
        avatar: null,
        xp: 0,
        level: 1,
        coins: 0,
        elo: 1000,
        wins: 0,
        losses: 0,
        isPremium: false,
        usernameSet: true,
        signupOtpVerified: true,
        friendCode: '',
      );

  int get totalGames => wins + losses;
  double get winRate => totalGames == 0 ? 0 : wins / totalGames;

  /// Səviyyə sistemi qaydaları:
  /// - Lv 1 → 2 üçün 1000 XP lazımdır.
  /// - Hər növbəti səviyyə üçün lazım olan XP `current * 1000`-dir
  ///   (Lv n → n+1 üçün n*1000 XP).
  /// - Maksimum səviyyə [maxLevel]; XP davam edə bilər, level dayanır.
  /// - Lv N-ə çatmaq üçün cəmi `500 * N * (N-1)` XP lazımdır.
  static const int maxLevel = 100;
  static const int xpBase = 1000;

  /// Lv n → n+1 üçün lazım olan XP.
  static int xpToAdvance(int currentLevel) => currentLevel * xpBase;

  /// Lv [level]-in başlanğıcında olmaq üçün cəmi lazım olan XP (Lv 1 = 0).
  static int totalXpForLevel(int level) {
    if (level <= 1) return 0;
    return (xpBase ~/ 2) * level * (level - 1);
  }

  /// Cəmi XP-dən səviyyə (Lv 1..maxLevel).
  /// `T(N) = 500 * N * (N-1) <= xp` bərabərsizliyinin həlli:
  /// `N = floor((1 + sqrt(1 + 8 * xp / xpBase)) / 2)`.
  static int levelFromXp(int totalXp) {
    if (totalXp <= 0) return 1;
    final disc = 1 + 8 * totalXp / xpBase;
    final n = (1 + math.sqrt(disc)) / 2;
    final lvl = n.floor();
    if (lvl < 1) return 1;
    if (lvl > maxLevel) return maxLevel;
    return lvl;
  }

  /// Cari səviyyədə qazanılan XP (cari səviyyənin sıfır xəttindən başlayaraq).
  static int xpInLevel(int totalXp) {
    final lvl = levelFromXp(totalXp);
    return totalXp - totalXpForLevel(lvl);
  }

  /// Cari səviyyədə proqress (0.0 - 1.0). Max səviyyədə həmişə 1.0.
  static double progressForXp(int totalXp) {
    final lvl = levelFromXp(totalXp);
    if (lvl >= maxLevel) return 1.0;
    final needed = xpToAdvance(lvl);
    if (needed == 0) return 0;
    return (xpInLevel(totalXp) / needed).clamp(0.0, 1.0);
  }
}

class UserRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  const UserRepository(this._dio, this._storage);

  Future<UserProfile> getMe() async {
    try {
      // ignore: avoid_print
      print('[user_repo] GET /users/me başlayır');
      final response = await _dio.get('/users/me');
      // ignore: avoid_print
      print('[user_repo] GET /users/me OK status=${response.statusCode}');
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      // ignore: avoid_print
      print('[user_repo] GET /users/me failed: type=${e.type} status=${e.response?.statusCode} data=${e.response?.data}');
      if (_isNetworkError(e)) {
        final username = await _storage.read(key: 'username') ?? 'Player';
        final email = await _storage.read(key: 'email');
        return UserProfile.offline(username: username, email: email);
      }
      rethrow;
    }
  }

  /// Username dəyiş + username_set=true et. 409 → istifadəçi adı tutulub.
  Future<UserProfile> setUsername(String username) async {
    final response = await _dio.patch(
      '/users/me/username',
      data: {'username': username},
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  /// Canlı yoxlama: bu username istifadəçi tərəfindən götürülə bilərmi?
  /// `reason`: null | 'min_three_chars' | 'format' | 'taken'.
  Future<({bool available, String? reason})> checkUsernameAvailable(String username) async {
    final response = await _dio.get(
      '/users/username-available',
      queryParameters: {'name': username},
    );
    final data = response.data as Map<String, dynamic>;
    return (
      available: data['available'] as bool? ?? false,
      reason: data['reason'] as String?,
    );
  }

  /// Bot/solo oyunlarından lokal queue-da yığılan mükafatları backend-ə
  /// göndərir. Şəbəkə xətası halında [DioException] tullayır — çağıran
  /// lokal queue-da saxlayır və sonradan təkrar göndərir.
  Future<UserProfile> applyReward({
    int xp = 0,
    int coins = 0,
    int wins = 0,
    int losses = 0,
    int draws = 0,
  }) async {
    final response = await _dio.post(
      '/users/me/reward',
      data: {
        'xp': xp,
        'coins': coins,
        'wins': wins,
        'losses': losses,
        'draws': draws,
      },
    );
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  bool _isNetworkError(DioException e) {
    return e.response == null ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.unknown;
  }
}
