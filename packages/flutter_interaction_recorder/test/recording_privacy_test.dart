import 'dart:convert';

import 'package:flutter_interaction_recorder/flutter_interaction_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

/// What an obscured (password) field held must never be kept: not in the
/// event, not in the JSON written to the documents directory, and not in a
/// recording loaded from an older file.
void main() {
  const secret = 'hunter2-S3cret!';

  test('an obscured text input keeps no value', () {
    final e = InteractionEvent.textInput(
      timestamp: Duration.zero,
      page: '/login',
      testId: 'password_field',
      text: secret,
      obscureText: true,
    );
    expect(e.textValue, isNull);
    expect(e.obscureText, isTrue);
    expect(jsonEncode(e.toJson()), isNot(contains(secret)));
  });

  test('a plain text input still keeps its value', () {
    final e = InteractionEvent.textInput(
      timestamp: Duration.zero,
      page: '/login',
      testId: 'username_field',
      text: 'admin',
      obscureText: false,
    );
    expect(e.textValue, 'admin');
    expect(e.toJson()['textValue'], 'admin');
  });

  test('a recorded session never serialises a password', () {
    final recorder = InteractionRecorder.instance..reset();
    recorder.startRecording(startPage: '/login');
    recorder.onTextChanged('username_field', 'admin', false);
    recorder.onTextFocusLost('username_field', 'admin', false);
    recorder.onTextChanged('password_field', secret, true);
    recorder.onTextFocusLost('password_field', secret, true);
    final session = recorder.stopRecording(name: 'login');

    final json = jsonEncode(session.toJson());
    expect(json, isNot(contains(secret)));
    expect(json, contains('admin'));
    final pw = session.events.firstWhere((e) => e.testId == 'password_field');
    expect(pw.type, InteractionEventType.textInput);
    expect(pw.obscureText, isTrue);
    expect(pw.textValue, isNull);
  });

  test('loading an older recording drops a stored password', () {
    final old = {
      'id': 'abc',
      'name': 'login',
      'startTime': DateTime(2026).toIso8601String(),
      'startPage': '/login',
      'events': [
        {
          'timestampMs': 10,
          'page': '/login',
          'type': 'textInput',
          'testId': 'password_field',
          'textValue': secret,
          'obscureText': true,
        },
      ],
    };
    final session = RecordingSession.fromJson(old);
    expect(session.events.single.textValue, isNull);
    expect(jsonEncode(session.toJson()), isNot(contains(secret)));
  });

  test('generated code still types *** into an obscured field', () {
    final session = RecordingSession(
      id: 'abc',
      name: 'pw only',
      startTime: DateTime(2026),
      startPage: '/login',
      events: [
        InteractionEvent.textInput(
          timestamp: Duration.zero,
          page: '/login',
          testId: 'password_field',
          text: secret,
          obscureText: true,
        ),
      ],
    );
    final flows = TestCodeGenerator().generate(session)['flows']!;
    expect(flows, contains("enterText(find.byKey(const ValueKey('__test_id__password_field')), '***')"));
    expect(flows, isNot(contains(secret)));
  });
}
