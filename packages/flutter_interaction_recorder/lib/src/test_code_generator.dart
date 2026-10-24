import 'interaction_event.dart';
import 'recording_session.dart';
import 'test_id.dart';

/// The test framework to generate code for.
enum TestFramework {
  /// Standard Flutter integration tests using `integration_test` package.
  /// Uses `testWidgets`, `WidgetTester`, `find.byKey()`, `tester.tap()`.
  flutter,

  /// Patrol integration tests using `patrol` package.
  /// Uses `patrolTest`, `PatrolIntegrationTester`, `$(...)`, `.tap()`.
  /// Supports native interactions via `$.native`.
  patrol,
}

/// A reusable flow (a sequence of events that can be extracted
/// into a function and called from multiple tests).
class _Flow {
  final String name;
  final String signature;
  final List<InteractionEvent> events;
  final Set<String> parameterizedFields;

  _Flow(this.name, this.events, this.parameterizedFields)
      : signature = _computeSignature(events);

  static String _computeSignature(List<InteractionEvent> events) {
    return events.map((e) => '${e.type.name}:${e.testId ?? "-"}').join('|');
  }

  bool get isLoginFlow =>
      name.toLowerCase().contains('login') ||
      events.any((e) =>
          e.testId?.contains('login') == true ||
          e.testId?.contains('password') == true);

  bool get isRegistrationFlow =>
      name.toLowerCase().contains('register') ||
      name.toLowerCase().contains('signup') ||
      name.toLowerCase().contains('sign_up');
}

/// Generates Dart integration test code from [RecordingSession]s.
///
/// Supports two output modes:
/// - [TestFramework.flutter] — standard `integration_test` package
/// - [TestFramework.patrol] — Patrol framework with `$(...)` finders
///   and native automation support
///
/// In both modes, the generator:
/// - Converts recorded events into tap, enterText, drag, and navigation calls
/// - Extracts reusable flows (login, registration) into shared functions
/// - Parameterizes text inputs so different accounts can reuse the same flow
class TestCodeGenerator {
  static const keyPrefix = testIdKeyPrefix;

  /// Generates a complete test file from a single session.
  ///
  /// [framework] controls whether the output uses standard Flutter
  /// integration test APIs or Patrol's `$(...)` finder syntax.
  Map<String, String> generate(
    RecordingSession session, {
    TestFramework framework = TestFramework.flutter,
  }) {
    final flows = _extractFlows(session);
    final flowHelperName = _toPascalCase(session.name) + 'Flows';

    return {
      'main': _generateMainTest(session, flows, flowHelperName, framework),
      'flows': _generateFlowHelper(flowHelperName, flows, framework),
    };
  }

  /// Generates test files from multiple sessions, sharing common
  /// flows across them for componentization.
  Map<String, String> generateMulti(
    List<RecordingSession> sessions, {
    TestFramework framework = TestFramework.flutter,
  }) {
    final allFlows = <String, _Flow>{};
    for (final session in sessions) {
      final flows = _extractFlows(session);
      for (final flow in flows) {
        final key = flow.signature;
        if (!allFlows.containsKey(key)) {
          allFlows[key] = flow;
        }
      }
    }

    final files = <String, String>{};
    files['shared_flows.dart'] =
        _generateSharedFlows(allFlows.values.toList(), framework);

    for (final session in sessions) {
      final sessionFlows = _extractFlows(session);
      final testName = _toSnakeCase(session.name);
      files['${testName}_test.dart'] =
          _generateMultiSessionTest(session, sessionFlows, framework);
    }

    return files;
  }

  // ── Flow extraction ─────────────────────────────────────────

