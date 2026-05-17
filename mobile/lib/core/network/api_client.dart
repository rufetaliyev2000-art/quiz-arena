import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/device_id_provider.dart';
import 'api_endpoints.dart';

class ApiClient {
  ApiClient._();

  static Dio create(
    SupabaseClient supabase,
    DeviceIdService deviceIdService, {
    required VoidCallback onDeviceMismatch,
  }) {
    final dio = Dio(BaseOptions(
      baseUrl: ApiEndpoints.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(_AuthAndDeviceInterceptor(
      supabase,
      deviceIdService,
      onDeviceMismatch: onDeviceMismatch,
    ));
    return dio;
  }
}

/// Hər HTTP sorğusuna:
///  - cari Supabase JWT-ni `Authorization` başlığı kimi
///  - cari deviceId-ni `X-Device-Id` başlığı kimi qoşur.
/// 403 + `code: 'device_mismatch'` halında `onDeviceMismatch` çağrılır
/// (router-i /claim-device-ə yönləndirmək üçün).
class _AuthAndDeviceInterceptor extends QueuedInterceptorsWrapper {
  final SupabaseClient _supabase;
  final DeviceIdService _deviceIdService;
  final VoidCallback onDeviceMismatch;

  _AuthAndDeviceInterceptor(this._supabase, this._deviceIdService, {required this.onDeviceMismatch});

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = _supabase.auth.currentSession?.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    final deviceId = await _deviceIdService.get();
    options.headers['X-Device-Id'] = deviceId;
    debugPrint('[http] → ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  Future<void> onResponse(Response response, ResponseInterceptorHandler handler) async {
    debugPrint('[http] ← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('[http] ✗ ${err.response?.statusCode} ${err.requestOptions.path}: ${err.response?.data}');

    // 403 device_mismatch — başqa cihazda hesab aktivdir.
    if (err.response?.statusCode == 403) {
      final data = err.response?.data;
      String? code;
      if (data is Map) {
        final inner = data['message'];
        if (inner is Map) code = inner['code'] as String?;
        code ??= data['code'] as String?;
      }
      if (code == 'device_mismatch') {
        debugPrint('[http] device_mismatch — redirecting to /claim-device');
        onDeviceMismatch();
        handler.next(err);
        return;
      }
    }

    if (err.response?.statusCode == 401) {
      try {
        await _supabase.auth.refreshSession();
        final newToken = _supabase.auth.currentSession?.accessToken;
        if (newToken != null) {
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final dio = Dio();
          final retry = await dio.fetch(err.requestOptions);
          return handler.resolve(retry);
        }
      } catch (_) {
        await _supabase.auth.signOut();
      }
    }
    handler.next(err);
  }
}
