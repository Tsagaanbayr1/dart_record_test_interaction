import 'package:flutter/material.dart';

import 'interaction_recorder.dart';

/// A draggable floating button that controls recording.
///
/// The button sits on top of the app (default: top-right corner)
/// and can be dragged anywhere. It shows the current recorder
/// state via color and icon:
/// - Gray circle with dot: idle
/// - Red circle (pulsing): recording
/// - Orange circle with pause: paused
class RecorderButton extends StatefulWidget {
  /// Callback when the user requests to save the recording.
  final VoidCallback? onSave;

  /// Callback when the user requests to discard the recording.
  final VoidCallback? onDiscard;

  /// Initial position of the button. Defaults to top-right.
  final Offset? initialPosition;

  const RecorderButton({
    super.key,
    this.onSave,
    this.onDiscard,
    this.initialPosition,
  });

  @override
  State<RecorderButton> createState() => _RecorderButtonState();
}

class _RecorderButtonState extends State<RecorderButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  Offset _position = const Offset(9999, 60);
  bool _positioned = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (widget.initialPosition != null) {
      _position = widget.initialPosition!;
      _positioned = true;
    }
    InteractionRecorder.instance.stateStream.listen(_onStateChanged);
    _updatePulse();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onStateChanged(RecorderState state) {
    _updatePulse();
    if (mounted) setState(() {});
  }

  void _updatePulse() {
    if (InteractionRecorder.instance.state == RecorderState.recording) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
    }
  }

  void _ensurePosition(Size screenSize) {
    if (!_positioned) {
      _position = Offset(screenSize.width - 70, 60);
      _positioned = true;
    }
    // Keep button on screen
    _position = Offset(
      _position.dx.clamp(8, screenSize.width - 56),
      _position.dy.clamp(8, screenSize.height - 56),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    _ensurePosition(screenSize);

    final state = InteractionRecorder.instance.state;
    final isRecording = state == RecorderState.recording;
    final isPaused = state == RecorderState.paused;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position += details.delta;
            _ensurePosition(screenSize);
          });
        },
        onLongPress: _showMenu,
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = isRecording ? 1.0 + _pulseController.value * 0.15 : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _buttonColor(isRecording, isPaused),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _onTap,
                child: Icon(
                  _buttonIcon(isRecording, isPaused),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _buttonColor(bool isRecording, bool isPaused) {
    if (isRecording) return Colors.red;
    if (isPaused) return Colors.orange;
    return Colors.blueGrey;
  }

  IconData _buttonIcon(bool isRecording, bool isPaused) {
    if (isRecording) return Icons.stop;
    if (isPaused) return Icons.play_arrow;
    return Icons.fiber_manual_record;
  }

  void _onTap() {
    final state = InteractionRecorder.instance.state;
    switch (state) {
      case RecorderState.idle:
        InteractionRecorder.instance.startRecording();
        break;
      case RecorderState.recording:
        InteractionRecorder.instance.pauseRecording();
        break;
      case RecorderState.paused:
        InteractionRecorder.instance.resumeRecording();
        break;
    }
  }

  void _showMenu() {
    final state = InteractionRecorder.instance.state;
    if (state == RecorderState.idle) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Save Recording'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onSave?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Discard Recording'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onDiscard?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }
}
