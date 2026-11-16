import 'dart:io';

import 'package:mason_logger/mason_logger.dart';

import 'progress_bar.dart';

/// Colors, live progress and prompts for the `theme` CLI.
///
/// Everything degrades to plain text unless [interactive]: output that is
/// piped, a dumb terminal or `CI` keeps the exact text scripts and tests see.
class TerminalUi {
  TerminalUi(
    this.out, {
    this.interactive = false,
    this.canPrompt = false,
    this.color = false,
  });

  /// No colors, no live line, no prompts.
  TerminalUi.plain(this.out)
    : interactive = false,
      canPrompt = false,
      color = false;

  factory TerminalUi.detect(StringSink out, {Map<String, String>? env}) {
    final e = env ?? Platform.environment;
    final tty = identical(out, stdout) && stdout.hasTerminal;
    final interactive = tty && !e.containsKey('CI') && e['TERM'] != 'dumb';
    return TerminalUi(
      out,
      interactive: interactive,
      canPrompt: interactive && stdin.hasTerminal,
      color: interactive && !e.containsKey('NO_COLOR'),
    );
  }

  final StringSink out;

  /// Draw live lines (progress bar, spinner).
  final bool interactive;

  /// Ask questions on stdin.
  final bool canPrompt;
  final bool color;

  Logger? _logger;
  Logger get _log => _logger ??= Logger();

  String _paint(AnsiCode code, String s) => color ? (code.wrap(s) ?? s) : s;

  String ok(String s) => _paint(green, s);
  String warn(String s) => _paint(yellow, s);
  String bad(String s) => _paint(red, s);
  String dim(String s) => _paint(darkGray, s);
  String bold(String s) => color ? (styleBold.wrap(s) ?? s) : s;
  String accent(String s) => _paint(cyan, s);

  /// A bar for [total] steps, or a spinner when [total] is 0.
  ProgressBar bar({int total = 0, int Function()? columns}) => ProgressBar(
    this,
    total: total,
    columns: columns ?? () => stdout.hasTerminal ? stdout.terminalColumns : 80,
  );

  bool confirm(String message, {bool defaultValue = true}) =>
      _log.confirm(message, defaultValue: defaultValue);

  String chooseOne(String message, List<String> choices) =>
      _log.chooseOne(message, choices: choices);

  String prompt(String message, {String? defaultValue}) =>
      _log.prompt(message, defaultValue: defaultValue);

  /// A rounded box around [lines]; borders are colored, [lines] keep their own
  /// styling.
  String box(String title, List<String> lines) {
    var inner = _visible(title) + 2;
    for (final l in lines) {
      final n = _visible(l);
      if (n > inner) inner = n;
    }
    inner += 2;
    String row(String text) =>
        '${accent('│')} $text${' ' * (inner - _visible(text) - 1)}${accent('│')}';
    final top =
        '${accent('╭─ ')}${bold(title)}'
        '${accent(' ${'─' * (inner - _visible(title) - 3)}╮')}';
    return [
      top,
      for (final l in lines) row(l),
      accent('╰${'─' * inner}╯'),
    ].join('\n');
  }

  static final _ansi = RegExp('\x1B\\[[0-9;]*m');
  static int _visible(String s) => s.replaceAll(_ansi, '').length;
}
