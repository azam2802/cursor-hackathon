// Basic smoke test for the SummerDrift app shell.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:summer_activity/core/auth/auth_service.dart';
import 'package:summer_activity/main.dart';

void main() {
  testWidgets('App boots and shows the auth screen when signed out', (tester) async {
    await tester.pumpWidget(
      SummerDriftApp(
        authService: AuthService.testing(
          authStateChanges: Stream<User?>.value(null),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SummerDrift'), findsOneWidget);
    expect(find.text('Вход'), findsOneWidget);
    expect(find.text('Регистрация'), findsOneWidget);
    expect(find.text('Войти через Google'), findsOneWidget);
  });
}
