import 'dart:convert';
import '../services/reminders.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api.dart';

class WorkoutSet {
  final int setNumber;
  final double weightKg;
  final int reps;
  const WorkoutSet(this.setNumber, this.weightKg, this.reps);
  Map<String, dynamic> toJson() =>
      {'setNumber': setNumber, 'weightKg': weightKg, 'reps': reps};
}

class WorkoutLog {
  final String date, exercise;
  final int? week;
  final String? day;
  final List<WorkoutSet> sets;
  final String? notes;
  WorkoutLog(
      {required this.date,
      required this.exercise,
      this.week,
      this.day,
      required this.sets,
      this.notes});
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
  const CheckinEntry(this.date, this.energy, this.sleepHours, this.waterL, this.mood, this.notes);
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
  bool initialPullDone = false;

  late SharedPreferences _prefs;

  static const _kCache = 'if_cache_v1';
  static const _kPending = 'if_pending_v1';

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadCache();
    // try to reach the server (background)
    try {
      final me = await api.me();
      username = me['username'] as String? ?? username;
      startDate = (me['programStartDate'] as String?) ?? startDate;
      unit = (me['units'] as String?) ?? unit;
      // No start date set anywhere → the 12-week clock begins TODAY (first login).
      // User can backdate it in Settings → Program start date to their real first gym day.
      if (startDate.isEmpty) {
        // User directive: 21 September 2026 (Monday) start date
        final iso = '2026-09-21';
        await setPref('program_start_date', iso);
      }
      final settingsMap = me['settings'] as Map? ?? {};
      prefs.clear();
      settingsMap.forEach((k, v) => prefs['$k'] = '$v');
      prefs['program_start_date'] = startDate;
      prefs['units'] = unit;
      status = AuthStatus.loggedIn;
      await refreshState();
      await _flushQueue();
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
      _prefs.getString('if_user') != null && (_prefs.containsKey('if_user') || workouts.isNotEmpty);

  bool get loggedIn => status == AuthStatus.loggedIn;

  // ---------- auth actions ----------
  Future<String?> login(String u, String p) async {
    try {
      final r = await api.login(u, p);
      username = r['username'] as String? ?? u;
      _prefs.setString('if_user', username);
      status = AuthStatus.loggedIn;
      notifyListeners();
      await refreshState();
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (e) {
      return 'Network error — is the server reachable?';
    }
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } catch (_) {}
    await _wipeLocal();
    status = AuthStatus.loggedOut;
    notifyListeners();
  }

  Future<void> changePassword(String cur, String next) async {
    await api.changePassword(cur, next);
  }

  // ---------- data sync ----------
  Future<void> refreshState() async {
    try {
      final s = await api.state();
      _replaceAll(s);
      initialPullDone = true;
      lastError = null;
    } on ApiException {
      lastError = 'Sync failed';
    }
    notifyListeners();
  }

  void _replaceAll(Map<String, dynamic> s) {
    workouts
      ..clear()
      ..addAll((s['workouts'] as List? ?? []).map((w) {
        final m = w as Map<String, dynamic>;
        return WorkoutLog(
          date: m['date'] as String,
          exercise: m['exercise'] as String,
          week: m['week'] as int?,
          day: m['day'] as String?,
          sets: (m['sets'] == null)
              ? []
              : [for (final x in m['sets'] as List) WorkoutSet(
                  (x as Map)['setNumber'] as int,
                  ((x['weightKg'] as num?) ?? 0).toDouble(),
                  ((x['reps'] as num?) ?? 0).toInt())],
          notes: m['notes'] as String?,
        );
      }));
    bodyWeight
      ..clear()
      ..addAll((s['bodyWeight'] as List? ?? []).map((w) {
        final m = w as Map<String, dynamic>;
        return WeightEntry(m['date'] as String, (m['kg'] as num).toDouble());
      }));
    measurements
      ..clear()
      ..addAll((s['measurements'] as List? ?? []).map((w) {
        final m = w as Map<String, dynamic>;
        return MeasurementEntry(
            m['date'] as String,
            (m['waistCm'] as num?)?.toDouble(),
            (m['chestCm'] as num?)?.toDouble(),
            (m['armCm'] as num?)?.toDouble());
      }));
    kegelLogs
      ..clear()
      ..addAll((s['kegels'] as List? ?? []).map((w) {
        final m = w as Map<String, dynamic>;
        return KegelEntry(
            (m['id'] as num?)?.toInt() ?? 0,
            m['date'] as String,
            (m['sets'] as num).toInt(),
            (m['holdSeconds'] as num).toInt());
      }));
    checkins
      ..clear()
      ..addAll((s['checkins'] as List? ?? []).map((w) {
        final m = w as Map<String, dynamic>;
        return CheckinEntry(
            m['date'] as String,
            (m['energy'] as num?)?.toInt(),
            (m['sleepHours'] as num?)?.toDouble(),
            (m['waterL'] as num?)?.toDouble(),
            m['mood'] as String?,
            m['notes'] as String?);
      }));
    _saveCache();
  }

  // ---------- local-first writes with offline queue ----------
  Future<void> _enqueue(Map<String, dynamic> op) async {
    _pending.add(op);
    pendingCount = _pending.length;
    notifyListeners();
    await _prefs.setString(_kPending, jsonEncode(_pending));
  }

  Future<void> _flushQueue() async {
    if (_pending.isEmpty) return;
    final remaining = <Map<String, dynamic>>[];
    for (final op in _pending) {
      try {
        final method = (op['method'] as String?) ?? 'POST';
        final path = op['path'] as String;
        final data = op['data'] as Map<String, dynamic>;
        switch ('$method $path') {
          case 'POST workout': await api.postWorkout(data); break;
          case 'DELETE workout': await api.deleteWorkout(data['date'] as String, exercise: data['exercise'] as String?); break;
          case 'POST weight': await api.postWeight(data['date'] as String, (data['kg'] as num).toDouble()); break;
          case 'DELETE weight': await api.deleteWeight(data['date'] as String); break;
          case 'POST measurements': await api.postMeasurements(data['date'] as String, (data['waistCm'] as num?)?.toDouble(), (data['chestCm'] as num?)?.toDouble(), (data['armCm'] as num?)?.toDouble()); break;
          case 'DELETE measurements': await api.deleteMeasurements(data['date'] as String); break;
          case 'POST kegels': await api.postKegels(data['date'] as String, (data['sets'] as num).toInt(), (data['holdSeconds'] as num).toInt()); break;
          case 'PUT kegels': await api.editKegels((data['id'] as num).toInt(), (data['sets'] as num).toInt(), (data['holdSeconds'] as num).toInt()); break;
          case 'DELETE kegels': await api.deleteKegels((data['id'] as num).toInt()); break;
          case 'POST checkins': await api.postCheckin(data); break;
          case 'DELETE checkins': await api.deleteCheckin(data['date'] as String); break;
          case 'POST settings': await api.putSetting(data['key'] as String, data['value'] as String); break;
          default: remaining.add(op); continue;
        }
      } catch (_) {
        remaining.add(op); // keep for next flush
      }
    }
    _pending
      ..clear()
      ..addAll(remaining);
    pendingCount = _pending.length;
    await _prefs.setString(_kPending, jsonEncode(_pending));
  }

  int get pendingOps => _pending.length;

  Future<void> scheduleFlush() async {
    if (_pending.isEmpty) return;
    try {
      await _flushQueue();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logWorkout(WorkoutLog log) async {
    final op = {'path': 'workout', 'data': log.toJson()};
    workouts.add(log);
    _saveCache();
    try {
      await api.postWorkout(log.toJson());
    } catch (_) {
      await _enqueue(op);
    }
    notifyListeners();
  }

  Future<void> logWeight(String date, double kg) async {
    bodyWeight.removeWhere((w) => w.date == date);
    bodyWeight.add(WeightEntry(date, kg));
    bodyWeight.sort((a, b) => a.date.compareTo(b.date));
    _saveCache();
    try {
      await api.postWeight(date, kg);
    } catch (_) {
      await _enqueue({'path': 'weight', 'data': {'date': date, 'kg': kg}});
    }
    notifyListeners();
  }

  Future<void> logMeasurements(MeasurementEntry m) async {
    measurements.removeWhere((x) => x.date == m.date);
    measurements.add(m);
    measurements.sort((a, b) => a.date.compareTo(b.date));
    _saveCache();
    try {
      await api.postMeasurements(m.date, m.waistCm, m.chestCm, m.armCm);
    } catch (_) {
      await _enqueue({
        'path': 'measurements',
        'data': {
          'date': m.date,
          if (m.waistCm != null) 'waistCm': m.waistCm,
          if (m.chestCm != null) 'chestCm': m.chestCm,
          if (m.armCm != null) 'armCm': m.armCm,
        }
      });
    }
    notifyListeners();
  }

  Future<void> logKegels(String date, int sets, int holdSeconds) async {
    kegelLogs.insert(0, KegelEntry(0, date, sets, holdSeconds));
    _saveCache();
    try {
      await api.postKegels(date, sets, holdSeconds);
    } catch (_) {
      await _enqueue(
          {'path': 'kegels', 'data': {'date': date, 'sets': sets, 'holdSeconds': holdSeconds}});
    }
    notifyListeners();
  }

  Future<void> setStartDate(String iso) async {
    startDate = iso;
    await setPref('program_start_date', iso);
  }

  // ---------- edit / delete (fix mistakes) ----------

  Future<void> deleteWorkoutLog(String date, String exercise) async {
    workouts.removeWhere((w) => w.date == date && w.exercise == exercise);
    _saveCache();
    try {
      await api.deleteWorkout(date, exercise: exercise);
    } catch (_) {
      await _enqueue({'method': 'DELETE', 'path': 'workout', 'data': {'date': date, 'exercise': exercise}});
    }
    notifyListeners();
  }

  Future<void> deleteWeightLog(String date) async {
    bodyWeight.removeWhere((w) => w.date == date);
    _saveCache();
    try {
      await api.deleteWeight(date);
    } catch (_) {
      await _enqueue({'method': 'DELETE', 'path': 'weight', 'data': {'date': date}});
    }
    notifyListeners();
  }

  Future<void> deleteMeasurementLog(String date) async {
    measurements.removeWhere((m) => m.date == date);
    _saveCache();
    try {
      await api.deleteMeasurements(date);
    } catch (_) {
      await _enqueue({'method': 'DELETE', 'path': 'measurements', 'data': {'date': date}});
    }
    notifyListeners();
  }

  Future<void> deleteKegelLog(int id) async {
    kegelLogs.removeWhere((k) => k.id == id);
    _saveCache();
    try {
      await api.deleteKegels(id);
    } catch (_) {
      await _enqueue({'method': 'DELETE', 'path': 'kegels', 'data': {'id': id}});
    }
    notifyListeners();
  }

  Future<void> editKegelLog(int id, int sets, int holdSeconds) async {
    final i = kegelLogs.indexWhere((k) => k.id == id);
    if (i >= 0) {
      final old = kegelLogs[i];
      kegelLogs[i] = KegelEntry(id, old.date, sets, holdSeconds);
      _saveCache();
    }
    try {
      await api.editKegels(id, sets, holdSeconds);
    } catch (_) {
      await _enqueue({
        'method': 'PUT',
        'path': 'kegels',
        'data': {'id': id, 'sets': sets, 'holdSeconds': holdSeconds}
      });
    }
    notifyListeners();
  }

  Future<void> saveCheckin(CheckinEntry c) async {
    checkins.removeWhere((x) => x.date == c.date);
    checkins.add(c);
    checkins.sort((a, b) => b.date.compareTo(a.date));
    _saveCache();
    final data = {
      'date': c.date,
      if (c.energy != null) 'energy': c.energy,
      if (c.sleepHours != null) 'sleepHours': c.sleepHours,
      if (c.waterL != null) 'waterL': c.waterL,
      if (c.mood != null) 'mood': c.mood,
      if (c.notes != null) 'notes': c.notes,
    };
    try {
      await api.postCheckin(data);
    } catch (_) {
      await _enqueue({'method': 'POST', 'path': 'checkins', 'data': data});
    }
    notifyListeners();
  }

  Future<void> deleteCheckinLog(String date) async {
    checkins.removeWhere((c) => c.date == date);
    _saveCache();
    try {
      await api.deleteCheckin(date);
    } catch (_) {
      await _enqueue({'method': 'DELETE', 'path': 'checkins', 'data': {'date': date}});
    }
    notifyListeners();
  }

  Future<void> applyRemindersIfEnabled() async {
    if (pref('reminder_enabled') == '1') {
      try {
        await ReminderService.scheduleForPrefs(this, true);
      } catch (_) {}
    }
  }

  // ---------- settings helpers ----------
  final Map<String, String> prefs = {};

  String pref(String key, [String def = '']) => prefs[key] ?? def;

  Future<void> setPref(String key, String value) async {
    prefs[key] = value;
    try {
      await api.putSetting(key, value);
    } catch (_) {
      await _enqueue({'method': 'POST', 'path': 'settings', 'data': {'key': key, 'value': value}});
    }
    notifyListeners();
  }

  // ---------- cache ----------
  void _saveCache() {
    final j = {
      'workouts': workouts.map((w) => w.toJson()).toList(),
      'bodyWeight': bodyWeight.map((w) => {'date': w.date, 'kg': w.kg}).toList(),
      'measurements': measurements
          .map((m) => {
                'date': m.date,
                'waistCm': m.waistCm,
                'chestCm': m.chestCm,
                'armCm': m.armCm,
              })
          .toList(),
      'kegels': kegelLogs
          .map((k) => {'id': k.id, 'date': k.date, 'sets': k.sets, 'holdSeconds': k.holdSeconds})
          .toList(),
      'checkins': checkins
          .map((c) => {'date': c.date, 'energy': c.energy, 'sleepHours': c.sleepHours, 'waterL': c.waterL, 'mood': c.mood, 'notes': c.notes})
          .toList(),
      'startDate': startDate,
      'unit': unit,
    };
    _prefs.setString(_kCache, jsonEncode(j));
  }

  void _loadCache() {
    final raw = _prefs.getString(_kCache);
    if (raw == null) return;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      workouts.clear();
      for (final w in j['workouts'] as List? ?? []) {
        final m = w as Map<String, dynamic>;
        workouts.add(WorkoutLog(
          date: m['date'] as String,
          exercise: m['exercise'] as String,
          week: m['week'] as int?,
          day: m['day'] as String?,
          sets: [
            for (final x in m['sets'] as List? ?? [])
              WorkoutSet(
                  (x as Map)['setNumber'] as int,
                  ((x['weightKg'] as num?) ?? 0).toDouble(),
                  ((x['reps'] as num?) ?? 0).toInt())
          ],
          notes: m['notes'] as String?,
        ));
      }
      bodyWeight.clear();
      for (final w in j['bodyWeight'] as List? ?? []) {
        final m = w as Map<String, dynamic>;
        bodyWeight.add(WeightEntry(m['date'] as String, (m['kg'] as num).toDouble()));
      }
      measurements.clear();
      for (final m in j['measurements'] as List? ?? []) {
        final x = m as Map<String, dynamic>;
        measurements.add(MeasurementEntry(
            x['date'] as String,
            (x['waistCm'] as num?)?.toDouble(),
            (x['chestCm'] as num?)?.toDouble(),
            (x['armCm'] as num?)?.toDouble()));
      }
      kegelLogs.clear();
      for (final k in j['kegels'] as List? ?? []) {
        final x = k as Map<String, dynamic>;
        kegelLogs.add(KegelEntry((x['id'] as num?)?.toInt() ?? 0,
            x['date'] as String, (x['sets'] as num).toInt(), (x['holdSeconds'] as num).toInt()));
      }
      checkins.clear();
      for (final c in j['checkins'] as List? ?? []) {
        final x = c as Map<String, dynamic>;
        checkins.add(CheckinEntry(x['date'] as String,
            (x['energy'] as num?)?.toInt(),
            (x['sleepHours'] as num?)?.toDouble(),
            (x['waterL'] as num?)?.toDouble(),
            x['mood'] as String?,
            x['notes'] as String?));
      }
      startDate = (j['startDate'] as String?) ?? '';
      unit = (j['unit'] as String?) ?? 'kg';
    } catch (_) {}
  }

  Future<void> _wipeLocal() async {
    workouts.clear();
    bodyWeight.clear();
    measurements.clear();
    kegelLogs.clear();
    _pending.clear();
    pendingCount = 0;
    prefs.clear();
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

  double volumeForDate(String date) {
    var v = 0.0;
    for (final l in logsOn(date)) {
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

  /// Streak of consecutive training days with logs (Sunday skipped — gym closed).
  int streak() {
    var streak = 0;
    var d = DateTime.now();
    for (var i = 0; i < 120; i++) {
      final iso = _iso(d);
      if (d.weekday == DateTime.sunday) {
        d = d.subtract(const Duration(days: 1));
        continue;
      }
      if (logsOn(iso).isNotEmpty) {
        streak++;
        d = d.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  double? lastWeight() =>
      bodyWeight.isEmpty ? null : bodyWeight.last.kg;

  /// Longest historical streak of consecutive training days (Mon–Sat, Sunday skipped).
  int bestStreak() {
    if (workouts.isEmpty) return 0;
    final days = <String>{};
    for (final w in workouts) {
      days.add(w.date);
    }
    if (days.isEmpty) return 0;
    final sorted = days.map(DateTime.parse).toList()..sort();
    final first = sorted.first;
    final today = DateTime.now();
    final start = DateTime(first.year, first.month, first.day);
    var best = 0;
    var cur = 0;
    for (var d = start; !d.isAfter(today); d = d.add(const Duration(days: 1))) {
      if (d.weekday == DateTime.sunday) continue;
      final iso = _iso(d);
      if (days.contains(iso)) {
        cur++;
        if (cur > best) best = cur;
      } else {
        cur = 0;
      }
    }
    return best;
  }

  /// Intensity 0..4 per day for the ember heatmap.
  /// 0 = nothing · 1 = check-in only · 2 = trained · 3 = trained + check-in ·
  /// 4 = trained + check-in + kegels.
  Map<String, int> heatmapCells() {
    final byDate = <String, int>{};
    for (final w in workouts) {
      byDate[w.date] = (byDate[w.date] ?? 0) | 2;
    }
    for (final c in checkins) {
      byDate[c.date] = (byDate[c.date] ?? 0) | 1;
    }
    for (final k in kegelLogs) {
      byDate[k.date] = (byDate[k.date] ?? 0) | 4;
    }
    return byDate;
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
