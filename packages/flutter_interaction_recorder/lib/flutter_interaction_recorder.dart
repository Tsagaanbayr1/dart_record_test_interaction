/// Flutter Interaction Recorder
///
/// A package that records user interactions with test IDs and
/// generates integration test code for Flutter applications.
///
/// ## Quick start
///
/// 1. Wrap your app with [RecorderOverlay]:
/// ```dart
/// void main() {
///   runApp(RecorderOverlay(child: MyApp()));
/// }
/// ```
///
/// 2. Add the navigator observer to your [MaterialApp]:
/// ```dart
/// MaterialApp(
///   navigatorObservers: [RecorderOverlay.navigatorObserver],
///   ...
/// )
/// ```
///
/// 3. Wrap interactive widgets with [TestId]:
/// ```dart
/// TestId(id: 'login_button', child: ElevatedButton(...))
/// ```
///
/// 4. Use [TestIdTextField] for text inputs:
/// ```dart
/// TestIdTextField(id: 'username_field', decoration: ...)
/// ```
///
/// 5. Run the app in debug mode, tap the record button, and
///    interact with your app. Save the recording.
///
/// 6. Use [TestCodeGenerator] to generate integration test code
///    from saved recordings.
library flutter_interaction_recorder;

// Core models
export 'src/interaction_event.dart';
export 'src/recording_session.dart';

// Test ID system
export 'src/test_id.dart' show TestId, TestIdRegistry, makeTestKey, testKey, testIdKeyPrefix, TestIdWidgetExtension;
export 'src/test_id_text_field.dart';

// Recorder
export 'src/interaction_recorder.dart';
export 'src/navigation_tracker.dart';
export 'src/pointer_tracker.dart';

// UI
export 'src/recorder_overlay.dart';
export 'src/recorder_button.dart';

// Storage & code generation
export 'src/recording_storage.dart';
export 'src/test_code_generator.dart';
