import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import 'interaction_event.dart';
import 'recording_session.dart';

/// The state of the recorder.
enum RecorderState { idle, recording, paused }

/// The core singleton that manages interaction recording.
///
/// The [InteractionRecorder] is the central hub that:
/// - Tracks recorder state (idle / recording / paused)
/// - Receives events from [PointerTracker], [NavigationTracker],
///   and [TestIdTextField]
/// - Builds [InteractionEvent]s with timestamps and page info
/// - Notifies listeners of state changes and new events
///
/// Typically you do not call methods on this directly; the
/// [RecorderOverlay] widget handles start / stop / pause for you.
class InteractionRecorder {
  static final InteractionRecorder instance = InteractionRecorder._();

  InteractionRecorder._();

  // ── State ──────────────────────────────────────────────────

  RecorderState _state = RecorderState.idle;
  RecorderState get state => _state;

  /// The page the user was on when recording started.
  String _startPage = 'unknown';
  String get startPage => _startPage;

  /// The current page (updated by [NavigationTracker]).
  String _currentPage = 'unknown';
  String get currentPage => _currentPage;

  DateTime? _recordingStart;
  List<InteractionEvent> _events = [];

  /// Events recorded in the current (or most recent) session.
  List<InteractionEvent> get events => List.unmodifiable(_events);

  // ── Streams / listeners ────────────────────────────────────

  final _stateController = StreamController<RecorderState>.broadcast();
  Stream<RecorderState> get stateStream => _stateController.stream;

  final _eventController = StreamController<InteractionEvent>.broadcast();
  Stream<InteractionEvent> get eventStream => _eventController.stream;

  // ── Text input tracking ────────────────────────────────────

  /// Tracks the latest text value for each text field test ID.
  final Map<String, String> _textValues = {};

  /// Tracks whether each text field is obscured.
  final Map<String, bool> _obscureFields = {};

  // ── Recording control ──────────────────────────────────────

  /// Starts a new recording session.
  ///
  /// [startPage] should be the current route name (provided by
  /// [NavigationTracker] or [RecorderOverlay]).
  void startRecording({String? startPage}) {
    if (_state == RecorderState.recording) return;

    _startPage = startPage ?? _currentPage;
    _recordingStart = DateTime.now();
    _events = [];
    _textValues.clear();
    _obscureFields.clear();

    _state = RecorderState.recording;
    _stateController.add(_state);

    _addEvent(InteractionEvent(
      timestamp: Duration.zero,
      page: _startPage,
      type: InteractionEventType.recordingStart,
    ));
  }

  /// Pauses recording. Events are not recorded while paused.
  void pauseRecording() {
    if (_state != RecorderState.recording) return;
    _state = RecorderState.paused;
    _stateController.add(_state);
  }

  /// Resumes recording after a pause.
  void resumeRecording() {
    if (_state != RecorderState.paused) return;
    _state = RecorderState.recording;
    _stateController.add(_state);
  }

  /// Stops recording and returns the completed [RecordingSession].
  ///
  /// The session is NOT automatically persisted. Use
  /// [RecordingStorage.save] to write it to disk.
  RecordingSession stopRecording({String? name}) {
    _addEvent(InteractionEvent(
      timestamp: _elapsed,
      page: _currentPage,
      type: InteractionEventType.recordingStop,
    ));

    final session = RecordingSession(
      id: _generateId(),
      name: name ?? 'Recording ${_recordingStart!.toIso8601String()}',
      startTime: _recordingStart!,
      startPage: _startPage,
      events: List.from(_events),
    );

    _state = RecorderState.idle;
    _stateController.add(_state);

    return session;
  }

  // ── Event recording (called by trackers) ───────────────────

  /// Called by [PointerTracker] when a tap is detected.
  void onTap(Offset position, String? testId) {
    if (_state != RecorderState.recording) return;
    _addEvent(InteractionEvent.tap(
      timestamp: _elapsed,
      page: _currentPage,
      testId: testId ?? 'unknown',
      position: position,
    ));
  }

  /// Called by [PointerTracker] when a scroll / drag is detected.
  void onScroll(Offset start, Offset end, String? testId) {
    if (_state != RecorderState.recording) return;
    _addEvent(InteractionEvent.scroll(
      timestamp: _elapsed,
      page: _currentPage,
      testId: testId,
      start: start,
      end: end,
    ));
  }

  /// Called by [TestIdTextField] when text changes.
  void onTextChanged(String testId, String text, bool obscureText) {
    // An obscured field's value is never held, even in memory.
    _textValues[testId] = obscureText ? '' : text;
    _obscureFields[testId] = obscureText;
    if (_state != RecorderState.recording) return;
    // We do NOT record every keystroke. The final value is recorded
    // on focus loss via [onTextFocusLost].
  }

  /// Called by [TestIdTextField] when the field loses focus.
  void onTextFocusLost(String testId, String text, bool obscureText) {
    if (_state != RecorderState.recording) return;
    if (text.isEmpty) return;
    _addEvent(InteractionEvent.textInput(
      timestamp: _elapsed,
      page: _currentPage,
      testId: testId,
      text: text,
      obscureText: obscureText,
    ));
  }

  /// Called by [NavigationTracker] when the route changes.
  void onPageChanged(String pageName) {
    _currentPage = pageName;
    if (_state != RecorderState.recording) return;
    _addEvent(InteractionEvent.navigation(
      timestamp: _elapsed,
      page: _currentPage,
      destinationPage: pageName,
    ));
  }

  /// Called by [NavigationTracker] when the user navigates back.
  void onBackNavigation() {
    if (_state != RecorderState.recording) return;
    _addEvent(InteractionEvent.backNavigation(
      timestamp: _elapsed,
      page: _currentPage,
    ));
  }

  // ── Internal helpers ───────────────────────────────────────

  Duration get _elapsed =>
      DateTime.now().difference(_recordingStart ?? DateTime.now());

  void _addEvent(InteractionEvent event) {
    _events.add(event);
    _eventController.add(event);
  }

  String _generateId() {
    final rng = Random();
    final chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(12, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Resets the recorder to its initial state (used on hot restart).
  void reset() {
    _state = RecorderState.idle;
    _events = [];
    _textValues.clear();
    _obscureFields.clear();
    _currentPage = 'unknown';
    _startPage = 'unknown';
    _recordingStart = null;
  }

  void dispose() {
    _stateController.close();
    _eventController.close();
  }
}