  List<_Flow> _extractFlows(RecordingSession session) {
    final flows = <_Flow>[];
    final events = session.events.where((e) =>
        e.type != InteractionEventType.recordingStart &&
        e.type != InteractionEventType.recordingStop).toList();

    int i = 0;
    while (i < events.length) {
      final event = events[i];
      if (event.type == InteractionEventType.textInput) {
        final flowEvents = <InteractionEvent>[];
        final paramFields = <String>{};
        final page = event.page;

        while (i < events.length) {
          final e = events[i];
          if (e.type == InteractionEventType.textInput) {
            flowEvents.add(e);
            paramFields.add(e.testId!);
            i++;
          } else if (e.type == InteractionEventType.tap && flowEvents.isNotEmpty) {
            flowEvents.add(e);
            i++;
            break;
          } else if (e.type == InteractionEventType.navigation) {
            break;
          } else {
            break;
          }
        }

        if (flowEvents.length >= 2) {
          final name = _inferFlowName(flowEvents, page);
          flows.add(_Flow(name, flowEvents, paramFields));
        }
        continue;
      }
      i++;
    }

    if (flows.isEmpty && events.isNotEmpty) {
      flows.add(_Flow('customFlow', events, {}));
    }

    return flows;
  }

  String _inferFlowName(List<InteractionEvent> events, String page) {
    final ids = events.map((e) => e.testId).whereType<String>().toSet();
    final idsStr = ids.join(' ').toLowerCase();

    if (idsStr.contains('login') || idsStr.contains('password')) return 'login';
    if (idsStr.contains('register') || idsStr.contains('signup') || idsStr.contains('sign_up'))
      return 'registration';
    if (idsStr.contains('search')) return 'search';
    return 'flow_on_${_toSnakeCase(page)}';
  }

  // ── Main test generation ────────────────────────────────────

  String _generateMainTest(
    RecordingSession session,
    List<_Flow> flows,
    String flowHelperName,
    TestFramework framework,
  ) {
    if (framework == TestFramework.patrol) {
      return _generatePatrolMainTest(session, flows, flowHelperName);
    }
    return _generateFlutterMainTest(session, flows, flowHelperName);
  }

  String _generateFlutterMainTest(
    RecordingSession session,
    List<_Flow> flows,
    String flowHelperName,
  ) {
    final buf = StringBuffer();
    buf.writeln("import 'package:flutter_test/flutter_test.dart';");
    buf.writeln("import 'package:integration_test/integration_test.dart';");
    buf.writeln();
    buf.writeln("import '$flowHelperName.dart' as flows;");
    buf.writeln();
    buf.writeln("void main() {");
    buf.writeln("  IntegrationTestWidgetsFlutterBinding.ensureInitialized();");
    buf.writeln();
    buf.writeln("  group('${_escapeString(session.name)}', () {");
    buf.writeln("    testWidgets('recorded flow', (tester) async {");
    buf.writeln("      // TODO: Replace with your app's main widget");
    buf.writeln("      // app.main();");
    buf.writeln("      // await tester.pumpAndSettle();");
    buf.writeln();
    _writeFlowCalls(buf, flows, 'flows', 'tester');
    buf.writeln("    });");
    buf.writeln("  });");
    buf.writeln("}");
    return buf.toString();
  }

  String _generatePatrolMainTest(
    RecordingSession session,
    List<_Flow> flows,
    String flowHelperName,
  ) {
    final buf = StringBuffer();
    buf.writeln("import 'package:patrol/patrol.dart';");
    buf.writeln();
    buf.writeln("import '$flowHelperName.dart' as flows;");
    buf.writeln();
    buf.writeln("void main() {");
    buf.writeln("  patrolTest('${_escapeString(session.name)}', (\$) async {");
    buf.writeln("    // TODO: Replace with your app's entry point");
    buf.writeln("    // await \$.pumpWidgetAndSettle(MyApp());");
    buf.writeln("    // or: app.main(); await \$.pumpAndSettle();");
    buf.writeln();
    _writeFlowCalls(buf, flows, 'flows', '\$');
    buf.writeln("  });");
    buf.writeln("}");
    return buf.toString();
  }

  // ── Flow helper generation ──────────────────────────────────

