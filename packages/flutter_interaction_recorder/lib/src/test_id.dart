import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Prefix used for all test ID value keys.
///
/// In integration tests, widgets are found via:
///   `find.byKey(const ValueKey('__test_id__<id>'))`
const testIdKeyPrefix = '__test_id__';

/// Constructs the [ValueKey] used by [TestId] widgets.
ValueKey<String> makeTestKey(String id) => ValueKey('$testIdKeyPrefix$id');

/// A global registry that tracks all [TestId] render objects and their
/// positions. The [InteractionRecorder] uses this to resolve which test
/// ID was tapped at a given screen position.
class TestIdRegistry {
  static final TestIdRegistry instance = TestIdRegistry._();

  TestIdRegistry._();

  /// Maps test ID -> set of render objects currently on screen.
  final Map<String, Set<RenderBox>> _renderObjects = {};

  /// Callback fired whenever a new test ID appears on screen.
  void Function(String id)? onTestIdsChanged;

  void registerRenderObject(String id, RenderBox ro) {
    _renderObjects.putIfAbsent(id, () => {}).add(ro);
    onTestIdsChanged?.call(id);
  }

  void unregisterRenderObject(String id, RenderBox ro) {
    _renderObjects[id]?.remove(ro);
    if (_renderObjects[id]?.isEmpty ?? false) {
      _renderObjects.remove(id);
    }
  }

  /// Finds the most specific (smallest) test ID whose render box
  /// contains [position]. Returns null if no test ID'd widget is at
  /// that position.
  String? findTestIdAt(Offset position) {
    String? bestId;
    double bestArea = double.infinity;

    for (final entry in _renderObjects.entries) {
      for (final ro in Set.from(entry.value)) {
        if (ro is! RenderBox || !ro.attached) continue;
        final box = ro;
        if (!box.hasSize) continue;

        final topLeft = box.localToGlobal(Offset.zero);
        final rect = topLeft & box.size;

        if (rect.contains(position)) {
          final area = box.size.width * box.size.height;
          if (area < bestArea) {
            bestArea = area;
            bestId = entry.key;
          }
        }
      }
    }

    return bestId;
  }

  /// All test IDs currently registered (i.e. visible on screen).
  Set<String> get allIds => Set<String>.from(_renderObjects.keys);

  /// Clears the registry (used on hot restart).
  void clear() {
    _renderObjects.clear();
  }
}

/// A lightweight render object that proxies to its child while
/// registering itself with [TestIdRegistry] for position tracking.
class _TestMarkerRenderObject extends RenderProxyBox {
  String testId;

  _TestMarkerRenderObject(this.testId);

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    TestIdRegistry.instance.registerRenderObject(testId, this);
  }

  @override
  void detach() {
    TestIdRegistry.instance.unregisterRenderObject(testId, this);
    super.detach();
  }
}

/// A [SingleChildRenderObjectWidget] that creates a [_TestMarkerRenderObject].
///
/// The [ValueKey] on this widget is what integration tests use to find
/// the widget via `find.byKey(makeTestKey(id))`.
class _TestMarker extends SingleChildRenderObjectWidget {
  final String testId;

  const _TestMarker({
    required this.testId,
    super.key,
    super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _TestMarkerRenderObject(testId);

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _TestMarkerRenderObject renderObject,
  ) {
    if (renderObject.testId != testId) {
      if (renderObject.attached) {
        TestIdRegistry.instance.unregisterRenderObject(
          renderObject.testId,
          renderObject,
        );
      }
      renderObject.testId = testId;
      if (renderObject.attached) {
        TestIdRegistry.instance.registerRenderObject(testId, renderObject);
      }
    }
  }
}

/// Wraps any widget with a test ID that the recorder can track.
///
/// Wrap every interactive widget in your app with [TestId]:
///
/// ```dart
/// TestId(
///   id: 'login_button',
///   child: ElevatedButton(onPressed: _login, child: Text('Login')),
/// )
/// ```
///
/// In integration tests, the widget is found via:
/// `find.byKey(makeTestKey('login_button'))`
class TestId extends StatelessWidget {
  /// The unique identifier for this widget. Should be descriptive
  /// and unique within a page (e.g. 'login_button', 'email_field').
  final String id;

  /// The child widget to mark with this test ID.
  final Widget child;

  const TestId({
    super.key,
    required this.id,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _TestMarker(
      key: makeTestKey(id),
      testId: id,
      child: child,
    );
  }
}

/// Extension to easily add a test ID to any widget.
///
/// ```dart
/// ElevatedButton(onPressed: _login, child: Text('Login')).withTestId('login_button')
/// ```
extension TestIdWidgetExtension on Widget {
  Widget withTestId(String id) => TestId(id: id, child: this);
}

/// Shortcut for [makeTestKey] — creates the [ValueKey] used by [TestId]
/// widgets. In generated tests (both Flutter and Patrol), this is used
/// to find widgets:
///
/// Flutter:  `find.byKey(testKey('login_button'))`
/// Patrol:   `$(testKey('login_button')).tap()`
ValueKey<String> testKey(String id) => makeTestKey(id);
