import 'dart:ui' show Offset;

/// The kind of interaction that was recorded.
enum InteractionEventType {
  tap,
  textInput,
  scroll,
  navigation,
  backNavigation,
  recordingStart,
  recordingStop,
}

/// A single recorded interaction event.
///
/// Every event carries a [timestamp] (relative to recording start),
/// the [page] on which it occurred, and the [testId] of the widget
/// involved (when applicable). Events are serialized to JSON via
/// [toJson] and deserialized via [InteractionEvent.fromJson].
class InteractionEvent {
  /// Relative time since the recording session started.
  final Duration timestamp;

  /// The page / route name on which the event occurred.
  final String page;

  /// The type of interaction.
  final InteractionEventType type;

  /// Test ID of the widget that was interacted with.
  /// Null for navigation events.
  final String? testId;

  /// Text that was entered (for [InteractionEventType.textInput] only).
  ///
  /// Always null for an obscured (password) field: the value is never kept,
  /// so it cannot reach the recording file, an export, or an AI agent.
  final String? textValue;

  /// Whether the text field was an obscured (password) field.
  final bool obscureText;

  /// Start position of a drag / scroll gesture (global coordinates).
  final double? startX;
  final double? startY;

  /// End position of a drag / scroll gesture (global coordinates).
  final double? endX;
  final double? endY;

  /// Destination page for navigation events.
  final String? destinationPage;

  /// Tap position (global coordinates) for tap events.
  final double? tapX;
  final double? tapY;

  const InteractionEvent({
    required this.timestamp,
    required this.page,
    required this.type,
    this.testId,
    this.textValue,
    this.obscureText = false,
    this.startX,
    this.startY,
    this.endX,
    this.endY,
    this.destinationPage,
    this.tapX,
    this.tapY,
  });

  factory InteractionEvent.tap({
    required Duration timestamp,
    required String page,
    required String testId,
    required Offset position,
  }) =>
      InteractionEvent(
        timestamp: timestamp,
        page: page,
        type: InteractionEventType.tap,
        testId: testId,
        tapX: position.dx,
        tapY: position.dy,
      );

  factory InteractionEvent.textInput({
    required Duration timestamp,
    required String page,
    required String testId,
    required String text,
    required bool obscureText,
  }) =>
      InteractionEvent(
        timestamp: timestamp,
        page: page,
        type: InteractionEventType.textInput,
        testId: testId,
        textValue: obscureText ? null : text,
        obscureText: obscureText,
      );

  factory InteractionEvent.scroll({
    required Duration timestamp,
    required String page,
    required String? testId,
    required Offset start,
    required Offset end,
  }) =>
      InteractionEvent(
        timestamp: timestamp,
        page: page,
        type: InteractionEventType.scroll,
        testId: testId,
        startX: start.dx,
        startY: start.dy,
        endX: end.dx,
        endY: end.dy,
      );

  factory InteractionEvent.navigation({
    required Duration timestamp,
    required String page,
    required String destinationPage,
  }) =>
      InteractionEvent(
        timestamp: timestamp,
        page: page,
        type: InteractionEventType.navigation,
        destinationPage: destinationPage,
      );

  factory InteractionEvent.backNavigation({
    required Duration timestamp,
    required String page,
  }) =>
      InteractionEvent(
        timestamp: timestamp,
        page: page,
        type: InteractionEventType.backNavigation,
      );

  Map<String, dynamic> toJson() => {
        'timestampMs': timestamp.inMilliseconds,
        'page': page,
        'type': type.name,
        if (testId != null) 'testId': testId,
        if (textValue != null) 'textValue': textValue,
        'obscureText': obscureText,
        if (startX != null) 'startX': startX,
        if (startY != null) 'startY': startY,
        if (endX != null) 'endX': endX,
        if (endY != null) 'endY': endY,
        if (destinationPage != null) 'destinationPage': destinationPage,
        if (tapX != null) 'tapX': tapX,
        if (tapY != null) 'tapY': tapY,
      };

  factory InteractionEvent.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String;
    final type = InteractionEventType.values.firstWhere(
      (e) => e.name == typeName,
      orElse: () => InteractionEventType.tap,
    );

    final obscureText = (json['obscureText'] as bool?) ?? false;
    return InteractionEvent(
      timestamp: Duration(milliseconds: (json['timestampMs'] as num).toInt()),
      page: json['page'] as String,
      type: type,
      testId: json['testId'] as String?,
      // Recordings written before 0.1.1 stored obscured values; drop them.
      textValue: obscureText ? null : json['textValue'] as String?,
      obscureText: obscureText,
      startX: (json['startX'] as num?)?.toDouble(),
      startY: (json['startY'] as num?)?.toDouble(),
      endX: (json['endX'] as num?)?.toDouble(),
      endY: (json['endY'] as num?)?.toDouble(),
      destinationPage: json['destinationPage'] as String?,
      tapX: (json['tapX'] as num?)?.toDouble(),
      tapY: (json['tapY'] as num?)?.toDouble(),
    );
  }

  @override
  String toString() {
    final parts = <String>['${type.name}@${timestamp.inMilliseconds}ms', 'page=$page'];
    if (testId != null) parts.add('testId=$testId');
    if (textValue != null) parts.add('text=${obscureText ? '***' : textValue}');
    if (destinationPage != null) parts.add('dest=$destinationPage');
    return 'InteractionEvent(${parts.join(', ')})';
  }
}

/// Extension to easily create [Offset] from event coordinates.
extension InteractionEventOffset on InteractionEvent {
  Offset? get tapPosition => tapX != null && tapY != null ? Offset(tapX!, tapY!) : null;
  Offset? get scrollStart => startX != null && startY != null ? Offset(startX!, startY!) : null;
  Offset? get scrollEnd => endX != null && endY != null ? Offset(endX!, endY!) : null;
}
