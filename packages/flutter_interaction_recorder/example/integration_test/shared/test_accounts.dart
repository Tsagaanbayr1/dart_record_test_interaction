class TestAccount {
  final String name;
  final String role;
  final Map<String, String> credentials;
  const TestAccount({required this.name, required this.role, required this.credentials});
  String get username => credentials['username'] ?? '';
  String get password => credentials['password'] ?? '';
}

const testAccounts = [
  TestAccount(name: 'admin', role: 'admin', credentials: {'username': 'admin', 'password': 'admin123'}),
  TestAccount(name: 'user', role: 'user', credentials: {'username': 'user1', 'password': 'user123'}),
];
