import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bu cihaza unique ID. İlk açılışda yaradılır və SharedPreferences-də qalır.
/// Tətbiq silinib yenidən qurulanda yeni ID yaranır — bu, "yeni cihaz"
/// kimi qiymətləndirilir (istifadəçi adına yenidən OTP claim lazım).
class DeviceIdService {
  static const _key = 'gguiz_device_id';
  String? _cached;

  Future<String> get() async {
    if (_cached != null) return _cached!;
    final p = await SharedPreferences.getInstance();
    final existing = p.getString(_key);
    if (existing != null && existing.isNotEmpty) {
      _cached = existing;
      return existing;
    }
    final id = _generate();
    await p.setString(_key, id);
    _cached = id;
    return id;
  }

  /// Cache-i sıfırla (məs. sign-out + yeni hesab kimi). DB-də saxlanılan
  /// active_device_id yenidən qurulmuş device-i bilməyəcək, normal axın işləyir.
  Future<void> reset() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_key);
    _cached = null;
  }

  String _generate() {
    // UUID-v4-vari: 32 hex + timestamp prefiksli, kifayət qədər unique.
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final id = '$ts-$hex';
    debugPrint('[device_id] generated: $id');
    return id;
  }
}

/// İstifadəçi adı seçildikdə (məs. profil sheet-ində) və ya OTP claim
/// zamanı ötürülən label — backend-də göstərmək üçün.
String deviceLabel() => defaultTargetPlatform.name;

final deviceIdServiceProvider = Provider<DeviceIdService>((ref) => DeviceIdService());

/// Async deviceId. Dio interceptor sinxron olduğu üçün ilk çağırışdan əvvəl
/// `ref.read(deviceIdServiceProvider).get()`-i await etmək lazımdır
/// (məs. main()-də).
final deviceIdProvider = FutureProvider<String>((ref) async {
  return ref.read(deviceIdServiceProvider).get();
});
