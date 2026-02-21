import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sky_pics/models/auth_state.dart';
import 'package:sky_pics/providers/auth_provider.dart';
import 'package:sky_pics/providers/service_providers.dart';
import 'package:sky_pics/services/credential_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockBlueskyService mockService;
  late MockCredentialService mockCredService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockBlueskyService();
    mockCredService = MockCredentialService();

    // Default: no saved credentials, save/clear succeed.
    when(() => mockCredService.load()).thenAnswer((_) async => null);
    when(() => mockCredService.save(any(), any())).thenAnswer((_) async {});
    when(() => mockCredService.clear()).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        blueskyServiceProvider.overrideWithValue(mockService),
        credentialServiceProvider.overrideWithValue(mockCredService),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('AuthNotifier', () {
    test('initial state is AuthLoading while checking credentials', () {
      final state = container.read(authProvider);
      expect(state, isA<AuthLoading>());
    });

    test('resolves to AuthInitial when no saved credentials', () async {
      container.read(authProvider); // trigger build
      await Future.delayed(const Duration(milliseconds: 50));
      expect(container.read(authProvider), isA<AuthInitial>());
    });

    test('login success transitions to AuthAuthenticated', () async {
      when(() => mockService.login(any(), any()))
          .thenAnswer((_) async => fakeSession());

      await container.read(authProvider.notifier).login(
        'testuser.bsky.social',
        'app-password-123',
      );

      final state = container.read(authProvider);
      expect(state, isA<AuthAuthenticated>());
      final auth = state as AuthAuthenticated;
      expect(auth.handle, 'testuser.bsky.social');
      expect(auth.did, 'did:plc:testuser123');
    });

    test('login shows loading state', () async {
      when(() => mockService.login(any(), any()))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return fakeSession();
      });

      final future = container.read(authProvider.notifier).login('test', 'pass');

      expect(container.read(authProvider), isA<AuthLoading>());

      await future;
      expect(container.read(authProvider), isA<AuthAuthenticated>());
    });

    test('login failure transitions to AuthError', () async {
      when(() => mockService.login(any(), any()))
          .thenThrow(Exception('Unauthorized'));

      await container.read(authProvider.notifier).login('bad', 'credentials');

      final state = container.read(authProvider);
      expect(state, isA<AuthError>());
      expect((state as AuthError).message, contains('Invalid handle'));
    });

    test('login network error shows network message', () async {
      when(() => mockService.login(any(), any()))
          .thenThrow(Exception('SocketException: connection refused'));

      await container.read(authProvider.notifier).login('test', 'pass');

      final state = container.read(authProvider) as AuthError;
      expect(state.message, contains('Network error'));
    });

    test('logout resets to AuthInitial', () async {
      when(() => mockService.login(any(), any()))
          .thenAnswer((_) async => fakeSession());

      await container.read(authProvider.notifier).login('test', 'pass');
      expect(container.read(authProvider), isA<AuthAuthenticated>());

      await container.read(authProvider.notifier).logout();
      expect(container.read(authProvider), isA<AuthInitial>());
    });
  });

  group('Credential persistence', () {
    test('login saves credentials when rememberMe is true', () async {
      when(() => mockService.login(any(), any()))
          .thenAnswer((_) async => fakeSession());

      await container
          .read(authProvider.notifier)
          .login('myuser', 'mypass', rememberMe: true);

      verify(() => mockCredService.save('myuser', 'mypass')).called(1);
    });

    test('login clears credentials when rememberMe is false', () async {
      when(() => mockService.login(any(), any()))
          .thenAnswer((_) async => fakeSession());

      await container.read(authProvider.notifier).login('myuser', 'mypass');

      verifyNever(() => mockCredService.save(any(), any()));
      verify(() => mockCredService.clear()).called(1);
    });

    test('login does not save credentials on failure', () async {
      when(() => mockService.login(any(), any()))
          .thenThrow(Exception('Unauthorized'));

      await container.read(authProvider.notifier).login('bad', 'creds');

      verifyNever(() => mockCredService.save(any(), any()));
    });

    test('logout clears saved credentials', () async {
      when(() => mockService.login(any(), any()))
          .thenAnswer((_) async => fakeSession());

      await container
          .read(authProvider.notifier)
          .login('test', 'pass', rememberMe: true);
      await container.read(authProvider.notifier).logout();

      verify(() => mockCredService.clear()).called(1);
    });

    test('auto-login succeeds with saved credentials', () async {
      when(() => mockCredService.load()).thenAnswer(
        (_) async => const SavedCredential(
          handle: 'saved.bsky.social',
          appPassword: 'saved-pass',
        ),
      );
      when(() => mockService.login('saved.bsky.social', 'saved-pass'))
          .thenAnswer((_) async => fakeSession());

      // Create a fresh container that will trigger build() -> _tryAutoLogin.
      final autoContainer = ProviderContainer(
        overrides: [
          blueskyServiceProvider.overrideWithValue(mockService),
          credentialServiceProvider.overrideWithValue(mockCredService),
        ],
      );
      addTearDown(autoContainer.dispose);

      // Read to trigger build.
      autoContainer.read(authProvider);

      // Allow the microtask to run.
      await Future.delayed(const Duration(milliseconds: 50));

      final state = autoContainer.read(authProvider);
      expect(state, isA<AuthAuthenticated>());
    });

    test('auto-login fails gracefully with invalid credentials', () async {
      when(() => mockCredService.load()).thenAnswer(
        (_) async => const SavedCredential(
          handle: 'old.bsky.social',
          appPassword: 'expired-pass',
        ),
      );
      when(() => mockService.login('old.bsky.social', 'expired-pass'))
          .thenThrow(Exception('Unauthorized'));

      final autoContainer = ProviderContainer(
        overrides: [
          blueskyServiceProvider.overrideWithValue(mockService),
          credentialServiceProvider.overrideWithValue(mockCredService),
        ],
      );
      addTearDown(autoContainer.dispose);

      autoContainer.read(authProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      // Should silently return to AuthInitial, NOT AuthError.
      final state = autoContainer.read(authProvider);
      expect(state, isA<AuthInitial>());
    });

    test('auto-login does nothing when no credentials saved', () async {
      when(() => mockCredService.load()).thenAnswer((_) async => null);

      final autoContainer = ProviderContainer(
        overrides: [
          blueskyServiceProvider.overrideWithValue(mockService),
          credentialServiceProvider.overrideWithValue(mockCredService),
        ],
      );
      addTearDown(autoContainer.dispose);

      autoContainer.read(authProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final state = autoContainer.read(authProvider);
      expect(state, isA<AuthInitial>());
      verifyNever(() => mockService.login(any(), any()));
    });
  });
}
