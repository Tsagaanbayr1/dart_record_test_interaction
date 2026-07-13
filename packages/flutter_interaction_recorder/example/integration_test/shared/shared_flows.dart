import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';

class SharedFlows {
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

  static Future<void> logout(PatrolIntegrationTester $) async {
    await $(testKey('logout_button')).tap();
    await $.pumpAndSettle();
    expect($(testKey('login_button')), findsOneWidget);
  }

  static Future<void> goToProfile(PatrolIntegrationTester $) async {
    await $(testKey('profile_button')).tap();
    await $.pumpAndSettle();
  }
}
