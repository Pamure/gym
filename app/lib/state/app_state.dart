import 'dart:convert';

import '../services/reminders.dart';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api.dart';
import '../data/program.dart';

class WorkoutSet {
  final int setNumber;
  final double weightKg;
  final int reps;
  const WorkoutSet(this.setNumber, this.weightKg, this.reps);
  Map<String, dynamic> toJson() => {
    'setNumber': setNumber,
    'weightKg': weightKg,
    'reps': reps,
  };
}

class WorkoutLog {
  final String date, exercise;
  final int? week;
  final String? day;
  final List<WorkoutSet> sets;
  final String? notes;
  WorkoutLog({
    required this.date,
    required this.exercise,
    this.week,
    this.day,
    required this.sets,
    this.notes,
  });
  Map<String, dynamic> toJson() => {
    'date': date,
    'exercise': exercise,
    if (week != null) 'week': week,
    if (day != null) 'day': day,
    'sets': sets.map((s) => s.toJson()).toList(),
    if (notes != null) 'notes': notes,
  };
}

class WeightEntry {
  final String date;
  final double kg;
  const WeightEntry(this.date, this.kg);
}

class MeasurementEntry {
  final String date;
  final double? waistCm, chestCm, armCm;
  const MeasurementEntry(this.date, this.waistCm, this.chestCm, this.armCm);
}

class KegelEntry {
  final int id;
  final String date;
  final int sets, holdSeconds;
  const KegelEntry(this.id, this.date, this.sets, this.holdSeconds);
}

class CheckinEntry {
  final String date;
  final int? energy;
  final double? sleepHours, waterL;
  final String? mood, notes;
  const CheckinEntry(
    this.date,
    this.energy,
    this.sleepHours,
    this.waterL,
    this.mood,
    this.notes,
  );
}

enum AuthStatus { booting, loggedOut, loggedIn }

/// App-wide state: auth session + locally-cached data with an offline
/// write queue. Data lives server-side; this cache makes the app instant
/// and usable without connectivity.
class AppState extends ChangeNotifier {
  final Api api;
  AppState(this.api);

  AuthStatus status = AuthStatus.booting;
  String username = '';
  String startDate = ''; // ISO yyyy-mm-dd of program week 1
  String unit = 'kg';

  final List<WorkoutLog> workouts = [];
  final List<WeightEntry> bodyWeight = [];
  final List<MeasurementEntry> measurements = [];
  final List<KegelEntry> kegelLogs = [];
  final List<CheckinEntry> checkins = [];
  final List<Map<String, dynamic>> _pending = [];
  int pendingCount = 0;
  String? lastError;
  // Missed days are never punished with extra sets. The plan is three
  // strength sessions; optional movement is genuinely optional.
  bool initialPullDone = false;

  late SharedPreferences _prefs;

