/// Test account definitions for multi-role testing with Patrol.
library;

class TestAccount {
  final String name;
  final String role;
  final Map<String, String> credentials;

  const TestAccount({
    required this.name,
    required this.role,
    required this.credentials,
  });

  String get username => credentials['username'] ?? '';
  String get password => credentials['password'] ?? '';
}

const testAccounts = <TestAccount>[
  TestAccount(
    name: 'admin',
    role: 'admin',
    credentials: {'username': 'admin', 'password': 'admin123'},
  ),
  TestAccount(
    name: 'standard_user',
    role: 'user',
    credentials: {'username': 'user1', 'password': 'user123'},
  ),
  TestAccount(
    name: 'guest',
    role: 'guest',
    credentials: {'username': 'guest', 'password': 'guest123'},
  ),
];
