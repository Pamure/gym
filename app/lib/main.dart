import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/api.dart';
import 'state/app_state.dart';
import 'screens/home_shell.dart';
import 'services/reminders.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

final apiProvider = Provider<Api>((ref) => throw UnimplementedError());
final appStateProvider = ChangeNotifierProvider<AppState>((ref) {
  final api = ref.watch(apiProvider);
  return AppState(api);
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = await Api.create();
  runApp(ProviderScope(overrides: [apiProvider.overrideWithValue(api)], child: const IronForgeApp()));
}

class IronForgeApp extends ConsumerStatefulWidget {
  const IronForgeApp({super.key});

  @override
  ConsumerState<IronForgeApp> createState() => _IronForgeAppState();
}

class _IronForgeAppState extends ConsumerState<IronForgeApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ReminderService.init();
      final state = ref.read(appStateProvider);
      await state.init();
      await state.applyRemindersIfEnabled();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IronForge',
      debugShowCheckedModeBanner: false,
      theme: T.theme(),
      home: Consumer(builder: (context, ref, _) {
        final state = ref.watch(appStateProvider);
        switch (state.status) {
          case AuthStatus.booting:
            return const _Splash();
          case AuthStatus.loggedOut:
            return LoginScreen();
          case AuthStatus.loggedIn:
            return const HomeShell();
        }
      }),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center, size: 64, color: T.indigo),
            SizedBox(height: 12),
            Text('IronForge', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            SizedBox(height: 20),
            CircularProgressIndicator(color: T.pink),
          ],
        ),
      ),
    );
  }
}
