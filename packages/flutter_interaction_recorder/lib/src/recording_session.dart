import 'interaction_event.dart';

/// Represents a complete recording session.
///
/// A session captures all interactions from the moment recording starts
/// until it stops. Sessions are serialized to JSON and can be used by
/// [TestCodeGenerator] to produce integration test code.
class RecordingSession {
  /// Unique identifier (UUID-like string).
  final String id;

  /// Human-readable name, e.g. "Login as admin".
  final String name;

  /// When the recording started.
  final DateTime startTime;

  /// The page / route that was active when recording began.
  /// Integration tests will start from this page.
  final String startPage;

  /// All events in order.
  final List<InteractionEvent> events;

  /// Optional metadata (account name, role, etc.).
  final Map<String, dynamic> metadata;

  /// Tags for categorizing sessions (e.g. "login", "registration").
  final List<String> tags;

  RecordingSession({
    required this.id,
    required this.name,
    required this.startTime,
    required this.startPage,
    required this.events,
    this.metadata = const {},
    this.tags = const [],
  });

  /// Whether this session contains a login flow.
  bool get isLoginFlow => tags.contains('login') || _detectLoginFlow();

  /// Whether this session contains a registration flow.
  bool get isRegistrationFlow =>
      tags.contains('registration') || _detectRegistrationFlow();

  bool _detectLoginFlow() {
    final ids = events.where((e) => e.testId != null).map((e) => e.testId!).toSet();
    return ids.any((id) =>
        id.contains('login') || id.contains('password') || id.contains('username'));
  }

  bool _detectRegistrationFlow() {
    final ids = events.where((e) => e.testId != null).map((e) => e.testId!).toSet();
    return ids.any((id) =>
        id.contains('register') || id.contains('signup') || id.contains('sign_up'));
  }

  /// All unique test IDs used in this session.
  Set<String> get usedTestIds =>
      events.where((e) => e.testId != null).map((e) => e.testId!).toSet();

  /// All unique pages visited in this session.
  Set<String> get visitedPages =>
      {startPage, ...events.map((e) => e.page), ...events.where((e) => e.destinationPage != null).map((e) => e.destinationPage!)};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startTime': startTime.toIso8601String(),
        'startPage': startPage,
        'events': events.map((e) => e.toJson()).toList(),
        'metadata': metadata,
        'tags': tags,
      };

  factory RecordingSession.fromJson(Map<String, dynamic> json) {
    return RecordingSession(
      id: json['id'] as String,
      name: json['name'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      startPage: json['startPage'] as String,
      events: (json['events'] as List)
          .map((e) => InteractionEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      tags: (json['tags'] as List?)?.map((e) => e as String).toList() ?? [],
    );
  }
}

/// An account profile that can be used across multiple test flows.
///
/// Store multiple accounts with different roles to run the same
/// test flow with different credentials. The AI skill uses these
/// to generate parameterized tests.
class TestAccount {
  final String name;
  final String role;
  final Map<String, String> credentials;
  final Map<String, dynamic> metadata;

  const TestAccount({
    required this.name,
    required this.role,
    required this.credentials,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'role': role,
        'credentials': credentials,
        'metadata': metadata,
      };

  factory TestAccount.fromJson(Map<String, dynamic> json) => TestAccount(
        name: json['name'] as String,
        role: json['role'] as String,
        credentials: (json['credentials'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String)),
        metadata: (json['metadata'] as Map<String, dynamic>?) ?? {},
      );
}
