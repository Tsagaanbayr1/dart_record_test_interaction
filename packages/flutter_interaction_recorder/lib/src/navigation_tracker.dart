import 'package:flutter/widgets.dart';

import 'interaction_recorder.dart';

/// A [NavigatorObserver] that reports route changes to
/// [InteractionRecorder].
///
/// Add this observer to your [Navigator] (usually via [MaterialApp]
/// or [CupertinoApp] `navigatorObservers`):
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [NavigationTracker()],
///   ...
/// )
/// ```
///
/// If you use [RecorderOverlay], it automatically injects this
/// observer for you.
class NavigationTracker extends NavigatorObserver {
  /// Optional override to extract a page name from a [Route].
  /// By default uses [RouteSettings.name] or the route type name.
  static String Function(Route)? pageNameExtractor;

  @override
  void didPush(Route route, Route? previousRoute) {
    final name = _extractPageName(route);
    InteractionRecorder.instance.onPageChanged(name);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    if (previousRoute != null) {
      final name = _extractPageName(previousRoute);
      InteractionRecorder.instance.onPageChanged(name);
    }
    InteractionRecorder.instance.onBackNavigation();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    if (newRoute != null) {
      final name = _extractPageName(newRoute);
      InteractionRecorder.instance.onPageChanged(name);
    }
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    if (previousRoute != null) {
      final name = _extractPageName(previousRoute);
      InteractionRecorder.instance.onPageChanged(name);
    }
  }

  String _extractPageName(Route route) {
    if (pageNameExtractor != null) return pageNameExtractor!(route);

    // Try RouteSettings.name first
    final settingsName = route.settings.name;
    if (settingsName != null && settingsName.isNotEmpty) {
      return settingsName;
    }

    // Fall back to the route type name, stripping common suffixes
    final typeName = route.runtimeType.toString();
    return typeName
        .replaceAll('Material', '')
        .replaceAll('PageRoute', '')
        .replaceAll('Route', '')
        .replaceAll('Page', '');
  }
}
