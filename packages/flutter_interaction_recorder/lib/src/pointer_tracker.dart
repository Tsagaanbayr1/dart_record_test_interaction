import 'package:flutter/material.dart';

import 'interaction_recorder.dart';
import 'test_id.dart';

/// Captures pointer events at the app level and reports taps and
/// scrolls to [InteractionRecorder].
///
/// [PointerTracker] wraps the app in a [Listener] and uses
/// [TestIdRegistry] to resolve which test ID'd widget was
/// interacted with. It distinguishes between taps (down + up
/// without significant movement) and scrolls (down + move + up
/// with significant movement).
class PointerTracker extends StatefulWidget {
  final Widget child;

  const PointerTracker({super.key, required this.child});

  @override
  State<PointerTracker> createState() => _PointerTrackerState();
}

class _PointerTrackerState extends State<PointerTracker> {
  Offset? _downPosition;
  bool _isDragging = false;
  static const _scrollThreshold = 18.0; // px

  void _onPointerDown(PointerDownEvent event) {
    _downPosition = event.position;
    _isDragging = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_downPosition == null) return;
    final distance = (event.position - _downPosition!).distance;
    if (distance > _scrollThreshold && !_isDragging) {
      _isDragging = true;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_downPosition == null) return;

    if (_isDragging) {
      // Scroll / drag
      final testId = TestIdRegistry.instance.findTestIdAt(_downPosition!);
      InteractionRecorder.instance.onScroll(
        _downPosition!,
        event.position,
        testId,
      );
    } else {
      // Tap
      final testId = TestIdRegistry.instance.findTestIdAt(event.position);
      InteractionRecorder.instance.onTap(event.position, testId);
    }

    _downPosition = null;
    _isDragging = false;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _downPosition = null;
    _isDragging = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: widget.child,
    );
  }
}
