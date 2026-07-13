# Flutter Test Interaction Skill

An AI skill for reviewing Flutter apps and generating integration tests from recorded interactions. Installable via npx, compatible with any AI agent (Claude, GPT, Codex, Copilot, Cursor, etc.).

Supports both standard `integration_test` and [Patrol](https://pub.dev/packages/patrol) for native interactions.

## Installation

```bash
npx @flutter-test-interaction/skill install
```

This installs:
- `.skills/SKILL.md` — the skill instructions for your AI agent
- `.skills/templates/` — code templates (standard + Patrol)
- Updates `AGENTS.md` with a reference to the skill

## Usage

### Install the skill

```bash
npx @flutter-test-interaction/skill install
```

### Set up test directories

```bash
# Standard Flutter integration tests
npx @flutter-test-interaction/skill init

# Patrol tests (native interactions, auto-wait, $.native)
npx @flutter-test-interaction/skill init --patrol
```

### Print the review checklist

```bash
npx @flutter-test-interaction/skill review
```

### List available templates

```bash
npx @flutter-test-interaction/skill templates
```

### Ask your AI to use the skill

After installation, tell your AI agent:

> "Read .skills/SKILL.md and review my Flutter app for test ID coverage"

The AI will:
1. Check that `RecorderOverlay` wraps the app
2. Verify `navigatorObservers` includes the tracker
3. Find all interactive widgets missing test IDs
4. Add `TestId` wrappers or `TestIdTextField` replacements
5. Generate integration tests from recordings (Flutter or Patrol)
6. Extract reusable flows (login, registration) into shared components
7. Set up multi-account test scenarios

## What the Skill Does

### Test ID Review

The AI scans your Flutter app and ensures every interactive element has a test ID:
- Buttons, text fields, checkboxes, switches
- List tiles, tabs, navigation items
- App bar actions, drawer items, dialog buttons

### Integration Test Generation

From recorded interactions, the AI generates:
- `shared/shared_flows.dart` — reusable flow functions (login, registration, navigation)
- `shared/test_accounts.dart` — account definitions with roles
- Individual test files per recording

For Patrol, it uses `patrolTest`, `$(testKey('id'))` finders, and `$.native` for platform interactions.

### Componentization & Reuse

- Login flows recorded once are reused across all tests that need authentication
- Registration flows are extracted and parameterized
- Navigation patterns are shared
- Cross-referencing is enforced — no duplicated flows

### Multi-Account Testing

```dart
for (final account in testAccounts) {
  patrolTest('login as ${account.role}', ($) async {
    await SharedFlows.login($,
      username: account.username,
      password: account.password,
    );
  });
}
```

## Commands

| Command | Description |
|---------|-------------|
| `install [path]` | Install SKILL.md and templates into a project |
| `init [path] [--patrol]` | Create integration test directory (standard or Patrol) |
| `review` | Print the test ID review checklist |
| `templates` | List available code templates |
| `help` | Show help |

## Templates

### Standard Flutter

- `shared_flows_template.dart` — login, register, logout, navigation helpers
- `test_accounts_template.dart` — admin, user, guest accounts
- `test_helpers_template.dart` — launch, scroll, tap, enter text helpers

### Patrol (`patrol/` subdirectory)

- `shared_flows_template.dart` — same flows using `PatrolIntegrationTester $` and `$(testKey('id'))`
- `test_accounts_template.dart` — same accounts
- `test_helpers_template.dart` — Patrol-native helpers including `$.native` and `.scrollTo()`

## Compatibility

Works with any AI agent that can read files:
- Claude (Anthropic)
- GPT / Codex (OpenAI)
- GitHub Copilot
- Cursor
- Any agent that follows AGENTS.md / SKILL.md conventions

## License

MIT
