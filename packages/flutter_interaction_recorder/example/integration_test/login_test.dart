// ignore_for_file: unused_import
import 'package:patrol/patrol.dart';
import 'shared/shared_flows.dart';
import 'shared/test_accounts.dart';

void main() {
  for (final account in testAccounts) {
    patrolTest('login as ${account.role}', ($) async {
      // TODO: pump your app
      // await $.pumpWidgetAndSettle(MyApp());
      // await SharedFlows.login($, username: account.username, password: account.password);
      // expect($(testKey('logout_button')), findsOneWidget);
    });
  }
}
