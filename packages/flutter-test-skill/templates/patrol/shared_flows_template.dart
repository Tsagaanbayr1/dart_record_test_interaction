/// Shared test flows using Patrol's $(...) finder syntax.
///
/// These functions use PatrolIntegrationTester ($) instead of WidgetTester.
/// They are reusable across all Patrol integration test files.
library;

import 'package:patrol/patrol.dart';
import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';

class SharedFlows {
  /// Login flow — enter username and password, then tap login.
  static Future<void> login(
    PatrolIntegrationTester $, {
    required String username,
    required String password,
  }) async {
    await $(testKey('username_field')).enterText(username);
    await $.pumpAndSettle();

    await $(testKey('password_field')).enterText(password);
    await $.pumpAndSettle();

    await $(testKey('login_button')).tap();
    await $.pumpAndSettle();
  }

  /// Registration flow.
  static Future<void> register(
    PatrolIntegrationTester $, {
    required String username,
    required String email,
    required String password,
  }) async {
    await $(testKey('register_username_field')).enterText(username);
    await $.pumpAndSettle();

    await $(testKey('register_email_field')).enterText(email);
    await $.pumpAndSettle();

    await $(testKey('register_password_field')).enterText(password);
    await $.pumpAndSettle();

    await $(testKey('register_submit_button')).tap();
    await $.pumpAndSettle();
  }

  /// Logout flow — tap logout and verify return to login page.
  static Future<void> logout(PatrolIntegrationTester $) async {
    await $(testKey('logout_button')).tap();
    await $.pumpAndSettle();

    expect($(testKey('login_button')), findsOneWidget);
  }

  /// Navigate to profile page.
  static Future<void> goToProfile(PatrolIntegrationTester $) async {
    await $(testKey('profile_button')).tap();
    await $.pumpAndSettle();
  }

  /// Scroll until a test-ID'd widget is visible (Patrol's built-in scrollTo).
  static Future<void> scrollToTestId(
    PatrolIntegrationTester $,
    String testId, {
    Finder? view,
  }) async {
    await $(testKey(testId)).scrollTo(view: view);
    await $.pumpAndSettle();
  }

  /// Grant runtime permissions via Patrol's native automation.
  /// Call this before flows that trigger permission dialogs.
  static Future<void> grantPermissions(PatrolIntegrationTester $) async {
    await $.native.grantPermissionWhenInUse();
  }
}