  String _generateFlowHelper(
    String className,
    List<_Flow> flows,
    TestFramework framework,
  ) {
    final buf = StringBuffer();

    if (framework == TestFramework.patrol) {
      buf.writeln("import 'package:patrol/patrol.dart';");
      buf.writeln("import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';");
    } else {
      buf.writeln("import 'package:flutter_test/flutter_test.dart';");
      buf.writeln("import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';");
    }

    buf.writeln();
    buf.writeln("/// Reusable test flows extracted from recordings.");
    buf.writeln("/// These can be shared across multiple test files.");
    buf.writeln("class $className {");

    for (final flow in flows) {
      final flowName = _toCamelCase(flow.name);
      buf.writeln();
      buf.writeln("  /// Flow: ${flow.name}");

      final params = <String>[];
      if (framework == TestFramework.patrol) {
        params.add('PatrolIntegrationTester \$');
      } else {
        params.add('WidgetTester tester');
      }
      for (final field in flow.parameterizedFields) {
        final paramName = _toCamelCase(field.replaceAll(RegExp(r'_field$'), ''));
        params.add("String $paramName");
      }

      buf.writeln("  static Future<void> $flowName(${params.join(', ')}) async {");
      if (framework == TestFramework.patrol) {
        _writePatrolFlowEvents(buf, flow);
      } else {
        _writeFlutterFlowEvents(buf, flow);
      }
      buf.writeln("  }");
    }

    buf.writeln("}");
    return buf.toString();
  }

  // ── Multi-session generation ────────────────────────────────

  String _generateSharedFlows(List<_Flow> allFlows, TestFramework framework) {
    final buf = StringBuffer();

    if (framework == TestFramework.patrol) {
      buf.writeln("import 'package:patrol/patrol.dart';");
      buf.writeln("import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';");
    } else {
      buf.writeln("import 'package:flutter_test/flutter_test.dart';");
      buf.writeln("import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';");
    }

    buf.writeln();
    buf.writeln("/// Shared test flows reusable across all test files.");
    buf.writeln("class SharedFlows {");

    for (final flow in allFlows) {
      final flowName = _toCamelCase(flow.name);
      buf.writeln();
      buf.writeln("  /// Shared flow: ${flow.name}");

      final params = <String>[];
      if (framework == TestFramework.patrol) {
        params.add('PatrolIntegrationTester \$');
      } else {
        params.add('WidgetTester tester');
      }
      for (final field in flow.parameterizedFields) {
        final paramName = _toCamelCase(field.replaceAll(RegExp(r'_field$'), ''));
        params.add("String $paramName");
      }

      buf.writeln("  static Future<void> $flowName(${params.join(', ')}) async {");
      if (framework == TestFramework.patrol) {
        _writePatrolFlowEvents(buf, flow);
      } else {
        _writeFlutterFlowEvents(buf, flow);
      }
      buf.writeln("  }");
    }

    buf.writeln("}");
    return buf.toString();
  }

  String _generateMultiSessionTest(
    RecordingSession session,
    List<_Flow> sessionFlows,
    TestFramework framework,
  ) {
    final isLogin = sessionFlows.any((f) => f.isLoginFlow);

    if (framework == TestFramework.patrol) {
      return _generatePatrolMultiSessionTest(session, sessionFlows, isLogin);
    }
    return _generateFlutterMultiSessionTest(session, sessionFlows, isLogin);
  }

  String _generateFlutterMultiSessionTest(
    RecordingSession session,
    List<_Flow> sessionFlows,
    bool isLogin,
  ) {
    final buf = StringBuffer();
    buf.writeln("import 'package:flutter_test/flutter_test.dart';");
    buf.writeln("import 'package:integration_test/integration_test.dart';");
    buf.writeln();
    buf.writeln("import 'shared_flows.dart';");
    buf.writeln();
    buf.writeln("void main() {");
    buf.writeln("  IntegrationTestWidgetsFlutterBinding.ensureInitialized();");
    buf.writeln();
    buf.writeln("  group('${_escapeString(session.name)}', () {");
    if (isLogin) buf.writeln("    // Run login flow with different accounts");
    buf.writeln("    testWidgets('${isLogin ? 'login flow' : 'recorded flow'}', (tester) async {");
    buf.writeln("      // TODO: Replace with your app's main widget");
    buf.writeln("      // app.main(); await tester.pumpAndSettle();");
    buf.writeln();
    _writeFlowCalls(buf, sessionFlows, 'SharedFlows', 'tester');
    buf.writeln("    });");
    buf.writeln("  });");
    buf.writeln("}");
    return buf.toString();
  }

