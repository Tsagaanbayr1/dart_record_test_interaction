import 'package:flutter/material.dart';

import 'interaction_recorder.dart';
import 'test_id.dart';

/// A [TextField] that automatically records text input when the
/// [InteractionRecorder] is active.
///
/// Use this instead of [TextField] for any text input that should
/// be captured during recording. The AI skill replaces `TextField`
/// widgets with `TestIdTextField` when adding test IDs.
///
/// ```dart
/// TestIdTextField(
///   id: 'username_field',
///   decoration: InputDecoration(labelText: 'Username'),
/// )
/// ```
class TestIdTextField extends StatefulWidget {
  /// Unique test ID for this text field.
  final String id;

  /// Whether the text is obscured (password fields).
  final bool obscureText;

  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextStyle? style;
  final TextAlign textAlign;
  final TextCapitalization textCapitalization;
  final EdgeInsets scrollPadding;
  final bool expands;
  final Brightness keyboardAppearance;

  const TestIdTextField({
    super.key,
    required this.id,
    this.obscureText = false,
    this.decoration,
    this.keyboardType,
    this.textInputAction,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.style,
    this.textAlign = TextAlign.start,
    this.textCapitalization = TextCapitalization.none,
    this.scrollPadding = const EdgeInsets.all(20),
    this.expands = false,
    this.keyboardAppearance = Brightness.light,
  });

  @override
  State<TestIdTextField> createState() => _TestIdTextFieldState();
}

class _TestIdTextFieldState extends State<TestIdTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(TestIdTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_onTextChanged);
      if (_ownsController) _controller.dispose();
      if (widget.controller != null) {
        _controller = widget.controller!;
        _ownsController = false;
      } else {
        _controller = TextEditingController();
        _ownsController = true;
      }
      _controller.addListener(_onTextChanged);
    }
    if (oldWidget.focusNode != widget.focusNode) {
      _focusNode.removeListener(_onFocusChanged);
      if (_ownsFocusNode) _focusNode.dispose();
      if (widget.focusNode != null) {
        _focusNode = widget.focusNode!;
        _ownsFocusNode = false;
      } else {
        _focusNode = FocusNode();
        _ownsFocusNode = true;
      }
      _focusNode.addListener(_onFocusChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!mounted) return;
    InteractionRecorder.instance.onTextChanged(
      widget.id,
      _controller.text,
      widget.obscureText,
    );
    widget.onChanged?.call(_controller.text);
  }

  void _onFocusChanged() {
    if (!mounted) return;
    if (!_focusNode.hasFocus) {
      InteractionRecorder.instance.onTextFocusLost(
        widget.id,
        _controller.text,
        widget.obscureText,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TestId(
      id: widget.id,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        obscureText: widget.obscureText,
        decoration: widget.decoration,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        onEditingComplete: widget.onEditingComplete,
        onSubmitted: widget.onSubmitted,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        maxLines: widget.maxLines,
        minLines: widget.minLines,
        maxLength: widget.maxLength,
        style: widget.style,
        textAlign: widget.textAlign,
        textCapitalization: widget.textCapitalization,
        scrollPadding: widget.scrollPadding,
        expands: widget.expands,
        keyboardAppearance: widget.keyboardAppearance,
      ),
    );
  }
}
