import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

Future<String> resolveApiBase() async {
  const envApi = String.fromEnvironment('API_BASE');
  if (envApi.isNotEmpty) return envApi;
  if (kIsWeb) return '';
  return 'https://gym.abba-s.dev';
}

class Api {
  final Dio dio;
  final CookieJar? cookieJar;
  Api(this.dio, {this.cookieJar});

  static Future<Api> create() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: await resolveApiBase(),
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 90),
      ),
    );
    if (kIsWeb) {
      (dio.httpClientAdapter as dynamic).withCredentials = true;
    } else {
      final dir = await getApplicationSupportDirectory();
      final jar = PersistCookieJar(
        ignoreExpires: false,
        storage: FileStorage('${dir.path}/cookies'),
      );
      dio.interceptors.add(CookieManager(jar));
      return Api(dio, cookieJar: jar);
    }
    return Api(dio);
  }

  /// All requests, including void writes, must reject HTTP failures. A 400 or
  /// 401 is not an offline event: queuing it or claiming success loses data.
  Future<Response<dynamic>> _send(Future<Response<dynamic>> request) async {
    try {
      return await request;
    } on DioException catch (e) {
      final response = e.response;
      if (response == null) rethrow; // connection/timeout: retryable offline
      final data = response.data;
      final err = data is Map && data['error'] != null
          ? '${data['error']}'
          : 'HTTP ${response.statusCode}';
      throw ApiException(err, response.statusCode ?? 0, data);
    }
  }

  Future<Map<String, dynamic>> _body(Future<Response<dynamic>> request) async {
    final r = await _send(request);
    return (r.data as Map).cast<String, dynamic>();
  }

  // Auth
  Future<Map<String, dynamic>> login(String u, String p) =>
      _body(dio.post('/api/auth/login', data: {'username': u, 'password': p}));
  Future<void> logout() async {
    await _send(dio.post('/api/auth/logout'));
  }

  Future<void> clearLocalSession() async {
    try {
      await cookieJar?.deleteAll();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> me() => _body(dio.get('/api/me'));
  Future<Map<String, dynamic>> changePassword(String cur, String next) => _body(
    dio.post(
      '/api/auth/password',
      data: {'currentPassword': cur, 'newPassword': next},
    ),
  );

  // Data
  Future<Map<String, dynamic>> state() => _body(dio.get('/api/state'));
  Future<Map<String, dynamic>> postWorkout(Map<String, dynamic> payload) =>
      _body(dio.post('/api/logs/workout', data: payload));
  Future<void> deleteWorkout(String date, {String? exercise}) async {
    final data = <String, dynamic>{'date': date};
    if (exercise != null) data['exercise'] = exercise;
    await _send(dio.delete('/api/logs/workout', data: data));
  }

  Future<void> postWeight(String date, double kg) async {
    await _send(dio.post('/api/logs/weight', data: {'date': date, 'kg': kg}));
  }

  Future<void> deleteWeight(String date) async {
    await _send(dio.delete('/api/logs/weight', data: {'date': date}));
  }

  Future<void> postMeasurements(
    String date,
    double? waist,
    double? chest,
    double? arm,
  ) async {
    final data = <String, dynamic>{'date': date};
    if (waist != null) data['waistCm'] = waist;
    if (chest != null) data['chestCm'] = chest;
    if (arm != null) data['armCm'] = arm;
    await _send(dio.post('/api/logs/measurements', data: data));
  }

  Future<void> deleteMeasurements(String date) async {
    await _send(dio.delete('/api/logs/measurements', data: {'date': date}));
  }

  Future<Map<String, dynamic>> postKegels(
    String date,
    int sets,
    int holdSeconds, {
    String? clientId,
  }) => _body(
    dio.post(
      '/api/logs/kegels',
      data: {
        'date': date,
        'sets': sets,
        'holdSeconds': holdSeconds,
        'clientId': ?clientId,
      },
    ),
  );
  Future<void> editKegels(int id, int sets, int holdSeconds) async {
    await _send(
      dio.put(
        '/api/logs/kegels',
        data: {'id': id, 'sets': sets, 'holdSeconds': holdSeconds},
      ),
    );
  }

  Future<void> deleteKegels(int id) async {
    await _send(dio.delete('/api/logs/kegels', data: {'id': id}));
  }

  Future<void> postCheckin(Map<String, dynamic> payload) async {
    await _send(dio.post('/api/checkins', data: payload));
  }

  Future<void> deleteCheckin(String date) async {
    await _send(dio.delete('/api/checkins', data: {'date': date}));
  }

  Future<void> putSetting(String key, String value) async {
    await _send(dio.post('/api/settings', data: {'key': key, 'value': value}));
  }

  // AI coach
  Future<Map<String, dynamic>> aiHistory() => _body(dio.get('/api/ai/chat'));
  Future<Map<String, dynamic>> aiAsk(String message, {String dayPlan = ''}) =>
      _body(
        dio.post(
          '/api/ai/chat',
          data: {
            'message': message,
            if (dayPlan.isNotEmpty) 'dayPlan': dayPlan,
          },
        ),
      );
  Future<void> aiClear() async {
    await _send(dio.delete('/api/ai/chat'));
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