  String _generatePatrolMultiSessionTest(
    RecordingSession session,
    List<_Flow> sessionFlows,
    bool isLogin,
  ) {
    final buf = StringBuffer();
    buf.writeln("import 'package:patrol/patrol.dart';");
    buf.writeln();
    buf.writeln("import 'shared_flows.dart';");
    buf.writeln();
    buf.writeln("void main() {");
    if (isLogin) buf.writeln("  // Run login flow with different accounts");
    buf.writeln("  patrolTest('${_escapeString(session.name)}', (\$) async {");
    buf.writeln("    // TODO: Replace with your app's entry point");
    buf.writeln("    // app.main(); await \$.pumpAndSettle();");
    buf.writeln();
    _writeFlowCalls(buf, sessionFlows, 'SharedFlows', '\$');
    buf.writeln("  });");
    buf.writeln("}");
    return buf.toString();
  }

  // ── Flow call writers ───────────────────────────────────────

  void _writeFlowCalls(StringBuffer buf, List<_Flow> flows, String className, String testerVar) {
    for (final flow in flows) {
      final flowName = _toCamelCase(flow.name);
      if (flow.parameterizedFields.isNotEmpty) {
        final args = flow.parameterizedFields.map((f) {
          final paramName = _toCamelCase(f.replaceAll(RegExp(r'_field$'), ''));
          return "/* $paramName */ ''";
        }).join(', ');
        buf.writeln("    await $className.$flowName($testerVar, $args);");
      } else {
        buf.writeln("    await $className.$flowName($testerVar);");
      }
    }
  }

  // ── Flutter event writer ────────────────────────────────────

  void _writeFlutterFlowEvents(StringBuffer buf, _Flow flow) {
    for (final event in flow.events) {
      switch (event.type) {
        case InteractionEventType.textInput:
          final key = _keyExpr(event.testId!);
          final paramName = _toCamelCase(event.testId!.replaceAll(RegExp(r'_field$'), ''));
          if (flow.parameterizedFields.contains(event.testId)) {
            buf.writeln("    await tester.enterText(find.byKey($key), $paramName);");
          } else {
            final textValue = event.obscureText ? "'***'" : "'${_escapeString(event.textValue!)}'";
            buf.writeln("    await tester.enterText(find.byKey($key), $textValue);");
          }
          buf.writeln("    await tester.pumpAndSettle();");
          break;
        case InteractionEventType.tap:
          buf.writeln("    await tester.tap(find.byKey(${_keyExpr(event.testId!)}));");
          buf.writeln("    await tester.pumpAndSettle();");
          break;
        case InteractionEventType.scroll:
          if (event.testId != null) {
            final dx = ((event.endX ?? 0) - (event.startX ?? 0)).round();
            final dy = ((event.endY ?? 0) - (event.startY ?? 0)).round();
            buf.writeln("    await tester.drag(find.byKey(${_keyExpr(event.testId!)}), const Offset($dx, $dy));");
          } else {
            buf.writeln("    // Scroll gesture");
          }
          buf.writeln("    await tester.pumpAndSettle();");
          break;
        case InteractionEventType.navigation:
          buf.writeln("    // Navigate to ${_commentText(event.destinationPage)}");
          buf.writeln("    await tester.pumpAndSettle();");
          break;
        case InteractionEventType.backNavigation:
          buf.writeln("    await tester.pageBack();");
          buf.writeln("    await tester.pumpAndSettle();");
          break;
        case InteractionEventType.recordingStart:
        case InteractionEventType.recordingStop:
          break;
      }
    }
  }

  // ── Patrol event writer ─────────────────────────────────────

