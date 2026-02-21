import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bluesky_service.dart';
import '../services/credential_service.dart';
import '../services/settings_service.dart';

/// Provides the singleton BlueskyService instance.
final blueskyServiceProvider = Provider<BlueskyService>((ref) {
  return BlueskyServiceImpl();
});

/// Provides the CredentialService for secure credential storage.
final credentialServiceProvider = Provider<CredentialService>((ref) {
  return SecureCredentialService();
});

/// Provides SharedPreferences (must be overridden at app startup).
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden');
});

/// Provides the SettingsService backed by SharedPreferences.
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.watch(sharedPreferencesProvider));
});
