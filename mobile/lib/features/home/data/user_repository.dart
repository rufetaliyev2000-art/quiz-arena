import 'dart:math' as math;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

/// Səhv kodlarını strukturlu formada ötürmək üçün — Supabase PostgrestException
/// `code` (SQLSTATE) və `message` qaytarır. Bu wrap onları konkret tipə salır.
class UsernameTakenException implements Exception {
  const UsernameTakenException();
}
class UsernameFormatException implements Exception {
  const UsernameFormatException();
}

class UserRepository {
  final SupabaseClient _client;
  final FlutterSecureStorage _storage;
  const UserRepository(this._client, this._storage);

  Future<UserProfile> getMe() async {
    try {
      // ignore: avoid_print
      print('[user_repo] rpc get_my_profile başlayır');
      final response = await _client.rpc('get_my_profile');
      // ignore: avoid_print
      print('[user_repo] rpc get_my_profile OK');
      return UserProfile.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      // ignore: avoid_print
      print('[user_repo] rpc get_my_profile failed: code=${e.code} message=${e.message}');
      rethrow;
    } catch (e) {
      // ignore: avoid_print
      print('[user_repo] rpc get_my_profile network error: $e');
      final username = await _storage.read(key: 'username') ?? 'Player';
      final email = await _storage.read(key: 'email');
      return UserProfile.offline(username: username, email: email);
    }
  }

  /// Username dəyiş + username_set=true et. `username_taken` → istifadəçi adı tutulub.
  Future<UserProfile> setUsername(String username) async {
    try {
      final response = await _client.rpc('set_username', params: {'p_name': username});
      return UserProfile.fromJson(response as Map<String, dynamic>);
    } on PostgrestException catch (e) {
      if (e.message.contains('username_taken') || e.code == '23505') {
        throw const UsernameTakenException();
      }
      if (e.message.contains('username_format') ||
          e.message.contains('min_three_chars') ||
          e.code == '22023') {
        throw const UsernameFormatException();
      }
      rethrow;
    }
  }

  /// Canlı yoxlama: bu username istifadəçi tərəfindən götürülə bilərmi?
  /// `reason`: null | 'min_three_chars' | 'format' | 'taken'.
  Future<({bool available, String? reason})> checkUsernameAvailable(String username) async {
    final response = await _client.rpc('is_username_available', params: {'p_name': username});
    final list = response as List<dynamic>;
    if (list.isEmpty) return (available: false, reason: 'format');
    final row = list.first as Map<String, dynamic>;
    return (
      available: row['available'] as bool? ?? false,
      reason: row['reason'] as String?,
    );
  }

  /// Bot/solo oyunlarından lokal queue-da yığılan mükafatları backend-ə
  /// göndərir. Şəbəkə xətası halında [Exception] tullayır — çağıran
  /// lokal queue-da saxlayır və sonradan təkrar göndərir.
  Future<UserProfile> applyReward({
    int xp = 0,
    int coins = 0,
    int wins = 0,
    int losses = 0,
    int draws = 0,
  }) async {
    final response = await _client.rpc('apply_local_reward', params: {
      'p_xp': xp,
      'p_coins': coins,
      'p_wins': wins,
      'p_losses': losses,
      'p_draws': draws,
    });
    return UserProfile.fromJson(response as Map<String, dynamic>);
  }
}
