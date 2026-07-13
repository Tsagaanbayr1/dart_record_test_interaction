# Flutter Test Interaction Skill

## Purpose

This skill enables AI agents to add test IDs to every interactive element in a Flutter application and generate componentized integration tests from recorded user interactions.

It works with the `flutter_interaction_recorder` Dart package, which overlays a record button on any Flutter app, captures every tap, text input, scroll, and navigation event using test IDs, and exports recordings as JSON. The AI agent then converts those recordings into clean, reusable integration test code.

## When to Use

- When the user asks to add test IDs or test coverage to a Flutter app
- When the user has recorded interactions and wants integration tests generated
- When the user wants to componentize or reuse test flows (login, registration) across multiple test scenarios
- When the user wants to test the same flow with multiple accounts or roles

## Workflow

### Phase 1: Add Test IDs to the Flutter App

1. Add `flutter_interaction_recorder` to `pubspec.yaml`:
   ```yaml
   dependencies:
     flutter_interaction_recorder: ^0.1.0
   ```

2. Wrap the app with `RecorderOverlay` in `main.dart`:
   ```dart
   import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';

   void main() {
     runApp(const RecorderOverlay(child: MyApp()));
   }
   ```

3. Add the navigator observer to `MaterialApp` or `CupertinoApp`:
   ```dart
   MaterialApp(
     navigatorObservers: [RecorderOverlay.navigatorObserver],
     ...
   )
   ```

4. Wrap EVERY interactive widget with `TestId`:
   ```dart
   TestId(
     id: 'login_button',
     child: ElevatedButton(onPressed: _login, child: Text('Login')),
   )
   ```

5. Replace EVERY `TextField` with `TestIdTextField`:
   ```dart
   TestIdTextField(
     id: 'username_field',
     decoration: InputDecoration(labelText: 'Username'),
   )
   ```

6. Use the `.withTestId()` extension for a terser syntax:
   ```dart
   ElevatedButton(onPressed: _login, child: Text('Login')).withTestId('login_button')
   ```

### Test ID Naming Convention

Use descriptive, snake_case IDs that describe the widget's purpose, not its type or position:

- `login_button` not `elevated_button_1`
- `username_field` not `textfield_0`
- `profile_tab` not `tab_2`
- `add_to_cart_button` not `fab_main`
- `item_3_delete_button` for list items (use the index)

For list items with dynamic content, include the index or a unique identifier:
```dart
TestId(id: 'item_${item.id}', child: ListTile(...))
```

### What Gets a Test ID

Add test IDs to ALL of these:
- Buttons (ElevatedButton, TextButton, OutlinedButton, IconButton, FloatingActionButton)
- Text fields (TextField, TextFormField — replace with TestIdTextField)
- Checkboxes and switches
- Radio buttons
- List tiles (ListTile, ExpansionTile)
- Tabs (TabBar items)
- Bottom navigation bar items
- App bar actions
- Drawer menu items
- Snackbar action buttons
- Dialog buttons
- Dropdown items
- Sliders and progress indicators (if interactive)
- Any widget with an `onTap`, `onPressed`, `onChanged`, or `onSubmitted` callback

### Phase 2: Record Interactions

1. Run the app in debug mode: `flutter run`
2. Tap the floating record button (top-right corner, draggable)
3. Perform the actions you want to test (enter username, password, tap login, navigate, etc.)
4. Long-press the record button and choose "Save Recording"
5. The recording is saved as JSON in the app's documents directory

Repeat for each flow you want to test:
- Login flow (with valid credentials)
- Registration flow
- Navigation flow (browse home, open profile, logout)
- Any feature-specific flow

### Phase 3: Generate Integration Tests

1. Locate saved recordings (check `getApplicationDocumentsDirectory()/recordings/*.json`)
2. Use the `TestCodeGenerator` to convert recordings to test code:
   ```dart
   import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';

   final storage = RecordingStorage();
   final sessions = await storage.listAll();
   final generator = TestCodeGenerator();

   // Generate from a single session
   final files = generator.generate(sessions.first);
   for (final entry in files.entries) {
     print('--- ${entry.key} ---');
     print(entry.value);
   }

   // Generate from multiple sessions (enables shared flows)
   final allFiles = generator.generateMulti(sessions);
   ```

