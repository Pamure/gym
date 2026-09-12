import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

/// Resolve the backend base URL.
Future<String> resolveApiBase() async {
  const envApi = String.fromEnvironment('API_BASE');
  if (envApi.isNotEmpty) return envApi;
  if (kIsWeb) return '';
  return 'https://gym.abba-s.dev';
}

class Api {
  final Dio dio;
  Api(this.dio);

  static Future<Api> create() async {
    final dio = Dio(BaseOptions(
      baseUrl: await resolveApiBase(),
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 90),
      validateStatus: (s) => s != null && s >= 200 && s < 500,
    ));
    if (kIsWeb) {
      (dio.httpClientAdapter as dynamic).withCredentials = true;
    } else {
      final dir = await getApplicationSupportDirectory();
      final jar = PersistCookieJar(
          ignoreExpires: false, storage: FileStorage('${dir.path}/cookies'));
      dio.interceptors.add(CookieManager(jar));
    }
    return Api(dio);
  }

  // ---------- auth ----------
  Future<Map<String, dynamic>> login(String u, String p) async {
    return _body(await dio.post('/api/auth/login', data: {'username': u, 'password': p}));
  }

  Future<void> logout() async => dio.post('/api/auth/logout');

  Future<Map<String, dynamic>> me() async => _body(await dio.get('/api/me'));

  Future<Map<String, dynamic>> changePassword(String cur, String next) async =>
      _body(await dio.post('/api/auth/password',
          data: {'currentPassword': cur, 'newPassword': next}));

  // ---------- data ----------
  Future<Map<String, dynamic>> state() async => _body(await dio.get('/api/state'));

  Future<Map<String, dynamic>> postWorkout(Map<String, dynamic> payload) async =>
      _body(await dio.post('/api/logs/workout', data: payload));

  Future<void> deleteWorkout(String date, {String? exercise}) async {
    await dio.delete('/api/logs/workout',
        data: {'date': date, if (exercise != null) 'exercise': exercise});
  }

  Future<void> postWeight(String date, double kg) async =>
      dio.post('/api/logs/weight', data: {'date': date, 'kg': kg});

  Future<void> deleteWeight(String date) async =>
      dio.delete('/api/logs/weight', data: {'date': date});

  Future<void> postMeasurements(String date, double? waist, double? chest, double? arm) async =>
      dio.post('/api/logs/measurements',
          data: {
            'date': date,
            if (waist != null) 'waistCm': waist,
            if (chest != null) 'chestCm': chest,
            if (arm != null) 'armCm': arm,
          });

  Future<void> deleteMeasurements(String date) async =>
      dio.delete('/api/logs/measurements', data: {'date': date});

  Future<void> postKegels(String date, int sets, int holdSeconds) async =>
      dio.post('/api/logs/kegels',
          data: {'date': date, 'sets': sets, 'holdSeconds': holdSeconds});

  Future<void> editKegels(int id, int sets, int holdSeconds) async =>
      dio.put('/api/logs/kegels',
          data: {'id': id, 'sets': sets, 'holdSeconds': holdSeconds});

  Future<void> deleteKegels(int id) async =>
      dio.delete('/api/logs/kegels', data: {'id': id});

  Future<void> postCheckin(Map<String, dynamic> payload) async =>
      dio.post('/api/checkins', data: payload);

  Future<void> deleteCheckin(String date) async =>
      dio.delete('/api/checkins', data: {'date': date});

  Future<void> putSetting(String key, String value) async =>
      dio.post('/api/settings', data: {'key': key, 'value': value});

  // ---------- AI coach ----------
  Future<Map<String, dynamic>> aiHistory() async =>
      _body(await dio.get('/api/ai/chat'));

  Future<Map<String, dynamic>> aiAsk(String message, {String dayPlan = ''}) async =>
      _body(await dio.post('/api/ai/chat',
          data: {'message': message, if (dayPlan.isNotEmpty) 'dayPlan': dayPlan}));

  Future<void> aiClear() async => dio.delete('/api/ai/chat');

  Map<String, dynamic> _body(Response r) {
    if (r.statusCode != null && r.statusCode! >= 400) {
      final err = (r.data is Map && r.data['error'] != null)
          ? '${r.data['error']}'
          : 'HTTP ${r.statusCode}';
      throw ApiException(err, r.statusCode ?? 0, r.data);
    }
    return (r.data as Map).cast<String, dynamic>();
  }
}

class ApiException implements Exception {
  final String message;
  final int status;
  final dynamic data;
  ApiException(this.message, this.status, this.data);
  bool get unauthorized => status == 401;
  bool get rateLimited => status == 429;
  bool get isNetwork => status == 0;
  @override
  String toString() => message;
}
