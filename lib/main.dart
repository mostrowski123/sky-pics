import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/auth_state.dart';
import 'providers/auth_provider.dart';
import 'providers/service_providers.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const BlueskyImageViewerApp(),
    ),
  );
}

class BlueskyImageViewerApp extends ConsumerWidget {
  const BlueskyImageViewerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);

    return MaterialApp(
      title: 'Bluesky Image Viewer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.dark,
      ),
      home: switch (auth) {
        AuthAuthenticated() => const FeedScreen(),
        AuthLoading() => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        _ => const LoginScreen(),
      },
    );
  }
}
