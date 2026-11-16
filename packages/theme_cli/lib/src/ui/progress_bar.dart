import 'dart:async';

import 'terminal_ui.dart';

/// One live terminal line: a bar when [total] > 0, a spinner otherwise.
/// Log lines print above it. Without an interactive [TerminalUi] it only
/// forwards [log] lines to the output.
class ProgressBar {
  ProgressBar(this._ui, {this.total = 0, required int Function() columns})
    : _columns = columns;

  static const _frames = ['⠋', '⠙', '⠹', '⠸', '⠼', '⠴', '⠦', '⠧', '⠇', '⠏'];

  final TerminalUi _ui;
  final int total;
  final int Function() _columns;
  final _clock = Stopwatch();
  Timer? _timer;
  var _done = 0;
  var _current = '';
  var _frame = 0;

  bool get _active => _timer != null;

  void start([String current = '']) {
    if (!_ui.interactive || _active) return;
    _current = current;
    _clock.start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _frame++;
      _draw();
    });
    _draw();
  }

  void update({int? done, String? current}) {
    if (done != null) _done = done;
    if (current != null) _current = current;
    if (_active) _draw();
  }

  /// Prints [line] above the live line.
  void log(String line) {
    if (!_active) {
      _ui.out.writeln(line);
      return;
    }
    _ui.out.write('\r\x1B[2K');
    _ui.out.writeln(line);
    _draw();
  }

  /// Removes the live line.
  void finish() {
    if (!_active) return;
    _timer!.cancel();
    _timer = null;
    _clock.stop();
    _ui.out.write('\r\x1B[2K');
  }

  void _draw() {
    _ui.out.write(
      '\r\x1B[2K${render(_ui, frame: _frame, done: _done, total: total, current: _current, elapsed: _clock.elapsed, columns: _columns())}',
    );
  }

  /// The live line for the given state; never wider than [columns] - 1.
  static String render(
    TerminalUi ui, {
    required int frame,
    required int done,
    required int total,
    required String current,
    required Duration elapsed,
    required int columns,
  }) {
    final spin = ui.accent(_frames[frame % _frames.length]);
    final time = formatDuration(elapsed);
    final String head;
    final int headLength;
    if (total > 0) {
      final width = (columns ~/ 4).clamp(10, 30);
      final filled = (width * done / total).round().clamp(0, width);
      final pct = (100 * done / total).round();
      final eta = done > 0 && done < total
          ? '  ETA ${formatDuration(elapsed * ((total - done) / done))}'
          : '';
      final bar = '${ui.ok('█' * filled)}${ui.dim('░' * (width - filled))}';
      final tail = '  $done/$total  $pct%  $time$eta';
      head = '$spin $bar${ui.dim(tail)}';
      headLength = 2 + width + tail.length;
    } else {
      final tail = ' $time';
      head = '$spin${ui.dim(tail)}';
      headLength = 1 + tail.length;
    }
    final room = columns - 1 - headLength - 2;
    if (current.isEmpty || room < 4) return head;
    final shown = current.length <= room
        ? current
        : '${current.substring(0, room - 1)}…';
    return '$head  $shown';
  }

  static String formatDuration(Duration d) {
    final s = d.inSeconds;
    if (s < 60) return '${s}s';
    return s < 3600
        ? '${s ~/ 60}m${s % 60}s'
        : '${s ~/ 3600}h${(s % 3600) ~/ 60}m';
  }
}
