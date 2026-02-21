import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:atproto_core/atproto_core.dart' as core;
import 'package:sky_pics/screens/login_screen.dart';
import 'package:sky_pics/providers/service_providers.dart';
import 'package:sky_pics/services/credential_service.dart';
import '../helpers/test_helpers.dart';

void main() {
  late MockBlueskyService mockService;
  late MockCredentialService mockCredService;

  setUp(() {
    mockService = MockBlueskyService();
    mockCredService = MockCredentialService();

    // Default: no saved credentials, save/clear succeed.
    when(() => mockCredService.load()).thenAnswer((_) async => null);
    when(() => mockCredService.save(any(), any())).thenAnswer((_) async {});
    when(() => mockCredService.clear()).thenAnswer((_) async {});
  });

  Widget buildLoginScreen({SavedCredential? savedCredential}) {
    // If a saved credential is provided, mock it.
    if (savedCredential != null) {
      when(() => mockCredService.load())
          .thenAnswer((_) async => savedCredential);
    }

    return ProviderScope(
      overrides: [
        blueskyServiceProvider.overrideWithValue(mockService),
        credentialServiceProvider.overrideWithValue(mockCredService),
      ],
      child: const MaterialApp(home: LoginScreen()),
    );
  }

  group('LoginScreen', () {
    testWidgets('renders handle and password fields', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('handle_field')), findsOneWidget);
      expect(find.byKey(const Key('password_field')), findsOneWidget);
    });

    testWidgets('renders App Password security instructions', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('App Password'),
        findsWidgets,
      );
      expect(
        find.textContaining('Do not use your main password'),
        findsOneWidget,
      );
    });

    testWidgets('renders sign in button', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('login button triggers auth on valid input', (tester) async {
      when(() => mockService.login(any(), any()))
          .thenAnswer((_) async => fakeSession());

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('handle_field')), 'test.bsky.social');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'app-pass-123');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      verify(() =>
          mockService.login('test.bsky.social', 'app-pass-123')).called(1);
    });

    testWidgets('shows loading indicator during login', (tester) async {
      final completer = Completer<core.Session>();
      when(() => mockService.login(any(), any()))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('handle_field')), 'test.bsky.social');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'pass');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the login to avoid pending timers.
      completer.complete(fakeSession());
      await tester.pumpAndSettle();
    });

    testWidgets('shows error message on login failure', (tester) async {
      when(() => mockService.login(any(), any()))
          .thenThrow(Exception('Unauthorized'));

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.enterText(
          find.byKey(const Key('handle_field')), 'bad');
      await tester.enterText(
          find.byKey(const Key('password_field')), 'cred');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('error_text')), findsOneWidget);
    });

    testWidgets('does not call login when fields are empty', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pump();

      verifyNever(() => mockService.login(any(), any()));
    });

    testWidgets('renders security icon', (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });

  group('Saved account', () {
    testWidgets('shows saved account card when credentials exist',
        (tester) async {
      await tester.pumpWidget(buildLoginScreen(
        savedCredential: const SavedCredential(
          handle: 'alice.bsky.social',
          appPassword: 'saved-pass',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('saved_account_card')), findsOneWidget);
      expect(find.text('alice.bsky.social'), findsOneWidget);
      expect(find.text('Tap to sign in quickly'), findsOneWidget);
    });

    testWidgets('does not show saved account card when no credentials',
        (tester) async {
      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('saved_account_card')), findsNothing);
    });

    testWidgets('tapping saved account triggers login', (tester) async {
      when(() => mockService.login(any(), any()))
          .thenAnswer((_) async => fakeSession());

      await tester.pumpWidget(buildLoginScreen(
        savedCredential: const SavedCredential(
          handle: 'alice.bsky.social',
          appPassword: 'saved-pass',
        ),
      ));
      await tester.pumpAndSettle();

      // Reset call count — build() fires _tryAutoLogin which already called
      // login once with the saved credentials.
      clearInteractions(mockService);

      await tester.tap(find.byKey(const Key('saved_account_card')));
      await tester.pump();

      verify(() =>
          mockService.login('alice.bsky.social', 'saved-pass')).called(1);
    });
  });
}
