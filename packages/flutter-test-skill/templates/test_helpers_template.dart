/// Common test utilities for integration tests.
library;

import 'package:flutter_test/flutter_test.dart';

/// Key prefix used by the flutter_interaction_recorder package.
const _prefix = '__test_id__';

/// Pumps the app and waits for it to settle.
/// Replace with your app's main function call.
Future<void> launchApp(WidgetTester tester) async {
  // TODO: Replace with your app's entry point
  // app.main();
  await tester.pumpAndSettle();
}

/// Checks whether a widget with the given test ID is currently visible.
bool isTestIdVisible(WidgetTester tester, String testId) {
  final finder = find.byKey(ValueKey('$_prefix$testId'));
  return tester.any(finder);
}

/// Scrolls down until a test ID'd widget is visible.
Future<void> scrollUntilTestIdVisible(
  WidgetTester tester,
  String testId, {
  double delta = 200.0,
  int maxScrolls = 10,
}) async {
  for (int i = 0; i < maxScrolls; i++) {
    await tester.pumpAndSettle();
    if (isTestIdVisible(tester, testId)) return;
    await tester.drag(find.byType(Scrollable).first, Offset(0, -delta));
    await tester.pumpAndSettle();
  }
}

/// Taps a widget by its test ID.
Future<void> tapTestId(WidgetTester tester, String testId) async {
  await tester.tap(find.byKey(ValueKey('$_prefix$testId')));
  await tester.pumpAndSettle();
}

/// Enters text into a widget by its test ID.
Future<void> enterTestIdText(WidgetTester tester, String testId, String text) async {
  await tester.enterText(find.byKey(ValueKey('$_prefix$testId')), text);
  await tester.pumpAndSettle();
}