3. Or let the AI agent read the recording JSON and generate test code directly using the patterns in `templates/`.

### Phase 4: Componentize and Reuse Test Flows

The generator automatically extracts reusable flows:
- A login flow (username + password + login button tap) becomes a `login()` function
- A registration flow becomes a `registration()` function
- These are placed in `shared_flows.dart` and imported by all test files

To manually componentize:
1. Identify repeated sequences across recordings (same test IDs, same order)
2. Extract them into a shared helper class
3. Parameterize text inputs (credentials) so different accounts can reuse the flow

Example shared flow:
```dart
class SharedFlows {
  static Future<void> login(WidgetTester tester, {required String username, required String password}) async {
    await tester.enterText(find.byKey(const ValueKey('__test_id__username_field')), username);
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('__test_id__password_field')), password);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('__test_id__login_button')));
    await tester.pumpAndSettle();
  }
}
```

### Phase 5: Multi-Account Testing

1. Define test accounts with different roles:
   ```dart
   final accounts = [
     TestAccount(name: 'admin', role: 'admin', credentials: {'username': 'admin', 'password': 'admin123'}),
     TestAccount(name: 'user', role: 'user', credentials: {'username': 'user1', 'password': 'user123'}),
     TestAccount(name: 'guest', role: 'guest', credentials: {'username': 'guest', 'password': 'guest123'}),
   ];
   ```

2. Run the same flow with each account:
   ```dart
   for (final account in accounts) {
     testWidgets('login as ${account.role}', (tester) async {
       app.main();
       await tester.pumpAndSettle();
       await SharedFlows.login(tester,
         username: account.credentials['username']!,
         password: account.credentials['password']!,
       );
       // Add role-specific assertions here
     });
   }
   ```

## Test Code Patterns

### Finding Widgets

Always use `find.byKey` with the test ID value key:
```dart
find.byKey(const ValueKey('__test_id__<id>'))
```

### Tapping
```dart
await tester.tap(find.byKey(const ValueKey('__test_id__login_button')));
await tester.pumpAndSettle();
```

### Entering Text
```dart
await tester.enterText(find.byKey(const ValueKey('__test_id__username_field')), 'testuser');
await tester.pumpAndSettle();
```

### Scrolling
```dart
await tester.drag(find.byKey(const ValueKey('__test_id__item_list')), const Offset(0, -200));
await tester.pumpAndSettle();
```

### Scrolling Until Visible
```dart
await tester.scrollUntilVisible(
  find.byKey(const ValueKey('__test_id__item_15')),
  200.0,
  scrollable: find.byKey(const ValueKey('__test_id__item_list')),
);
await tester.pumpAndSettle();
```

### Navigation Assertions
```dart
await tester.tap(find.byKey(const ValueKey('__test_id__profile_button')));
await tester.pumpAndSettle();
expect(find.text('Profile'), findsOneWidget);
```

### Back Navigation
```dart
await tester.pageBack();
await tester.pumpAndSettle();
```

## Checklist for AI Review

When reviewing a Flutter app for test ID coverage, check:

- [ ] `RecorderOverlay` wraps the app in `main.dart`
- [ ] `RecorderOverlay.navigatorObserver` added to `MaterialApp`/`CupertinoApp`
- [ ] Every `ElevatedButton`, `TextButton`, `OutlinedButton`, `IconButton` has a `TestId`
- [ ] Every `TextField` and `TextFormField` replaced with `TestIdTextField`
- [ ] Every `ListTile` with `onTap` has a `TestId`
- [ ] Every `FloatingActionButton` has a `TestId`
- [ ] Every `Checkbox`, `Switch`, `Radio` has a `TestId`
- [ ] Every `TabBar` tab has a `TestId`
- [ ] Every `BottomNavigationBar` item has a `TestId`
- [ ] Every `AppBar` action has a `TestId`
- [ ] Every `Drawer` item has a `TestId`
- [ ] Every dialog/dismissible action has a `TestId`
- [ ] Test IDs follow snake_case naming and describe purpose
- [ ] No duplicate test IDs on the same page
- [ ] List items include their index or unique ID in the test ID

## Integration Test File Structure