  static const _kCache = 'if_cache_v1';
  static const _kPending = 'if_pending_v1';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCache();
    username = _prefs.getString('if_user') ?? username;
    if (_prefs.getBool('if_logged_out') == true || username.isEmpty) {
      // Do not probe /api/me for a brand-new browser/device. Besides avoiding
      // a noisy expected 401, this prevents a stale browser cookie from
      // bypassing the visible login screen.
      status = AuthStatus.loggedOut;
      notifyListeners();
      return;
    }
    // Reach the server once at boot. Cached data remains usable offline, but a
    // real server 401 must still require login; local cache is not an auth
    // bypass.
    try {
      final me = await api.me();
      _applyMe(me);
      status = AuthStatus.loggedIn;
      // Start the 12-week clock on the agreed first Monday when this is a new
      // account. Persist the local value too, otherwise the dashboard briefly
      // shows an empty date until the next app restart.
      if (startDate.isEmpty) {
        startDate = '2026-09-21';
        await setPref('program_start_date', startDate);
      }
      prefs['program_start_date'] = startDate;
      prefs['units'] = unit;
      if (!prefs.containsKey('reminder_enabled')) {
        // The requested 06:30 default is opt-out, but Android still asks for
        // notification/alarm permissions and the user can disable it.
        await setPref('reminder_enabled', '1');
      }
      status = AuthStatus.loggedIn;
      await syncNow();
      await applyRemindersIfEnabled();
    } catch (e) {
      if (e is ApiException && e.unauthorized) {
        status = AuthStatus.loggedOut;
      } else if (_hasLocalSession) {
        // offline: show cached session
        status = AuthStatus.loggedIn;
        lastError = 'Offline — showing saved data. Will sync when back online.';
      } else {
        status = AuthStatus.loggedOut;
      }
    }
    notifyListeners();
  }

  bool get _hasLocalSession =>
      _prefs.getString('if_user') != null &&
      (_prefs.containsKey('if_user') || workouts.isNotEmpty);

  bool get loggedIn => status == AuthStatus.loggedIn;

  // ---------- auth actions ----------
  Future<String?> login(String u, String p) async {
    try {
      final r = await api.login(u, p);
      username = r['username'] as String? ?? u;
      await _prefs.setString('if_user', username);
      await _prefs.remove('if_logged_out');
      status = AuthStatus.loggedIn;
      // Fetch settings immediately so a fresh login has the same program date
      // and reminder state as a returning session.
      final me = await api.me();
      _applyMe(me);
      if (startDate.isEmpty) {
        startDate = '2026-09-21';
        await setPref('program_start_date', startDate);
      }
      if (!prefs.containsKey('reminder_enabled')) {
        await setPref('reminder_enabled', '1');
      }
      await syncNow();
      await applyRemindersIfEnabled();
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Network error — is the server reachable?';
    }
  }

  Future<void> logout({bool discardPending = false}) async {
    if (_pending.isNotEmpty && !discardPending) {
      throw StateError(
        '$pendingCount unsynced changes are stored only on this device. Sync first or explicitly discard them.',
      );
    }
    try {
      await api.logout();
    } catch (_) {}
    // Logout must remain reliable while offline: remove the persisted mobile
    // cookie and leave a local tombstone so a stale server cookie cannot log
    // the user straight back in on the next launch.
    await api.clearLocalSession();
    await ReminderService.cancelAll();
    await _wipeLocal();
    await _prefs.setBool('if_logged_out', true);
    status = AuthStatus.loggedOut;
    notifyListeners();
  }

  Future<void> changePassword(String cur, String next) async {
    await api.changePassword(cur, next);
  }

  // ---------- data sync ----------
  void _applyMe(Map<String, dynamic> me) {
    username = me['username'] as String? ?? username;
    startDate = (me['programStartDate'] as String?) ?? startDate;
    unit = (me['units'] as String?) ?? unit;
    prefs.clear();
    final settingsMap = me['settings'] as Map? ?? {};
    settingsMap.forEach((k, v) => prefs['$k'] = '$v');
    for (final op in _pending.where((op) => op['path'] == 'settings')) {
      final data = op['data'] as Map;
      prefs[data['key'] as String] = data['value'] as String;
    }
    startDate = prefs['program_start_date'] ?? startDate;
    unit = prefs['units'] ?? unit;
    if (startDate.isNotEmpty) prefs['program_start_date'] = startDate;
    prefs['units'] = unit;
    _saveCache();
  }

  int _localRevision = 0;

  /// Upload pending writes BEFORE replacing local state with the server copy.
  /// A failed upload never silently erases the only copy of an offline log.
  Future<bool> syncNow() async {
    if (status != AuthStatus.loggedIn) return false;
    await _flushQueue();
    if (_pending.isNotEmpty || _syncing) {
      lastError ??= '$pendingCount changes still waiting to sync.';
      notifyListeners();
      return false;
    }
    final revision = _localRevision;
    try {
      final s = await api.state();
      // A save can begin while this GET is in flight; never replace a newer
      // optimistic local change with that older response.
      if (_localRevision != revision || _pending.isNotEmpty || _syncing) {
        lastError = 'A change was saved during sync. Sync again to refresh.';
        notifyListeners();
        return false;
      }
      _replaceAll(s);
      initialPullDone = true;
      lastError = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _handleApiError(e);
    } catch (_) {
      lastError = 'Offline — saved data remains on this device.';
    }
    notifyListeners();
    return false;
  }

  Future<void> refreshState() async {
    await syncNow();
  }

  void _handleApiError(ApiException e) {
    if (e.unauthorized) {
      status = AuthStatus.loggedOut;
      lastError = 'Session expired — log in again to sync.';
    } else {
      lastError = e.message;
    }
    notifyListeners();
  }

  void _replaceAll(Map<String, dynamic> s) {
    workouts
      ..clear()
      ..addAll(
        (s['workouts'] as List? ?? []).map((w) {
          final m = w as Map<String, dynamic>;
          return WorkoutLog(
            date: m['date'] as String,
            exercise: m['exercise'] as String,
            week: m['week'] as int?,
            day: m['day'] as String?,
            sets: (m['sets'] == null)
                ? []
                : [
                    for (final x in m['sets'] as List)
                      WorkoutSet(
                        (x as Map)['setNumber'] as int,
                        ((x['weightKg'] as num?) ?? 0).toDouble(),
                        ((x['reps'] as num?) ?? 0).toInt(),
                      ),
                  ],
            notes: m['notes'] as String?,
          );
        }),
      );
    bodyWeight
      ..clear()
      ..addAll(
        (s['bodyWeight'] as List? ?? []).map((w) {
          final m = w as Map<String, dynamic>;
          return WeightEntry(m['date'] as String, (m['kg'] as num).toDouble());
        }),
      );
    measurements
      ..clear()
      ..addAll(
        (s['measurements'] as List? ?? []).map((w) {
          final m = w as Map<String, dynamic>;
          return MeasurementEntry(
            m['date'] as String,
            (m['waistCm'] as num?)?.toDouble(),
            (m['chestCm'] as num?)?.toDouble(),
            (m['armCm'] as num?)?.toDouble(),
          );
        }),
      );
    kegelLogs
      ..clear()
      ..addAll(
        (s['kegels'] as List? ?? []).map((w) {
          final m = w as Map<String, dynamic>;
          return KegelEntry(
            (m['id'] as num?)?.toInt() ?? 0,
            m['date'] as String,
            (m['sets'] as num).toInt(),
            (m['holdSeconds'] as num).toInt(),
          );
        }),
      );
    checkins
      ..clear()
      ..addAll(
        (s['checkins'] as List? ?? []).map((w) {
          final m = w as Map<String, dynamic>;
          return CheckinEntry(
            m['date'] as String,
            (m['energy'] as num?)?.toInt(),
            (m['sleepHours'] as num?)?.toDouble(),
            (m['waterL'] as num?)?.toDouble(),
            m['mood'] as String?,
            m['notes'] as String?,
          );
        }),
      );
    _saveCache();
  }

  // ---------- local-first writes with offline queue ----------
  String _operationKey(Map<String, dynamic> op) {
    final path = op['path'] as String;
    final data = op['data'] as Map;
    if (path == 'kegels') {
      return data['clientId'] == null
          ? 'kegels:${data['id']}'
          : 'kegel-create:${data['clientId']}';
    }
    if (path == 'settings') return 'settings:${data['key']}';
    if (path == 'workout') {
      return 'workout:${data['date']}:${data['exercise'] ?? '*'}';
    }
    return '$path:${data['date']}';
  }

  Future<void> _persistPending() async {
    pendingCount = _pending.length;
    await _prefs.setString(_kPending, jsonEncode(_pending));
    notifyListeners();
  }

  Future<void> _enqueue(Map<String, dynamic> op) async {
    final key = _operationKey(op);
    // Last write to one upsert key wins; never collapse distinct kegel sessions.
    _pending.removeWhere((old) => _operationKey(old) == key);
    _pending.add(op);
    await _persistPending();
  }

  bool _syncing = false;

  Future<void> _write(
    Map<String, dynamic> op,
    void Function() apply,
    Future<void> Function() send,
  ) async {
    if (!loggedIn) throw StateError('Log in again before saving.');
    final before = _cacheData();
    final revision = ++_localRevision;
    apply();
    // Persist intent before contacting the server: an app kill or lost HTTP
    // response must never leave an optimistic cache without a replay command.
    await _enqueue(op);
    await _prefs.setString(_kCache, jsonEncode(_cacheData()));
    if (_syncing) return;
    try {
      await _flushQueue(target: op, targetSend: send);
      if (!loggedIn) {
        throw ApiException('Session expired — log in again.', 401, null);
      }
    } on ApiException catch (e) {
      if (!e.rateLimited &&
          e.status >= 400 &&
          e.status < 500 &&
          e.status != 401) {
        _pending.remove(op);
        await _persistPending();
        // A second save may have superseded this request while it was in
        // flight. Never roll that newer optimistic state back with this one.
        if (_localRevision == revision) {
          _replaceAll(before);
          prefs
            ..clear()
            ..addAll((before['prefs'] as Map).cast<String, String>());
          startDate = before['startDate'] as String;
          unit = before['unit'] as String;
          _saveCache();
        }
      }
      _handleApiError(e);
      rethrow;
    }
    notifyListeners();
  }

  Future<void> _flushQueue({
    Map<String, dynamic>? target,
    Future<void> Function()? targetSend,
  }) async {
    if (_pending.isEmpty || _syncing || !loggedIn) return;
    _syncing = true;
    try {
      for (final op in List<Map<String, dynamic>>.from(_pending)) {
        if (!_pending.contains(op)) continue;
        try {
          final method = (op['method'] as String?) ?? 'POST';
          final path = op['path'] as String;
          final data = op['data'] as Map<String, dynamic>;
          if (identical(op, target) && targetSend != null) {
            await targetSend();
          } else {
            switch ('$method $path') {
              case 'POST workout':
                await api.postWorkout(data);
                break;
              case 'DELETE workout':
                await api.deleteWorkout(
                  data['date'] as String,
                  exercise: data['exercise'] as String?,
                );
                break;
              case 'POST weight':
                await api.postWeight(
                  data['date'] as String,
                  (data['kg'] as num).toDouble(),
                );
                break;
              case 'DELETE weight':
                await api.deleteWeight(data['date'] as String);
                break;
              case 'POST measurements':
                await api.postMeasurements(
                  data['date'] as String,
                  (data['waistCm'] as num?)?.toDouble(),
                  (data['chestCm'] as num?)?.toDouble(),
                  (data['armCm'] as num?)?.toDouble(),
                );
                break;
              case 'DELETE measurements':
                await api.deleteMeasurements(data['date'] as String);
                break;
              case 'POST kegels':
                final saved = await api.postKegels(
                  data['date'] as String,
                  (data['sets'] as num).toInt(),
                  (data['holdSeconds'] as num).toInt(),
                  clientId: data['clientId'] as String?,
                );
                final tempId = (data['tempId'] as num?)?.toInt();
                final serverId = (saved['id'] as num?)?.toInt();
                if (tempId != null && serverId != null) {
                  final i = kegelLogs.indexWhere((k) => k.id == tempId);
                  if (i >= 0) {
                    final k = kegelLogs[i];
                    kegelLogs[i] = KegelEntry(
                      serverId,
                      k.date,
                      k.sets,
                      k.holdSeconds,
                    );
                    _saveCache();
                  }
                }
                break;
              case 'PUT kegels':
                await api.editKegels(
                  (data['id'] as num).toInt(),
                  (data['sets'] as num).toInt(),
                  (data['holdSeconds'] as num).toInt(),
                );
                break;
              case 'DELETE kegels':
                await api.deleteKegels((data['id'] as num).toInt());
                break;
              case 'POST checkins':
                await api.postCheckin(data);
                break;
              case 'DELETE checkins':
                await api.deleteCheckin(data['date'] as String);
                break;
              case 'POST settings':
                await api.putSetting(
                  data['key'] as String,
                  data['value'] as String,
                );
                break;
              default:
                lastError = 'Unknown queued operation — kept for review.';
                return;
            }
          }
          _pending.remove(op);
          await _persistPending(); // durable after each acknowledgement
        } on ApiException catch (e) {
          _handleApiError(e);
          // Surface a direct save's rejected request to its caller. Replays of
          // older writes stay queued for explicit review/correction.
          if (identical(op, target) &&
              !e.rateLimited &&
              e.status >= 400 &&
              e.status < 500) {
            rethrow;
          }
          return;
        } catch (_) {
          lastError = 'Offline — saved changes remain queued on this device.';
          return;
        }
      }
      lastError = null;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  int get pendingOps => _pending.length;

  Future<void> scheduleFlush() async {
    await syncNow();
  }

  Future<void> logWorkout(WorkoutLog log) async {
    if (log.sets.isEmpty || log.sets.any((s) => s.reps < 1 || s.weightKg < 0)) {
      throw ArgumentError('Enter valid sets before saving.');
    }
    await _write(
      {'path': 'workout', 'data': log.toJson()},
      () {
        workouts.removeWhere(
          (old) => old.date == log.date && old.exercise == log.exercise,
        );
        workouts.add(log);
      },
      () async {
        await api.postWorkout(log.toJson());
      },
    );
  }

  Future<void> logWeight(String date, double kg) async {
    if (!kg.isFinite || kg < 20 || kg > 400) {
      throw ArgumentError('Weight must be between 20 and 400 kg.');
    }
    await _write(
      {
        'path': 'weight',
        'data': {'date': date, 'kg': kg},
      },
      () {
        bodyWeight.removeWhere((w) => w.date == date);
        bodyWeight.add(WeightEntry(date, kg));
        bodyWeight.sort((a, b) => a.date.compareTo(b.date));
      },
      () => api.postWeight(date, kg),
    );
  }

  Future<void> logMeasurements(MeasurementEntry m) async {
    final data = <String, dynamic>{'date': m.date};
    if (m.waistCm != null) data['waistCm'] = m.waistCm;
    if (m.chestCm != null) data['chestCm'] = m.chestCm;
    if (m.armCm != null) data['armCm'] = m.armCm;
    await _write({'path': 'measurements', 'data': data}, () {
      measurements.removeWhere((x) => x.date == m.date);
      measurements.add(m);
      measurements.sort((a, b) => a.date.compareTo(b.date));
    }, () => api.postMeasurements(m.date, m.waistCm, m.chestCm, m.armCm));
  }

  int _nextTempKegelId = -1;
  Future<void> logKegels(String date, int sets, int holdSeconds) async {
    final tempId = _nextTempKegelId--;
    final clientId = '${DateTime.now().microsecondsSinceEpoch}-${tempId.abs()}';
    final data = <String, dynamic>{
      'date': date,
      'sets': sets,
      'holdSeconds': holdSeconds,
      'clientId': clientId,
      'tempId': tempId,
    };
    await _write(
      {'path': 'kegels', 'data': data},
      () {
        kegelLogs.insert(0, KegelEntry(tempId, date, sets, holdSeconds));
      },
      () async {
        final saved = await api.postKegels(
          date,
          sets,
          holdSeconds,
          clientId: clientId,
        );
        final id = (saved['id'] as num?)?.toInt();
        if (id == null || id <= 0) {
          throw ApiException('Server did not assign a session ID', 502, saved);
        }
        final i = kegelLogs.indexWhere((k) => k.id == tempId);
        if (i >= 0) kegelLogs[i] = KegelEntry(id, date, sets, holdSeconds);
        _saveCache();
      },
    );
  }

  Future<void> setStartDate(String iso) async {
    await setPref('program_start_date', iso);
  }

  // ---------- edit / delete (fix mistakes) ----------

  Future<void> deleteWorkoutLog(String date, String exercise) async {
    await _write(
      {
        'method': 'DELETE',
        'path': 'workout',
        'data': {'date': date, 'exercise': exercise},
      },
      () =>
          workouts.removeWhere((w) => w.date == date && w.exercise == exercise),
      () => api.deleteWorkout(date, exercise: exercise),
    );
  }

  Future<void> deleteWeightLog(String date) async {
    await _write(
      {
        'method': 'DELETE',
        'path': 'weight',
        'data': {'date': date},
      },
      () => bodyWeight.removeWhere((w) => w.date == date),
      () => api.deleteWeight(date),
    );
  }

  Future<void> deleteMeasurementLog(String date) async {
    await _write(
      {
        'method': 'DELETE',
        'path': 'measurements',
        'data': {'date': date},
      },
      () => measurements.removeWhere((m) => m.date == date),
      () => api.deleteMeasurements(date),
    );
  }

  Future<void> deleteKegelLog(int id) async {
    if (id <= 0) {
      if (id == 0) {
        throw StateError('Sync this older session before deleting it.');
      }
      kegelLogs.removeWhere((k) => k.id == id);
      _pending.removeWhere(
        (op) => op['path'] == 'kegels' && (op['data'] as Map)['tempId'] == id,
      );
      _saveCache();
      await _persistPending();
      return;
    }
    await _write(
      {
        'method': 'DELETE',
        'path': 'kegels',
        'data': {'id': id},
      },
      () => kegelLogs.removeWhere((k) => k.id == id),
      () => api.deleteKegels(id),
    );
  }

  Future<void> editKegelLog(int id, int sets, int holdSeconds) async {
    if (id == 0) throw StateError('Sync this older session before editing it.');
    if (id < 0) {
      final i = kegelLogs.indexWhere((k) => k.id == id);
      final queued = _pending
          .where(
            (op) =>
                op['path'] == 'kegels' && (op['data'] as Map)['tempId'] == id,
          )
          .toList();
      if (i < 0 || queued.isEmpty) {
        throw StateError('Session not found locally.');
      }
      final old = kegelLogs[i];
      kegelLogs[i] = KegelEntry(id, old.date, sets, holdSeconds);
      (queued.single['data'] as Map)['sets'] = sets;
      (queued.single['data'] as Map)['holdSeconds'] = holdSeconds;
      _saveCache();
      await _persistPending();
      return;
    }
    await _write(
      {
        'method': 'PUT',
        'path': 'kegels',
        'data': {'id': id, 'sets': sets, 'holdSeconds': holdSeconds},
      },
      () {
        final i = kegelLogs.indexWhere((k) => k.id == id);
        if (i >= 0) {
          final old = kegelLogs[i];
          kegelLogs[i] = KegelEntry(id, old.date, sets, holdSeconds);
        }
      },
      () => api.editKegels(id, sets, holdSeconds),
    );
  }

  Future<void> saveCheckin(CheckinEntry c) async {
    final data = {
      'date': c.date,
      if (c.energy != null) 'energy': c.energy,
      if (c.sleepHours != null) 'sleepHours': c.sleepHours,
      if (c.waterL != null) 'waterL': c.waterL,
      if (c.mood != null) 'mood': c.mood,
      if (c.notes != null) 'notes': c.notes,
    };
    await _write({'path': 'checkins', 'data': data}, () {
      checkins.removeWhere((x) => x.date == c.date);
      checkins.add(c);
      checkins.sort((a, b) => b.date.compareTo(a.date));
    }, () => api.postCheckin(data));
  }

  Future<void> deleteCheckinLog(String date) async {
    await _write(
      {
        'method': 'DELETE',
        'path': 'checkins',
        'data': {'date': date},
      },
      () => checkins.removeWhere((c) => c.date == date),
      () => api.deleteCheckin(date),
    );
  }

  Future<void> applyRemindersIfEnabled() async {
    final enabled = loggedIn && pref('reminder_enabled', '0') == '1';
    try {
      await ReminderService.scheduleForPrefs(this, enabled);
    } catch (_) {}
  }

  // ---------- settings helpers ----------
  final Map<String, String> prefs = {};

  String pref(String key, [String def = '']) => prefs[key] ?? def;

  Future<void> setPref(String key, String value) async {
    await _write(
      {
        'path': 'settings',
        'data': {'key': key, 'value': value},
      },
      () {
        prefs[key] = value;
        if (key == 'program_start_date') startDate = value;
        if (key == 'units') unit = value;
      },
      () => api.putSetting(key, value),
    );
  }

  // ---------- cache ----------
  Map<String, dynamic> _cacheData() => {
    'workouts': workouts.map((w) => w.toJson()).toList(),
    'bodyWeight': bodyWeight.map((w) => {'date': w.date, 'kg': w.kg}).toList(),
    'measurements': measurements
        .map(
          (m) => {
            'date': m.date,
            'waistCm': m.waistCm,
            'chestCm': m.chestCm,
            'armCm': m.armCm,
          },
        )
        .toList(),
    'kegels': kegelLogs
        .map(
          (k) => {
            'id': k.id,
            'date': k.date,
            'sets': k.sets,
            'holdSeconds': k.holdSeconds,
          },
        )
        .toList(),
    'checkins': checkins
        .map(
          (c) => {
            'date': c.date,
            'energy': c.energy,
            'sleepHours': c.sleepHours,
            'waterL': c.waterL,
            'mood': c.mood,
            'notes': c.notes,
          },
        )
        .toList(),
    'startDate': startDate,
    'unit': unit,
    'prefs': Map<String, String>.from(prefs),
  };

  void _saveCache() => _prefs.setString(_kCache, jsonEncode(_cacheData()));

  void _loadCache() {
    final raw = _prefs.getString(_kCache);
    final pendingRaw = _prefs.getString(_kPending);
    if (pendingRaw != null) {
      try {
        final decoded = jsonDecode(pendingRaw) as List;
        _pending
          ..clear()
          ..addAll(decoded.map((x) => (x as Map).cast<String, dynamic>()));
        pendingCount = _pending.length;
      } catch (_) {
        _pending.clear();
        pendingCount = 0;
      }
    }
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      workouts.clear();
      for (final w in j['workouts'] as List? ?? []) {
        final m = w as Map<String, dynamic>;
        workouts.add(
          WorkoutLog(
            date: m['date'] as String,
            exercise: m['exercise'] as String,
            week: m['week'] as int?,
            day: m['day'] as String?,
            sets: [
              for (final x in m['sets'] as List? ?? [])
                WorkoutSet(
                  (x as Map)['setNumber'] as int,
                  ((x['weightKg'] as num?) ?? 0).toDouble(),
                  ((x['reps'] as num?) ?? 0).toInt(),
                ),
            ],
            notes: m['notes'] as String?,
          ),
        );
      }
      bodyWeight.clear();
      for (final w in j['bodyWeight'] as List? ?? []) {
        final m = w as Map<String, dynamic>;
        bodyWeight.add(
          WeightEntry(m['date'] as String, (m['kg'] as num).toDouble()),
        );
      }
      measurements.clear();
      for (final m in j['measurements'] as List? ?? []) {
        final x = m as Map<String, dynamic>;
        measurements.add(
          MeasurementEntry(
            x['date'] as String,
            (x['waistCm'] as num?)?.toDouble(),
            (x['chestCm'] as num?)?.toDouble(),
            (x['armCm'] as num?)?.toDouble(),
          ),
        );
      }
      kegelLogs.clear();
      for (final k in j['kegels'] as List? ?? []) {
        final x = k as Map<String, dynamic>;
        kegelLogs.add(
          KegelEntry(
            (x['id'] as num?)?.toInt() ?? 0,
            x['date'] as String,
            (x['sets'] as num).toInt(),
            (x['holdSeconds'] as num).toInt(),
          ),
        );
      }
      checkins.clear();
      for (final c in j['checkins'] as List? ?? []) {
        final x = c as Map<String, dynamic>;
        checkins.add(
          CheckinEntry(
            x['date'] as String,
            (x['energy'] as num?)?.toInt(),
            (x['sleepHours'] as num?)?.toDouble(),
            (x['waterL'] as num?)?.toDouble(),
            x['mood'] as String?,
            x['notes'] as String?,
          ),
        );
      }
      final negatives = kegelLogs.where((k) => k.id < 0).map((k) => k.id);
      _nextTempKegelId = negatives.isEmpty
          ? -1
          : negatives.reduce((a, b) => a < b ? a : b) - 1;
      startDate = (j['startDate'] as String?) ?? '';
      unit = (j['unit'] as String?) ?? 'kg';
      prefs.clear();
      final cachedPrefs = j['prefs'] as Map? ?? {};
      cachedPrefs.forEach((k, v) => prefs['$k'] = '$v');
    } catch (_) {}
  }

  Future<void> _wipeLocal() async {
    workouts.clear();
    bodyWeight.clear();
    measurements.clear();
    kegelLogs.clear();
    checkins.clear();
    _pending.clear();
    pendingCount = 0;
    prefs.clear();
    username = '';
    startDate = '';
    unit = 'kg';
    lastError = null;
    await _prefs.remove(_kCache);
    await _prefs.remove(_kPending);
    await _prefs.remove('if_user');
  }

  // ---------- derived metrics ----------
  /// Calendar date when the 12-week program ends (start + 12 weeks).
  String programEndDate() {
    if (startDate.isEmpty) return '';
    final start = DateTime.tryParse(startDate);
    if (start == null) return '';
    final end = start.add(const Duration(days: 83));
    return '${end.year.toString().padLeft(4, '0')}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';
  }

  int currentWeek() {
    if (startDate.isEmpty) return 1;
    final start = DateTime.tryParse(startDate);
    if (start == null) return 1;
    final days = DateTime.now().difference(start).inDays;
    final w = (days ~/ 7) + 1;
    return w.clamp(1, 12);
  }

  String todayIso() {
    final n = DateTime.now();
    return '${n.year.toString().padLeft(4, '0')}-${n.month.toString().padLeft(2, '0')}-${n.day.toString().padLeft(2, '0')}';
  }

  /// Logs for one date (any kind of workout entry).
  List<WorkoutLog> logsOn(String date) =>
      workouts.where((w) => w.date == date).toList();

  bool dayCompleted(String date) => logsOn(date).isNotEmpty;

  /// A required session needs at least three distinct planned loaded lifts.
  /// One warm-up or one recovery card means 'started', not 'completed'.
  bool strengthSessionCompleted(DateTime date) {
    final day = programDays[date.weekday - 1];
    if (day.restDay || day.optional) return false;
    final coachDay = coachPlanDays[date.weekday - 1];
    final planned = {
      ...day.items.map((x) => x.id),
      ...coachDay.items.map((x) => x.id),
    }.where(weightBasedIds.contains).toSet();
    final done = logsOn(_iso(date))
        .where(
          (log) =>
              planned.contains(log.exercise) &&
              log.sets.any((set) => set.reps > 0),
        )
        .map((log) => log.exercise)
        .toSet();
    return done.length >= 3;
  }

  double volumeForDate(String date) {
    var v = 0.0;
    for (final l in logsOn(date)) {
      if (l.exercise == 'farmers-walk') continue; // seconds are not reps
      for (final s in l.sets) {
        v += s.weightKg * s.reps;
      }
    }
    return v;
  }

  /// Best logged weight per exercise.
  Map<String, ({double kg, int reps, String date})> personalRecords() {
    final pr = <String, ({double kg, int reps, String date})>{};
    for (final l in workouts) {
      for (final s in l.sets) {
        if (s.weightKg <= 0) continue;
        final cur = pr[l.exercise];
        if (cur == null || s.weightKg > cur.kg) {
          pr[l.exercise] = (kg: s.weightKg, reps: s.reps, date: l.date);
        }
      }
    }
    return pr;
  }

  /// Consecutive completed required strength sessions. Optional days never
  /// break the streak, and today's unfinished session does not reset it yet.
  int streak() {
    var count = 0;
    final now = DateTime.now();
    var day = DateTime(now.year, now.month, now.day);
    for (var i = 0; i < 120; i++, day = day.subtract(const Duration(days: 1))) {
      final plan = programDays[day.weekday - 1];
      if (plan.optional || plan.restDay) continue;
      if (i == 0 && !strengthSessionCompleted(day)) continue;
      if (!strengthSessionCompleted(day)) break;
      count++;
    }
    return count;
  }

  double? lastWeight() => bodyWeight.isEmpty ? null : bodyWeight.last.kg;

  int bestStreak() {
    if (workouts.isEmpty) return 0;
    final dates = workouts
        .map((w) => DateTime.tryParse(w.date))
        .whereType<DateTime>()
        .toList();
    if (dates.isEmpty) return 0;
    dates.sort();
    var best = 0;
    var current = 0;
    final today = DateTime.now();
    for (
      var d = dates.first;
      !d.isAfter(today);
      d = d.add(const Duration(days: 1))
    ) {
      final plan = programDays[d.weekday - 1];
      if (plan.optional || plan.restDay) continue;
      if (strengthSessionCompleted(d)) {
        current++;
        if (current > best) best = current;
      } else {
        current = 0;
      }
    }
    return best;
  }

  /// Intensity 0..4 (trained=2, check-in=1, optional kegel=1).
  Map<String, int> heatmapCells() {
    final trained = workouts.map((w) => w.date).toSet();
    final checked = checkins.map((c) => c.date).toSet();
    final pelvic = kegelLogs.map((k) => k.date).toSet();
    final dates = {...trained, ...checked, ...pelvic};
    return {
      for (final date in dates)
        date:
            (trained.contains(date) ? 2 : 0) +
            (checked.contains(date) ? 1 : 0) +
            (pelvic.contains(date) ? 1 : 0),
    };
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
