# flutter_interaction_recorder

A Flutter package that records user interactions with test IDs and generates integration test code. Overlay a record button on any app, capture every tap, text input, scroll, and navigation event, then export reusable, componentized test flows.

Supports both standard `integration_test` and [Patrol](https://pub.dev/packages/patrol) (v4.7.0) for native interactions.

## Features

- **Record button overlay** — draggable floating button (default: top-right) that starts/stops recording
- **Test ID tracking** — wrap any widget with `TestId` to make it trackable
- **Text input recording** — `TestIdTextField` captures entered text values
- **Page/route tracking** — `NavigatorObserver` records which page each interaction occurs on
- **Scroll/drag capture** — pointer-level tracking detects scroll gestures
- **JSON persistence** — recordings saved to disk as portable JSON files
- **Test code generation** — converts recordings to Dart integration test code
- **Dual framework support** — generates both standard Flutter and Patrol test code
- **Flow componentization** — login, registration, and other flows are extracted as reusable functions
- **Multi-account support** — parameterize flows with different credentials and roles
- **Debug-only by default** — zero overhead in release builds

## Installation

```yaml
dependencies:
  flutter_interaction_recorder: ^0.1.0
```

For Patrol tests, also add:

```yaml
dev_dependencies:
  patrol: ^4.7.0
```

## Quick Start

### 1. Wrap your app

```dart
import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';

void main() {
  runApp(const RecorderOverlay(child: MyApp()));
}
```

### 2. Add the navigator observer

```dart
MaterialApp(
  navigatorObservers: [RecorderOverlay.navigatorObserver],
  // ...
)
```

### 3. Add test IDs to interactive widgets

```dart
TestId(
  id: 'login_button',
  child: ElevatedButton(onPressed: _login, child: Text('Login')),
)
```

Or use the extension:

```dart
ElevatedButton(onPressed: _login, child: Text('Login')).withTestId('login_button')
```

### 4. Use TestIdTextField for text inputs

```dart
TestIdTextField(
  id: 'username_field',
  decoration: InputDecoration(labelText: 'Username'),
)
```

### 5. Record

Run the app in debug mode (`flutter run`). Tap the floating record button, interact with your app, then long-press the button and choose "Save Recording".

### 6. Generate integration tests

```dart
final storage = RecordingStorage();
final sessions = await storage.listAll();
final generator = TestCodeGenerator();

// Standard Flutter integration tests
final files = generator.generate(sessions.first);

// Patrol tests
final patrolFiles = generator.generate(sessions.first, framework: TestFramework.patrol);

// Multiple sessions (enables shared flows)
final allFiles = generator.generateMulti(sessions);
final allPatrolFiles = generator.generateMulti(sessions, framework: TestFramework.patrol);
```

## Test ID Naming Convention

Use descriptive `snake_case` IDs:

| Good | Bad |
|------|-----|
| `login_button` | `button_1` |
| `username_field` | `textfield_0` |
| `item_3_delete` | `listtile_7` |

## Patrol Integration

Patrol provides native automation capabilities that `integration_test` can't handle — permission dialogs, notifications, deep links, native back button.

### Generated Patrol test code

```dart
import 'package:patrol/patrol.dart';
import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';

void main() {
  patrolTest('login flow', ($) async {
    await $(testKey('username_field')).enterText('admin');
    await $.pumpAndSettle();

    await $(testKey('password_field')).enterText('admin123');
    await $.pumpAndSettle();

    await $(testKey('login_button')).tap();
    await $.pumpAndSettle();

    // Native back button
    await $.native.pressBack();
  });
}
```

### `testKey()` helper

The `testKey(String id)` function returns `ValueKey('__test_id__id')`. It works in both standard and Patrol tests:

```dart
// Standard Flutter
find.byKey(testKey('login_button'))

// Patrol
$(testKey('login_button')).tap()
```

### Running Patrol tests

```bash
dart pub global activate patrol_cli
patrol test --target integration_test/
```

## Generated Test Structure

```
integration_test/
├── shared/
│   ├── shared_flows.dart     # Reusable flow functions
│   ├── test_accounts.dart    # Account definitions with roles
│   └── test_helpers.dart     # Common utilities
├── login_test.dart           # Login flow tests
├── navigation_test.dart      # Navigation flow tests
└── feature_test.dart         # Feature-specific tests
```

## Multi-Account Testing

```dart
final accounts = [
  TestAccount(name: 'admin', role: 'admin', credentials: {'username': 'admin', 'password': 'admin123'}),
  TestAccount(name: 'user', role: 'user', credentials: {'username': 'user1', 'password': 'user123'}),
];

for (final account in accounts) {
  patrolTest('login as ${account.role}', ($) async {
    await SharedFlows.login($,
      username: account.credentials['username']!,
      password: account.credentials['password']!,
    );
  });
}
```

## How It Works

1. `RecorderOverlay` wraps the app with a `Listener` (for pointer events) and a `Stack` (for the record button)
2. `TestId` creates a lightweight `RenderProxyBox` that registers its position with `TestIdRegistry`
3. When a tap occurs, the registry finds the smallest test-ID'd widget containing the tap position
4. `TestIdTextField` wraps `TextField` with a `TextEditingController` and `FocusNode` that report to the recorder
5. `NavigationTracker` (a `NavigatorObserver`) reports route changes
6. All events are collected into a `RecordingSession` and serialized to JSON
7. `TestCodeGenerator` converts sessions to integration test code (Flutter or Patrol) with flow extraction

## License

MIT
