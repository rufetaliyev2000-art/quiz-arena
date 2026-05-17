import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../network/api_client.dart';
import 'device_id_provider.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/providers/auth_provider.dart';

final storageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final dioProvider = Provider<Dio>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final deviceIdService = ref.watch(deviceIdServiceProvider);
  return ApiClient.create(
    supabase,
    deviceIdService,
    onDeviceMismatch: () {
      // Auth provider state-ində bayrağı qaldır — router bunu listen edib
      // /claim-device ekranına yönləndirir.
      ref.read(authProvider.notifier).markDeviceMismatch();
    },
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