```
integration_test/
├── shared/
│   ├── shared_flows.dart       # Reusable flow functions (login, registration)
│   ├── test_accounts.dart      # Account definitions with roles
│   └── test_helpers.dart       # Common utilities (app launch, wait, etc.)
├── login_test.dart             # Login flow tests (one per role)
├── registration_test.dart      # Registration flow tests
├── navigation_test.dart        # Navigation / browse flow tests
└── feature_test.dart           # Feature-specific flow tests
```

## Cross-Referencing Rules

- A login flow recorded once should be reused by ALL tests that need authentication
- A registration flow should be reused by tests that need a registered user
- Navigation patterns (home -> profile -> logout) should be shared
- Never duplicate a flow — always import from `shared_flows.dart`
- If a flow varies slightly (e.g., different button on a different page), create a variant with a suffix: `loginVariant2()`

## Error Handling in Generated Tests

Generated tests should include basic assertions:
- After navigation, assert the expected page content is visible
- After form submission, assert success/failure indicators
- After logout, assert the login page is shown

```dart
await SharedFlows.login(tester, username: 'admin', password: 'admin123');
expect(find.byKey(const ValueKey('__test_id__logout_button')), findsOneWidget);
```

## Patrol Integration

[Patrol](https://pub.dev/packages/patrol) is a powerful E2E testing framework that overcomes `integration_test` limitations by handling native interactions (permissions, notifications, etc.). This skill fully supports Patrol.

### Setting Up Patrol

1. Add patrol to `pubspec.yaml`:
   ```yaml
   dev_dependencies:
     patrol: ^4.7.0
   ```

2. Install Patrol CLI:
   ```bash
   dart pub global activate patrol_cli
   ```

3. Set up Patrol test directories with the skill:
   ```bash
   npx @flutter-test-interaction/skill init --patrol
   ```

### Generating Patrol Tests

When generating test code, use the `patrol` framework:

```dart
final generator = TestCodeGenerator();
final files = generator.generate(session, framework: TestFramework.patrol);
// or for multiple sessions:
final allFiles = generator.generateMulti(sessions, framework: TestFramework.patrol);
```

### Patrol Test Code Patterns

Patrol uses `patrolTest` instead of `testWidgets` and `$(...)` finders instead of `find.byKey`:

```dart
import 'package:patrol/patrol.dart';
import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';

void main() {
  patrolTest('login flow', ($) async {
    // Find widgets by test ID using $(testKey('id'))
    await $(testKey('username_field')).enterText('admin');
    await $.pumpAndSettle();

    await $(testKey('password_field')).enterText('admin123');
    await $.pumpAndSettle();

    await $(testKey('login_button')).tap();
    await $.pumpAndSettle();

    // Assert navigation
    expect($(testKey('logout_button')), findsOneWidget);
  });
}
```

### Patrol Advantages Over Standard integration_test

- **Native interactions**: `await $.native.grantPermissionWhenInUse()`, `await $.native.pressBack()`
- **Better finders**: `$(testKey('id')).scrollTo()`, `$(testKey('id')).exists`, `$(testKey('id')).visible`
- **Auto-wait**: Patrol automatically waits for widgets to appear before interacting
- **Native UI control**: tap native dialogs, interact with notifications, handle deep links

### Patrol Shared Flows

Patrol shared flows use `PatrolIntegrationTester $` instead of `WidgetTester`:

```dart
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
}
```

### Running Patrol Tests

```bash
# Run all Patrol tests
patrol test --target integration_test/

# Run on specific device
patrol test --target integration_test/ --device "iPhone 15"

# Run specific test file
patrol test --target integration_test/login_test.dart
```

### Choosing Between Flutter and Patrol

| Feature | integration_test | Patrol |
|---------|-----------------|--------|
| Basic taps & text entry | Yes | Yes |
| Native permission dialogs | No | Yes |
| Native back button | No | Yes (`$.native.pressBack()`) |
| Auto-wait for widgets | No | Yes |
| Scroll-to-visible | Manual | `$(...).scrollTo()` |
| Notifications | No | Yes |
| Deep links | No | Yes |
| Setup complexity | Low | Medium |

Use standard `integration_test` for simple widget tests. Use Patrol when you need native interactions or more robust E2E tests.
