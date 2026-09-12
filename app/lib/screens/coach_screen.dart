import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/program.dart';
import '../main.dart';
import '../theme.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _ChatMsg {
  final String role; // user | assistant
  final String content;
  const _ChatMsg(this.role, this.content);
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final List<_ChatMsg> _msgs = [];
  final _input = TextEditingController();
  bool _busy = false;
  String? _model;
  String? _error;
  final _scroll = ScrollController();

  static const _suggestions = [
    'Am I progressing? Review my last weeks',
    'Why am I not sore — is it working?',
    'Check my form reminders for deadlift',
    'I missed 2 days. How do I get back on track?',
    'What should I eat today to hit protein?',
    'Why is my weight going up? Is that fat?',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadHistory);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final st = ref.read(appStateProvider);
      final h = await st.api.aiHistory();
      final list = h['messages'] as List? ?? [];
      setState(() {
        _msgs.clear();
        for (final m in list) {
          final role = (m as Map)['role'] as String? ?? 'assistant';
          final content = m['content'] as String? ?? '';
          if (content.trim().isNotEmpty) {
            _msgs.add(_ChatMsg(role == 'user' ? 'user' : 'assistant', content));
          }
        }
      });
      // Open at the LATEST message (bottom), not the first one. Instant jump —
      // animating here looks broken on cold open.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.jumpTo(_scroll.position.maxScrollExtent);
        }
      });
    } catch (_) {}
  }

  String _dayPlanForToday() {
    final st = ref.read(appStateProvider);
    final week = st.currentWeek();
    final wd = DateTime.now().weekday;
    final day = programDays[wd - 1];
    if (day.restDay) return 'Today is REST day (gym closed Sunday)';
    final month = monthForWeek(week);
    final buf = StringBuffer('${day.title} — week $week (${phaseForWeek(week).name}). '
        'Exercises: ');
    for (final pe in day.items) {
      buf.write('${pe.name} ${pe.setsByMonth[month]}x${pe.repsByMonth[month]}${pe.unit ?? ''}; ');
    }
    return buf.toString();
  }

  Future<void> _ask(String text) async {
    final q = text.trim();
    if (q.isEmpty || _busy) return;
    setState(() {
      _msgs.add(_ChatMsg('user', q));
      _busy = true;
      _error = null;
    });
    _scrollDown();
    try {
      final st = ref.read(appStateProvider);
      final r = await st.api.aiAsk(q, dayPlan: _dayPlanForToday());
      setState(() {
        _msgs.add(_ChatMsg('assistant', r['reply'] as String? ?? ''));
        _model = r['model'] as String?;
        _busy = false;
      });
    } catch (e) {
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
    _scrollDown();
  }

  void _scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showSuggestions = _msgs.isEmpty && !_busy;
    return Column(
      children: [
        if (_msgs.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 6, top: 2),
              child: IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Reload conversation',
                icon: const Icon(Icons.refresh, size: 17, color: T.dim),
                onPressed: _loadHistory,
              ),
            ),
          ),
        Expanded(
          child: _msgs.isEmpty && !_busy
              ? _Welcome(suggestions: _suggestions, onAsk: _ask)
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(14),
                  itemCount: _msgs.length + (_busy ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i == _msgs.length) {
                      return const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                            child: SizedBox(
                                height: 18, width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2))),
                      );
                    }
                    final m = _msgs[i];
                    final mine = m.role == 'user';
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.82),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: mine ? T.indigo : T.surface2,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: Radius.circular(mine ? 14 : 2),
                            bottomRight: Radius.circular(mine ? 2 : 14),
                          ),
                        ),
                        child: Text(m.content,
                            style: TextStyle(
                                fontSize: 13.5,
                                height: 1.45,
                                color: mine ? Colors.white : T.text)),
                      ),
                    );
                  },
                ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(_error!,
                maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: T.red, fontSize: 11.5)),
          ),
        if (showSuggestions && _model == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
                'IronCoach reads your server data: workouts, weight, kegels, check-ins, '
                'missed days and your current program week — answers are grounded in it.',
                textAlign: TextAlign.center,
                style: TextStyle(color: T.dim, fontSize: 11)),
          ),
        if (_model != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text('via $_model',
                  style: TextStyle(color: T.dim, fontSize: 10)),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 3,
                    enabled: !_busy,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (v) {
                      _input.clear();
                      _ask(v);
                    },
                    decoration: InputDecoration(
                      hintText: 'Ask IronCoach… (reads your real data)',
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(backgroundColor: T.indigo),
                  onPressed: _busy
                      ? null
                      : () {
                          final v = _input.text;
                          _input.clear();
                          _ask(v);
                        },
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Welcome extends StatelessWidget {
  final List<String> suggestions;
  final void Function(String) onAsk;
  const _Welcome({required this.suggestions, required this.onAsk});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: T.gradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('IronCoach 🤖',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
              SizedBox(height: 6),
              Text(
                  'Your personal AI trainer. It reads YOUR live data from the server — '
                  'workouts, weights, measurements, kegels, check-ins, missed days — plus '
                  'your 12-week program — and coaches you like a human trainer would.',
                  style: TextStyle(fontSize: 13, height: 1.5, color: Colors.white)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('Try asking',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 8),
        for (final s in suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: T.text,
                side: const BorderSide(color: T.border),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onPressed: () => onAsk(s),
              child: Text(s, style: const TextStyle(fontSize: 13)),
            ),
          ),
      ],
    );
  }
}
