import 'dart:io';

import '../root_config.dart';
import '../sidecar.dart';

/// What the tools need from the machine they run on.
class ThemeToolContext {
  ThemeToolContext({
    required this.cwd,
    required this.project,
    required this.sidecar,
    this.fontsDirs = const [],
    this.root,
  });

  /// Relative paths in tool arguments resolve here.
  final Directory cwd;

  /// The Flutter project holding `assets/` and the render entry, if found.
  final String? project;

  /// The render process; null when no project was found.
  final Sidecar? sidecar;

  /// Font folders every call searches, in addition to its own `fonts_dirs`.
  final List<String> fontsDirs;

  /// The designer's folder with Wall/, THEMES/, Sample2/ and Preset/, if the
  /// server was told where it is.
  final ThemeRoot? root;

  /// Renders share one Flutter project, and two at once collide in its build
  /// folder, so calls that render wait for each other.
  Future<void> _tail = Future.value();

  Future<T> exclusive<T>(Future<T> Function() job) {
    final done = Future<T>.sync(() => _tail.then((_) => job()));
    _tail = done.then<void>((_) {}, onError: (_) {});
    return done;
  }
}
