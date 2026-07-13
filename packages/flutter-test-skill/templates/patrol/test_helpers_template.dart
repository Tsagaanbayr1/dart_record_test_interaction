/// Common test utilities for Patrol integration tests.
library;

import 'package:patrol/patrol.dart';
import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';

/// Pumps the app and waits for it to settle.
/// Replace with your app's entry point.
Future<void> launchApp(PatrolIntegrationTester $) async {
  // TODO: Replace with your app's entry point
  // app.main();
  await $.pumpAndSettle();
}

/// Taps a widget by its test ID.
Future<void> tapTestId(PatrolIntegrationTester $, String testId) async {
  await $(testKey(testId)).tap();
  await $.pumpAndSettle();
}

/// Enters text into a widget by its test ID.
Future<void> enterTestIdText(PatrolIntegrationTester $, String testId, String text) async {
  await $(testKey(testId)).enterText(text);
  await $.pumpAndSettle();
}

/// Scrolls until a test-ID'd widget is visible.
Future<void> scrollUntilTestIdVisible(
  PatrolIntegrationTester $,
  String testId, {
  Finder? view,
}) async {
  await $(testKey(testId)).scrollTo(view: view);
  await $.pumpAndSettle();
}

/// Checks whether a widget with the given test ID exists.
bool testIdExists(PatrolIntegrationTester $, String testId) {
  return $(testKey(testId)).exists;
}

/// Checks whether a widget with the given test ID is visible.
bool testIdVisible(PatrolIntegrationTester $, String testId) {
  return $(testKey(testId)).visible;
}
