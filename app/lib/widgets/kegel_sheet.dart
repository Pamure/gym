import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/program.dart';
import '../main.dart';
import '../theme.dart';

/// Optional gentle pelvic-floor timer + session logging.
Future<void> showKegelSheet(BuildContext context, WidgetRef ref) {
  final state = ref.read(appStateProvider);
  final month = monthForWeek(state.currentWeek());
  final hold = [3, 5, 8][month];
  final phase = phaseForWeek(state.currentWeek());
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: T.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _KegelSheet(hold: hold, hint: phase.name),
  );
}

class _KegelSheet extends ConsumerStatefulWidget {
  final int hold;
  final String hint;
  const _KegelSheet({required this.hold, required this.hint});

  @override
  ConsumerState<_KegelSheet> createState() => _KegelSheetState();
}

class _KegelSheetState extends ConsumerState<_KegelSheet> {
  int _done = 0;
  bool _running = false;
  String _label = 'Squeeze & hold';

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _label = 'Squeeze… hold ${widget.hold}s — pelvic floor only';
    });
    for (var i = 0; i < widget.hold; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
    }
    if (!mounted) return;
    setState(
      () => _label =
          'Fully relax ${widget.hold}s — abs, glutes, thighs loose. Breathe.',
    );
    for (var i = 0; i < widget.hold; i++) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _done++;
      _label = 'Done #$_done — pause a few seconds, then Run again';
    });
  }

  @override
  Widget build(BuildContext context) {
    final phase = ref.watch(appStateProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Guided kegel set',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
              ),
              Text(widget.hint, style: TextStyle(color: T.dim, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Optional gentle practice: contract only the pelvic floor, then relax fully. '
            'The urine-stop cue is for identifying the muscle once, not repeated training. Stop if painful or tight.',
            style: TextStyle(color: T.dim, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: T.surface2,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _running ? T.pink : T.text,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilledButton.icon(
                onPressed: _running ? null : _run,
                style: FilledButton.styleFrom(
                  backgroundColor: T.indigo,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.play_arrow),
                label: Text(_running ? 'Running…' : 'Run hold ${_done + 1}'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: T.surface2,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _done == 0
                    ? null
                    : () async {
                        final date = DateTime.now()
                            .toIso8601String()
                            .split('T')
                            .first;
                        try {
                          await phase.logKegels(date, _done, widget.hold);
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Logged $_done gentle pelvic-floor holds${phase.pendingCount > 0 ? ' · waiting to sync' : ''}.',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Session not saved: $e')),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.check),
                label: const Text('Save session'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
