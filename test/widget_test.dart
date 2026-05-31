// Basic smoke test for the SummerDrift app shell.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:summer_activity/main.dart';

void main() {
  testWidgets('App boots and shows the bottom navigation', (tester) async {
    await tester.pumpWidget(const SummerDriftApp());
    await tester.pump();

    // The four primary destinations should be reachable from the nav bar.
    expect(find.text('маршрут'), findsOneWidget);
    expect(find.text('ai'), findsOneWidget);
    expect(find.text('тайники'), findsOneWidget);
    expect(find.text('профиль'), findsOneWidget);

    // Switch to the AI planner tab.
    await tester.tap(find.byIcon(Icons.psychology));
    await tester.pump();
    expect(find.text('AI Планировщик'), findsOneWidget);
  });
}
