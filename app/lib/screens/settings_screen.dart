import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../services/reminders.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          _card(
            title: 'Account',
            icon: Icons.person_outline,
            children: [
              _row('Username', state.username),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.password, color: T.indigo, size: 20),
                title: const Text('Change password', style: TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.chevron_right, color: T.dim),
                onTap: () => _changePassword(context, ref),
              ),
            ],
          ),
          _ReminderCard(),
          const SizedBox(height: 14),
          _card(
            title: 'Program start date',

            icon: Icons.calendar_today_outlined,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  state.startDate.isEmpty
                      ? 'Not set — Week 1 starts today whenever you begin. Set your true start date here.'
                      : 'Week 1 = ${state.startDate} · you are on Week ${state.currentWeek()}',
                  style: TextStyle(color: T.dim, fontSize: 12.5),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.tryParse(state.startDate) ?? now,
                    firstDate: DateTime(now.year - 1),
                    lastDate: now,
                    helpText: 'First day of Week 1 (your first gym day)',
                  );
                  if (picked != null) {
                    await state.setStartDate(
                        '${picked.year.toString().padLeft(4, '0')}-'
                        '${picked.month.toString().padLeft(2, '0')}-'
                        '${picked.day.toString().padLeft(2, '0')}');
                  }
                },
                icon: const Icon(Icons.edit_calendar, size: 18),
                label: Text(
                    state.startDate.isEmpty ? 'Set start date' : 'Change start date'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _card(
            title: 'Data',
            icon: Icons.cloud_sync_outlined,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.upload_outlined, color: T.indigo, size: 20),
                title: const Text('Sync now', style: TextStyle(fontSize: 14)),
                subtitle: Text(
                    state.lastError ?? 'Data is stored on YOUR server (yarmuk) + cached locally',
                    style: TextStyle(color: T.dim, fontSize: 11.5)),
                trailing: const Icon(Icons.chevron_right, color: T.dim),
                onTap: () async {
                  await state.refreshState();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(state.lastError ?? 'Synced')));
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.copy_all_outlined, color: T.indigo, size: 20),
                title: const Text('Export data (JSON)', style: TextStyle(fontSize: 14)),
                subtitle: Text('Copies everything to clipboard as a backup',
                    style: TextStyle(color: T.dim, fontSize: 11.5)),
                onTap: () async {
                  final payload = jsonEncode({
                    'exported': DateTime.now().toIso8601String(),
                    'username': state.username,
                    'startDate': state.startDate,
                    'bodyWeight': state.bodyWeight
                        .map((w) => {'date': w.date, 'kg': w.kg})
                        .toList(),
                    'measurements': state.measurements
                        .map((m) => {
                              'date': m.date,
                              'waistCm': m.waistCm,
                              'chestCm': m.chestCm,
                              'armCm': m.armCm,
                            })
                        .toList(),
                    'workouts': state.workouts.map((w) => w.toJson()).toList(),
                    'kegels': state.kegelLogs
                        .map((k) =>
                            {'date': k.date, 'sets': k.sets, 'hold': k.holdSeconds})
                        .toList(),
                  });
                  await Clipboard.setData(ClipboardData(text: payload));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Exported to clipboard — paste into a notes file')));
                  }
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.auto_awesome, color: T.indigo, size: 20),
                title: const Text('Clear IronCoach memory', style: TextStyle(fontSize: 14)),
                subtitle: Text('Deletes the saved coach chat history from the server',
                    style: TextStyle(color: T.dim, fontSize: 11.5)),
                trailing: const Icon(Icons.chevron_right, color: T.dim),
                onTap: () async {
                  await ref.read(appStateProvider).api.aiClear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Coach memory cleared')));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _card(
            title: 'Safety & privacy',
            icon: Icons.shield_outlined,
            children: [
              Text(
                '• Nobody can reach this app without your Cloudflare Access login\n'
                '• Session cookie is HttpOnly + encrypted, expires in 12h\n'
                '• Password is argon2-hashed server-side, never stored by the app\n'
                '• Server binds to localhost only — no open ports\n'
                '• Backups: nightly on the server, 14-day retention',
                style: TextStyle(color: T.dim, fontSize: 12, height: 1.6),
              ),
            ],
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: T.red,
              side: BorderSide(color: T.red.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: () async {
              final sure = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: T.surface,
                  title: const Text('Log out?'),
                  content: const Text('Your data stays safe on the server. '
                      'You will need your password to get back in.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
                    FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: T.red),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Log out')),
                  ],
                ),
              );
              if (sure == true) await ref.read(appStateProvider).logout();
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Log out'),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text('IronForge v1.0 · built for one athlete',
                style: TextStyle(color: T.dim, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _card({required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: T.indigo),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text('$k  ', style: TextStyle(color: T.dim, fontSize: 13)),
            Expanded(
                child: Text(v,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
          ],
        ),
      );

  Future<void> _changePassword(BuildContext context, WidgetRef ref) async {
    final cur = TextEditingController();
    final next = TextEditingController();
    String? err;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: T.surface,
          title: const Text('Change password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: cur,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current password')),
              const SizedBox(height: 10),
              TextField(
                  controller: next,
                  obscureText: true,
                  decoration:
                      const InputDecoration(labelText: 'New password (min 10 chars)')),
              if (err != null) ...[
                const SizedBox(height: 8),
                Text(err!, style: const TextStyle(color: T.red, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: T.indigo),
              onPressed: () async {
                try {
                  await ref
                      .read(appStateProvider)
                      .changePassword(cur.text, next.text);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  setLocal(() => err = '$e');
                }
              },
              child: const Text('Change'),
            ),
          ],
        ),
      ),
    );
    if (ok == true && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Password changed')));
    }
  }
}