  void _writePatrolFlowEvents(StringBuffer buf, _Flow flow) {
    for (final event in flow.events) {
      switch (event.type) {
        case InteractionEventType.textInput:
          final key = _keyExpr(event.testId!);
          final paramName = _toCamelCase(event.testId!.replaceAll(RegExp(r'_field$'), ''));
          if (flow.parameterizedFields.contains(event.testId)) {
            buf.writeln("    await \$($key).enterText($paramName);");
          } else {
            final textValue = event.obscureText ? "'***'" : "'${_escapeString(event.textValue!)}'";
            buf.writeln("    await \$($key).enterText($textValue);");
          }
          buf.writeln("    await \$.pumpAndSettle();");
          break;
        case InteractionEventType.tap:
          buf.writeln("    await \$(${_keyExpr(event.testId!)}).tap();");
          buf.writeln("    await \$.pumpAndSettle();");
          break;
        case InteractionEventType.scroll:
          if (event.testId != null) {
            buf.writeln("    await \$(${_keyExpr(event.testId!)}).scrollTo();");
          } else {
            final dx = ((event.endX ?? 0) - (event.startX ?? 0)).round();
            final dy = ((event.endY ?? 0) - (event.startY ?? 0)).round();
            buf.writeln("    // Drag offset: ($dx, $dy)");
          }
          buf.writeln("    await \$.pumpAndSettle();");
          break;
        case InteractionEventType.navigation:
          buf.writeln("    // Navigate to ${_commentText(event.destinationPage)}");
          buf.writeln("    await \$.pumpAndSettle();");
          break;
        case InteractionEventType.backNavigation:
          buf.writeln("    await \$.native.pressBack();");
          buf.writeln("    await \$.pumpAndSettle();");
          break;
        case InteractionEventType.recordingStart:
        case InteractionEventType.recordingStop:
          break;
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────

  String _keyExpr(String testId) =>
      "const ValueKey('${_escapeString('$keyPrefix$testId')}')";

  /// Escapes [s] for use inside a single-quoted Dart string literal.
  ///
  /// Recorded values come from a recording file, so every character that
  /// could end the literal or start an interpolation is escaped: the
  /// backslash, the quote, `$`, and control characters.
  String _escapeString(String s) {
    final buf = StringBuffer();
    for (final rune in s.runes) {
      switch (rune) {
        case 0x5C: // \
          buf.write(r'\\');
        case 0x27: // '
          buf.write(r"\'");
        case 0x24: // $
          buf.write(r'\$');
        case 0x0A:
          buf.write(r'\n');
        case 0x0D:
          buf.write(r'\r');
        case 0x09:
          buf.write(r'\t');
        default:
          if (rune < 0x20 || rune == 0x7F) {
            buf.write('\\u{${rune.toRadixString(16)}}');
          } else {
            buf.writeCharCode(rune);
          }
      }
    }
    return buf.toString();
  }

  /// Text for a `//` comment: a line break would end the comment early.
  String _commentText(String? s) =>
      (s ?? '').replaceAll(RegExp('[\r\n\u2028\u2029]+'), ' ');

  String _toPascalCase(String s) {
    final words = s.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ').split(RegExp(r'\s+'));
    return words.where((w) => w.isNotEmpty).map((w) {
      return w[0].toUpperCase() + w.substring(1).toLowerCase();
    }).join();
  }

  String _toCamelCase(String s) {
    final pascal = _toPascalCase(s);
    // No ASCII letters or digits to build a name from (e.g. a Cyrillic test
    // ID): derive a stable, valid identifier instead of using [s] as code.
    if (pascal.isEmpty) {
      return 'field${s.runes.map((r) => r.toRadixString(16)).join('_')}';
    }
    return pascal[0].toLowerCase() + pascal.substring(1);
  }

  String _toSnakeCase(String s) {
    final words = s.replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), ' ').split(RegExp(r'\s+'));
    return words.where((w) => w.isNotEmpty).map((w) => w.toLowerCase()).join('_');
  }
}
