import 'package:flutter/material.dart';

import 'interaction_recorder.dart';
import 'navigation_tracker.dart';
import 'pointer_tracker.dart';
import 'recorder_button.dart';
import 'recording_session.dart';
import 'recording_storage.dart';

/// A shared [NavigationTracker] instance that the user adds to
/// their [Navigator].
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [RecorderOverlay.navigatorObserver],
///   ...
/// )
/// ```
late final NavigationTracker _navigatorObserver = NavigationTracker();

/// Wraps the entire app with recording infrastructure.
///
/// Place [RecorderOverlay] as the top-level wrapper (above
/// [MaterialApp] / [CupertinoApp]):
///
/// ```dart
/// void main() {
///   runApp(RecorderOverlay(
///     child: MyApp(),
///   ));
/// }
/// ```
///
/// And add the navigator observer to your app:
/// ```dart
/// MaterialApp(
///   navigatorObservers: [RecorderOverlay.navigatorObserver],
///   ...
/// )
/// ```
///
/// This automatically:
/// - Wraps the app in a [Listener] to capture taps and scrolls
/// - Shows a draggable record button (top-right by default)
/// - Shows a live status badge (current page + event count)
/// - Handles saving / discarding recordings to disk
///
/// In release mode, the overlay is automatically disabled and the
/// app runs without any recording overhead.
class RecorderOverlay extends StatefulWidget {
  final Widget child;

  /// Whether the overlay is enabled. Defaults to `true` in debug
  /// mode, `false` in release mode.
  final bool? enabled;

  /// Initial position of the record button.
  final Offset? buttonPosition;

  /// Called after a recording is saved to disk.
  final void Function(RecordingSession session)? onRecordingSaved;

  const RecorderOverlay({
    super.key,
    required this.child,
    this.enabled,
    this.buttonPosition,
    this.onRecordingSaved,
  });

  /// The [NavigatorObserver] to add to your [MaterialApp] /
  /// [CupertinoApp] for page tracking.
  static NavigationObserver get navigatorObserver => _navigatorObserver;

  @override
  State<RecorderOverlay> createState() => _RecorderOverlayState();
}

class _RecorderOverlayState extends State<RecorderOverlay> {
  late bool _enabled;
  final _storage = RecordingStorage();

  @override
  void initState() {
    super.initState();
    _enabled = widget.enabled ?? _isDebugMode();
  }

  bool _isDebugMode() {
    bool inDebugMode = false;
    assert(() {
      inDebugMode = true;
      return true;
    }());
    return inDebugMode;
  }

  @override
  Widget build(BuildContext context) {
    if (!_enabled) return widget.child;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: PointerTracker(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            widget.child,
            _RecordButtonArea(
              position: widget.buttonPosition,
              onSave: () => _saveRecording(),
              onDiscard: _discardRecording,
            ),
            const _RecordingStatusBadge(),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRecording() async {
    final session = InteractionRecorder.instance.stopRecording();
    await _storage.save(session);
    widget.onRecordingSaved?.call(session);
  }

  void _discardRecording() {
    InteractionRecorder.instance.stopRecording();
  }
}

/// The record button area — ignores pointer except on the button
/// itself so it doesn't block the app.
class _RecordButtonArea extends StatelessWidget {
  final Offset? position;
  final Future<void> Function() onSave;
  final VoidCallback onDiscard;

  const _RecordButtonArea({
    this.position,
    required this.onSave,
    required this.onDiscard,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          children: [
            RecorderButton(
              initialPosition: position,
              onSave: () => onSave(),
              onDiscard: onDiscard,
            ),
          ],
        ),
      ),
    );
  }
}

/// A small badge that shows the current page and event count
/// while recording.
class _RecordingStatusBadge extends StatefulWidget {
  const _RecordingStatusBadge();

  @override
  State<_RecordingStatusBadge> createState() => _RecordingStatusBadgeState();
}

class _RecordingStatusBadgeState extends State<_RecordingStatusBadge> {
  int _eventCount = 0;
  String _currentPage = '';
  RecorderState _state = RecorderState.idle;

  @override
  void initState() {
    super.initState();
    InteractionRecorder.instance.stateStream.listen((state) {
      if (mounted) setState(() => _state = state);
    });
    InteractionRecorder.instance.eventStream.listen((event) {
      if (mounted) {
        setState(() {
          _eventCount++;
          _currentPage = event.page;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_state == RecorderState.idle) return const SizedBox.shrink();

    return Positioned(
      left: 8,
      top: 8,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_state == RecorderState.recording) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                '$_currentPage  |  $_eventCount events',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Type alias so [RecorderOverlay.navigatorObserver] can be used
/// without importing [NavigationTracker] directly.
typedef NavigationObserver = NavigationTracker;