class _ReminderCard extends ConsumerWidget {
  const _ReminderCard();

  Future<void> _pickTime(BuildContext context, WidgetRef ref, String key, String title) async {
    final st = ref.read(appStateProvider);
    final cur = st.pref(key);
    final parts = cur.split(':');
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: parts.length == 2 ? int.tryParse(parts[0]) ?? 6 : 6,
          minute: parts.length == 2 ? int.tryParse(parts[1]) ?? 30 : 30),
      helpText: title,
    );
    if (t != null) {
      final val = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
      await st.setPref(key, val);
      if (context.mounted) {
        final enabled = st.pref('reminder_enabled') == '1';
        await ReminderService.scheduleForPrefs(st, enabled);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(appStateProvider);
    final enabled = st.pref('reminder_enabled') == '1';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.alarm, size: 18, color: T.pink),
                const SizedBox(width: 8),
                const Text('Daily reminders (discipline)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
                'Push notifications on the Android app. Web shows these in the app only.',
                style: TextStyle(color: T.dim, fontSize: 11.5)),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable reminders', style: TextStyle(fontSize: 14)),
              value: enabled,
              onChanged: (v) async {
                await st.setPref('reminder_enabled', v ? '1' : '0');
                if (context.mounted) {
                  await ReminderService.scheduleForPrefs(st, v);
                  if (v && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Reminders scheduled — grant notification permission if asked')));
                  }
                }
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wb_sunny_outlined, color: T.amber, size: 20),
              title: Text('Wake-up: ${st.pref('wake_time', '06:30')}',
                  style: const TextStyle(fontSize: 14)),
              subtitle: const Text('Morning push: today\'s session + water + kegel nudge',
                  style: TextStyle(fontSize: 11.5)),
              trailing: const Icon(Icons.edit_outlined, color: T.dim, size: 18),
              onTap: () => _pickTime(context, ref, 'wake_time', 'Wake-up reminder'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.fitness_center, color: T.indigo, size: 20),
              title: Text('Gym session: ${st.pref('gym_time', '17:00')}',
                  style: const TextStyle(fontSize: 14)),
              subtitle: const Text('Today\'s exercises reminder — use your rest days off',
                  style: TextStyle(fontSize: 11.5)),
              trailing: const Icon(Icons.edit_outlined, color: T.dim, size: 18),
              onTap: () => _pickTime(context, ref, 'gym_time', 'Gym reminder'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.favorite_outline, color: T.pink, size: 20),
              title: Text('Kegels: ${st.pref('reminder_time', '21:00')}',
                  style: const TextStyle(fontSize: 14)),
              subtitle: const Text('Evening kegel set nudge (3 sets, 5 min)',
                  style: TextStyle(fontSize: 11.5)),
              trailing: const Icon(Icons.edit_outlined, color: T.dim, size: 18),
              onTap: () => _pickTime(context, ref, 'reminder_time', 'Kegel reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
