import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

/// Recorded strings (session names, typed text, test IDs, route names) come
/// from a recording file. They must come out of the generator as inert Dart
/// string literals or comments, never as code.
void main() {
  RecordingSession session({
    String name = 'demo',
    List<InteractionEvent> events = const [],
  }) =>
      RecordingSession(
        id: 'abc',
        name: name,
        startTime: DateTime(2026),
        startPage: '/',
        events: events,
      );

  InteractionEvent typed(String testId, String text) => InteractionEvent.textInput(
        timestamp: Duration.zero,
        page: '/',
        testId: testId,
        text: text,
        obscureText: false,
      );

  test(r'session names escape $, backslash, quote and newline', () {
    final main = TestCodeGenerator()
        .generate(session(name: "a\$b\\c'd\ne", events: [typed('q_field', 'x')]))['main']!;
    expect(main, contains(r"group('a\$b\\c\'d\ne', () {"));
  });

  test('typed text cannot interpolate or close the literal', () {
    final flows = TestCodeGenerator().generate(session(events: [
      typed('q_field', r"${exit(1)} $HOME \' end"),
    ]))['flows']!;
    expect(
      flows,
      contains(r"enterText(find.byKey(const ValueKey('__test_id__q_field')), '\${exit(1)} \$HOME \\\' end');"),
    );
  });

  test('test IDs are escaped inside ValueKey', () {
    final flows = TestCodeGenerator().generate(session(events: [
      InteractionEvent.tap(
        timestamp: Duration.zero,
        page: '/',
        testId: r"btn'); exit(1); ('$x",
        position: Offset.zero,
      ),
    ]))['flows']!;
    expect(flows, contains(r"tester.tap(find.byKey(const ValueKey('__test_id__btn\'); exit(1); (\'\$x')));"));
  });

  test('route names stay inside their comment', () {
    final flows = TestCodeGenerator().generate(session(events: [
      InteractionEvent.navigation(
        timestamp: Duration.zero,
        page: '/',
        destinationPage: '/home\nexit(1);',
      ),
    ]))['flows']!;
    expect(flows, contains('    // Navigate to /home exit(1);\n'));
    expect(flows.split('\n').where((l) => l.trim() == 'exit(1);'), isEmpty);
  });

  test('a test ID with no ASCII letters still gives a valid parameter name', () {
    final flows = TestCodeGenerator().generate(session(events: [
      typed('нэр', 'a'),
      typed('нууц_үг', 'b'),
      InteractionEvent.tap(
        timestamp: Duration.zero,
        page: '/',
        testId: 'go',
        position: Offset.zero,
      ),
    ]))['flows']!;
    final sig = RegExp(r'static Future<void> \w+\(WidgetTester tester, (.*)\) async').firstMatch(flows)!;
    for (final p in sig.group(1)!.split(', ')) {
      expect(p, matches(RegExp(r'^String [A-Za-z_][A-Za-z0-9_]*$')));
    }
  });
}
