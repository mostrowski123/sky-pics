import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_state.dart';
import '../services/credential_service.dart';
import 'service_providers.dart';

/// Manages authentication state using Riverpod v3 Notifier.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Start in loading so saved-credential users skip the login screen.
    Future.microtask(() => _tryAutoLogin());
    return const AuthLoading();
  }

  /// Attempt to login with saved credentials. On failure, silently
  /// return to [AuthInitial] so the user sees the normal login screen.
  Future<void> _tryAutoLogin() async {
    try {
      final credService = ref.read(credentialServiceProvider);
      final saved = await credService.load();
      if (saved == null) {
        state = const AuthInitial();
        return;
      }

      final service = ref.read(blueskyServiceProvider);
      final session = await service.login(saved.handle, saved.appPassword);
      state = AuthAuthenticated(
        handle: session.handle,
        did: session.did,
      );
    } catch (_) {
      // Expired or invalid saved credentials — show login screen quietly.
      state = const AuthInitial();
    }
  }

  Future<void> login(String handle, String appPassword,
      {bool rememberMe = false}) async {
    state = const AuthLoading();
    try {
      final service = ref.read(blueskyServiceProvider);
      final session = await service.login(handle, appPassword);

      // Save or clear credentials based on user preference.
      try {
        final credService = ref.read(credentialServiceProvider);
        if (rememberMe) {
          await credService.save(handle, appPassword);
        } else {
          await credService.clear();
        }
      } catch (_) {
        // Storage failure is non-fatal — login still succeeds.
      }

      state = AuthAuthenticated(
        handle: session.handle,
        did: session.did,
      );
    } catch (e) {
      state = AuthError(_friendlyError(e));
    }
  }

  Future<void> logout() async {
    try {
      final credService = ref.read(credentialServiceProvider);
      await credService.clear();
    } catch (_) {
      // Ignore storage errors on logout.
    }
    state = const AuthInitial();
  }

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('unauthorized') || msg.contains('authentication')) {
      return 'Invalid handle or app password. Please check your credentials.';
    }
    if (msg.contains('socket') || msg.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    return 'Login failed: $e';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Provides the saved credential for display on the login screen.
final savedCredentialProvider = FutureProvider<SavedCredential?>((ref) {
  final credService = ref.read(credentialServiceProvider);
  return credService.load();
});
