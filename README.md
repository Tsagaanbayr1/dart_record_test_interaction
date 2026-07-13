# Flutter Test Interaction

Record real user interactions in your Flutter app, then generate clean, reusable integration tests — with AI doing the heavy lifting.

Two packages that work together:

| Package | Type | What it does |
|---------|------|-------------|
| `flutter_interaction_recorder` | Dart / pub.dev | Overlays a record button on your app, captures every tap, text input, scroll, and navigation using test IDs |
| `@flutter-test-interaction/skill` | NPM / npx | AI skill that reviews your app for test ID coverage and generates componentized integration tests from recordings |

Supports both standard `integration_test` and [Patrol](https://pub.dev/packages/patrol) (v4.7.0) for native interactions.

```
 Your Flutter app                   AI agent
 ────────────────                  ──────────────
 RecorderOverlay                   reads SKILL.md
       │                               │
  user taps around                    reviews app
  enters text                         adds test IDs
  navigates                           reads recording JSON
       │                               │
  recording.json ──────────────→  generates integration tests
                                  extracts reusable flows
                                  sets up multi-account tests
```

---

## Quick Start (5 steps)

### 1. Add the Dart package

```yaml
# pubspec.yaml
dependencies:
  flutter_interaction_recorder: ^0.1.0
```

For Patrol support, also add:

```yaml
dev_dependencies:
  patrol: ^4.7.0
```

### 2. Wrap your app

```dart
// main.dart
import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';

void main() {
  runApp(const RecorderOverlay(child: MyApp()));
}
```

### 3. Add the navigator observer

```dart
MaterialApp(
  navigatorObservers: [RecorderOverlay.navigatorObserver],
  home: MyHomePage(),
)
```

### 4. Tag your interactive widgets

```dart
// Buttons, tiles, icons — anything tappable
TestId(
  id: 'login_button',
  child: ElevatedButton(onPressed: _login, child: const Text('Login')),
)

// Text fields — use TestIdTextField instead of TextField
TestIdTextField(
  id: 'username_field',
  decoration: const InputDecoration(labelText: 'Username'),
)
```

Or use the shorthand extension:

```dart
ElevatedButton(onPressed: _login, child: const Text('Login')).withTestId('login_button')
```

### 5. Install the AI skill and generate tests

```bash
npx @flutter-test-interaction/skill install
npx @flutter-test-interaction/skill init              # standard Flutter tests
npx @flutter-test-interaction/skill init --patrol     # Patrol tests (native interactions)
```

Then tell your AI agent: *"Read .skills/SKILL.md and review my Flutter app for test ID coverage."*

---

## Recording Interactions

Run your app in debug mode:

```bash
flutter run
```

You'll see a floating record button in the top-right corner. Drag it anywhere you like.

- **Tap it** to start recording (it turns red and pulses)
- **Tap again** to pause (orange)
- **Tap to resume**
- **Long-press** to save or discard

While recording, a small badge in the top-left shows the current page and event count. Every tap, text entry, scroll, and navigation is captured with its test ID and timestamp.

Recordings are saved as JSON files in the app's documents directory under `recordings/`.

---

## What Gets a Test ID

Wrap all of these with `TestId` (or replace `TextField` with `TestIdTextField`):

| Widget | Example test ID |
|--------|----------------|
| `ElevatedButton`, `TextButton`, `OutlinedButton` | `login_button` |
| `IconButton` | `profile_button` |
| `FloatingActionButton` | `add_button` |
| `TextField` → `TestIdTextField` | `username_field` |
| `ListTile` (with `onTap`) | `item_3_delete` |
| `Checkbox`, `Switch`, `Radio` | `notifications_switch` |
| `TabBar` tabs | `settings_tab` |
| `BottomNavigationBar` items | `home_nav` |
| `AppBar` actions | `search_action` |
| `Drawer` items | `profile_drawer_item` |
| Dialog buttons | `confirm_delete_button` |

**Naming rule:** use `snake_case` that describes the widget's purpose, not its type or position. `login_button` is good, `button_1` is not.

---

## Generating Integration Tests

### From code

```dart
final storage = RecordingStorage();
final sessions = await storage.listAll();
final generator = TestCodeGenerator();

// Standard Flutter integration tests
final files = generator.generate(sessions.first);
final allFiles = generator.generateMulti(sessions);

// Patrol tests (native interactions, auto-wait, $.native)
final patrolFiles = generator.generate(sessions.first, framework: TestFramework.patrol);
final allPatrolFiles = generator.generateMulti(sessions, framework: TestFramework.patrol);
```

### From the AI skill

The AI reads your recording JSON and the `SKILL.md`, then generates:

```
integration_test/
├── shared/
│   ├── shared_flows.dart      # login(), register(), logout() — reused everywhere
│   ├── test_accounts.dart     # admin, user, guest accounts
│   └── test_helpers.dart      # launchApp(), tapTestId(), enterTestIdText()
├── login_test.dart            # runs login flow
├── registration_test.dart     # runs registration flow
└── navigation_test.dart       # browse → profile → logout
```

---

## Patrol vs Standard integration_test

| Feature | integration_test | Patrol |
|---------|-----------------|--------|
| Basic taps & text entry | Yes | Yes |
| Native permission dialogs | No | Yes |
| Native back button | No | `$.native.pressBack()` |
| Auto-wait for widgets | No | Yes |
| Scroll-to-visible | Manual | `$(...).scrollTo()` |
| Notifications & deep links | No | Yes |
| Setup complexity | Low | Medium |

**Patrol test code** uses `patrolTest` and `$(...)` finders:

```dart
patrolTest('login flow', ($) async {
  await $(testKey('username_field')).enterText('admin');
  await $.pumpAndSettle();
  await $(testKey('password_field')).enterText('admin123');
  await $.pumpAndSettle();
  await $(testKey('login_button')).tap();
  await $.pumpAndSettle();
});
```

**Standard test code** uses `testWidgets` and `find.byKey`:

```dart
testWidgets('login flow', (tester) async {
  await tester.enterText(find.byKey(testKey('username_field')), 'admin');
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(testKey('password_field')), 'admin123');
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(testKey('login_button')));
  await tester.pumpAndSettle();
});
```

The `testKey('id')` helper works in both — it returns `ValueKey('__test_id__id')`.

---

## Reusable Flows (Componentization)

A login flow recorded once becomes a shared function that every test reuses:

```dart
// shared/shared_flows.dart (Patrol version)
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

Any test that needs authentication just calls `SharedFlows.login(...)` — no duplication.

---

## Multi-Account Testing

Define accounts with different roles:

```dart
// shared/test_accounts.dart
const testAccounts = [
  TestAccount(name: 'admin', role: 'admin',
    credentials: {'username': 'admin', 'password': 'admin123'}),
  TestAccount(name: 'user', role: 'user',
    credentials: {'username': 'user1', 'password': 'user123'}),
  TestAccount(name: 'guest', role: 'guest',
    credentials: {'username': 'guest', 'password': 'guest123'}),
];
```

Run the same flow for each:

```dart
for (final account in testAccounts) {
  patrolTest('login as ${account.role}', ($) async {
    await launchApp($);
    await SharedFlows.login($,
      username: account.username,
      password: account.password,
    );
    expect($(testKey('logout_button')), findsOneWidget);
  });
}
```

---

## API Overview

### Widgets

| Widget | Purpose |
|--------|---------|
| `RecorderOverlay` | Wraps the app — adds record button, pointer tracking, status badge |
| `TestId` | Wraps any widget with a test ID for tracking and test finding |
| `TestIdTextField` | Drop-in `TextField` replacement that records entered text |
| `RecorderButton` | The draggable floating button (used internally by the overlay) |

### Core classes

| Class | Purpose |
|-------|---------|
| `InteractionRecorder` | Singleton that manages recording state and collects events |
| `TestIdRegistry` | Tracks all test-ID'd widgets and their screen positions |
| `NavigationTracker` | `NavigatorObserver` that records page changes |
| `RecordingStorage` | Saves/loads recordings and accounts as JSON |
| `TestCodeGenerator` | Converts recordings to integration test code (Flutter or Patrol) |
| `TestFramework` | Enum: `TestFramework.flutter` or `TestFramework.patrol` |
| `testKey(String id)` | Returns `ValueKey('__test_id__id')` — works in both Flutter and Patrol tests |
| `RecordingSession` | A complete recording (events, pages, metadata) |
| `TestAccount` | An account profile with credentials and role |

---

## AI Skill Commands

```bash
# Install the skill into your project
npx @flutter-test-interaction/skill install

# Create the integration_test/ directory (standard Flutter)
npx @flutter-test-interaction/skill init

# Create the integration_test/ directory (Patrol)
npx @flutter-test-interaction/skill init --patrol

# Print the test ID review checklist
npx @flutter-test-interaction/skill review

# List available code templates
npx @flutter-test-interaction/skill templates
```

Works with any AI agent that can read files — Claude, GPT, Codex, Copilot, Cursor, and others.

---

## Example App

A complete demo with Patrol integration tests is in [packages/flutter_interaction_recorder/example/](packages/flutter_interaction_recorder/example/). It has a login page, home page with a scrollable list, and a profile page — all with test IDs.

```bash
cd packages/flutter_interaction_recorder/example
flutter run                                    # run the app with record button
patrol test --target integration_test/          # run the Patrol tests
```

---

## Package Details

- [flutter_interaction_recorder README](packages/flutter_interaction_recorder/README.md) — full Dart API docs
- [flutter-test-skill README](packages/flutter-test-skill/README.md) — CLI and skill details

## License

MIT
