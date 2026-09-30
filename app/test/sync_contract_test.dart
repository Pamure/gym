import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironforge/services/api.dart';
import 'package:ironforge/state/app_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory HTTP transport: no real login, AI key, filesystem DB, or network.
class _Backend implements HttpClientAdapter {
  bool online = true;
  bool rejectWeight = false;
  Completer<void>? pauseState;
  Completer<void>? stateEntered;
  Completer<void>? pauseWeight;
  Completer<void>? weightEntered;
  final weights = <String, double>{};
  final sessions = <int, Map<String, dynamic>>{};
  final sessionKeys = <String, int>{};
  int nextId = 1;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (!online) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      );
    }
    final path = options.uri.path;
    final data = options.data is String
        ? jsonDecode(options.data as String) as Map<String, dynamic>
        : (options.data is Map
              ? (options.data as Map).cast<String, dynamic>()
              : <String, dynamic>{});
    dynamic body = {'ok': true};
    var status = 200;
    if (path == '/api/me') {
      body = {
        'username': 'demo',
        'programStartDate': '2026-09-21',
        'units': 'kg',
        'settings': {
          'program_start_date': '2026-09-21',
          'reminder_enabled': '0',
        },
      };
    } else if (path == '/api/state') {
      body = {
        'workouts': [],
        'bodyWeight': [
          for (final w in weights.entries) {'date': w.key, 'kg': w.value},
        ],
        'measurements': [],
        'kegels': [
          for (final k in sessions.entries) {'id': k.key, ...k.value},
        ],
        'checkins': [],
      };
    } else if (path == '/api/logs/weight' && options.method == 'POST') {
      if (pauseWeight != null) {
        final pending = pauseWeight!;
        pauseWeight = null;
        weightEntered?.complete();
        await pending.future;
      }
      if (rejectWeight) {
        status = 400;
        body = {'error': 'invalid weight'};
      } else {
        weights[data['date'] as String] = (data['kg'] as num).toDouble();
      }
    } else if (path == '/api/logs/kegels' && options.method == 'POST') {
      final clientId = data['clientId'] as String?;
      final id = clientId != null && sessionKeys.containsKey(clientId)
          ? sessionKeys[clientId]!
          : nextId++;
      if (clientId != null) sessionKeys[clientId] = id;
      sessions[id] = {
        'date': data['date'],
        'sets': data['sets'],
        'holdSeconds': data['holdSeconds'],
      };
      body = {'ok': true, 'id': id};
    } else if (path == '/api/logs/kegels' && options.method == 'DELETE') {
      sessions.remove(data['id']);
    }
    if (path == '/api/state' && pauseState != null) {
      final pending = pauseState!;
      pauseState = null;
      stateEntered?.complete();
      await pending.future;
    }
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Future<AppState> _makeState(_Backend backend) async {
  final dio = Dio(BaseOptions(baseUrl: 'http://localhost'));
  dio.httpClientAdapter = backend;
  final state = AppState(Api(dio));
  await state.init();
  return state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({'if_user': 'demo'}));

  test('older offline weight cannot overwrite a newer online save', () async {
    final backend = _Backend();
    final state = await _makeState(backend);
    backend.online = false;
    await state.logWeight('2026-09-28', 45);
    expect(state.pendingCount, 1);
    backend.online = true;
    final resumed = await _makeState(backend);
    expect(resumed.pendingCount, 0);
    await resumed.logWeight('2026-09-28', 50);
    expect(backend.weights['2026-09-28'], 50);
    expect(resumed.pendingCount, 0);
    expect(await resumed.syncNow(), isTrue);
    expect(resumed.lastWeight(), 50);
    final restarted = await _makeState(backend);
    expect(restarted.lastWeight(), 50);
    expect(restarted.pendingCount, 0);
  });

  test('a save has a durable replay intent before its HTTP response', () async {
    final backend = _Backend();
    final state = await _makeState(backend);
    final response = Completer<void>();
    backend.pauseWeight = response;
    backend.weightEntered = Completer<void>();
    final save = state.logWeight('2026-09-28', 70);
    await backend.weightEntered!.future;
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('if_pending_v1'), contains('2026-09-28'));
    final restarted = await _makeState(backend);
    expect(backend.weights['2026-09-28'], 70);
    expect(restarted.pendingCount, 0);
    response.complete();
    await save;
  });

  test('a stale in-flight refresh cannot erase a concurrent save', () async {
    final backend = _Backend();
    final state = await _makeState(backend);
    final pending = Completer<void>();
    backend.pauseState = pending;
    backend.stateEntered = Completer<void>();
    final refresh = state.syncNow();
    await backend.stateEntered!.future;
    await state.logWeight('2026-09-28', 70);
    pending.complete();
    expect(await refresh, isFalse);
    expect(state.lastWeight(), 70);
    expect(await state.syncNow(), isTrue);
    expect(state.lastWeight(), 70);
  });

  test(
    'rejected HTTP 400 rolls back local snapshot; never queued as offline',
    () async {
      final backend = _Backend();
      final state = await _makeState(backend);
      backend.rejectWeight = true;
      await expectLater(
        state.logWeight('2026-09-28', 70),
        throwsA(isA<ApiException>()),
      );
      expect(state.bodyWeight, isEmpty);
      expect(state.pendingCount, 0);
      expect(backend.weights, isEmpty);
    },
  );

  test('new pelvic-floor sessions get distinct server ids; deleting one keeps the other', () async {
    final backend = _Backend();
    final state = await _makeState(backend);
    await state.logKegels('2026-09-28', 1, 3);
    await state.logKegels('2026-09-28', 1, 3);
    expect(state.kegelLogs.map((k) => k.id).toSet(), {1, 2});
    await state.deleteKegelLog(1);
    expect(state.kegelLogs.map((k) => k.id), [2]);
    expect(backend.sessions.keys.toList(), [2]);
  });

  test('logout refuses to erase the only copy of an offline write', () async {
    final backend = _Backend();
    final state = await _makeState(backend);
    backend.online = false;
    await state.logWeight('2026-09-28', 70);
    await expectLater(state.logout(), throwsStateError);
    expect(state.pendingCount, 1);
    expect(state.loggedIn, isTrue);
  });

  test('disabled reminder preference survives an offline restart', () async {
    final backend = _Backend();
    final initial = await _makeState(backend);
    expect(initial.pref('reminder_enabled'), '0');
    backend.online = false;
    final offline = await _makeState(backend);
    expect(offline.loggedIn, isTrue);
    expect(offline.pref('reminder_enabled'), '0');
  });

  test('HTTP 401 on a void write is an error, not success', () async {
    final backend = _Backend();
    final state = await _makeState(backend);
    // Simulate an expired session by swapping an adapter that returns 401.
    state.api.dio.httpClientAdapter = _UnauthorizedBackend();
    await expectLater(
      state.logWeight('2026-09-28', 70),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    expect(state.loggedIn, isFalse);
    expect(state.pendingCount, 1); // retained for replay after re-login
  });
}

class _UnauthorizedBackend implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => ResponseBody.fromString(
    '{"error":"unauthenticated"}',
    401,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}
