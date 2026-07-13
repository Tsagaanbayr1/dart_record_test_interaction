/// Shared test flows reusable across all integration test files.
///
/// Each function here corresponds to a recorded interaction flow.
//  They are parameterized so different accounts/roles can reuse them.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Key prefix used by the flutter_interaction_recorder package.
const _prefix = '__test_id__';
ValueKey<String> _key(String id) => ValueKey('$_prefix$id');

class SharedFlows {
  /// Login flow — enter username and password, then tap the login button.
  ///
  /// Reuse this in any test that needs an authenticated user.
  static Future<void> login(
    WidgetTester tester, {
    required String username,
    required String password,
  }) async {
    await tester.enterText(find.byKey(_key('username_field')), username);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(_key('password_field')), password);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_key('login_button')));
    await tester.pumpAndSettle();
  }

  /// Registration flow — fill in registration fields and submit.
  static Future<void> register(
    WidgetTester tester, {
    required String username,
    required String email,
    required String password,
  }) async {
    await tester.enterText(find.byKey(_key('register_username_field')), username);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(_key('register_email_field')), email);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(_key('register_password_field')), password);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_key('register_submit_button')));
    await tester.pumpAndSettle();
  }

  /// Logout flow — tap the logout button and verify return to login page.
  static Future<void> logout(WidgetTester tester) async {
    await tester.tap(find.byKey(_key('logout_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(_key('login_button')), findsOneWidget);
  }

  /// Navigate to profile page from home.
  static Future<void> goToProfile(WidgetTester tester) async {
    await tester.tap(find.byKey(_key('profile_button')));
    await tester.pumpAndSettle();
  }

  /// Navigate back to home from another page.
  static Future<void> goBackHome(WidgetTester tester) async {
    await tester.pageBack();
    await tester.pumpAndSettle();
  }
}
