import 'package:test/test.dart';
import 'package:theme_cli/src/ui/progress_bar.dart';
import 'package:theme_cli/src/ui/terminal_ui.dart';

void main() {
  group('ProgressBar', () {
    test('renders a bar with counts, percentage and ETA', () {
      final ui = TerminalUi(StringBuffer(), interactive: true);
      final line = ProgressBar.render(
        ui,
        frame: 0,
        done: 5,
        total: 10,
        current: 'Neon',
        elapsed: const Duration(seconds: 10),
        columns: 100,
      );
      expect(line, contains('5/10'));
      expect(line, contains('50%'));
      expect(line, contains('ETA 10s'));
      expect(line, endsWith('Neon'));
      expect('█'.allMatches(line).length, 13);
    });

    test('never exceeds the terminal width', () {
      final ui = TerminalUi(StringBuffer(), interactive: true);
      final line = ProgressBar.render(
        ui,
        frame: 3,
        done: 1,
        total: 3,
        current: 'a' * 200,
        elapsed: const Duration(seconds: 1),
        columns: 60,
      );
      expect(line.length, lessThan(60));
      expect(line, endsWith('…'));
    });

    test('is a spinner without a total', () {
      final ui = TerminalUi(StringBuffer(), interactive: true);
      final line = ProgressBar.render(
        ui,
        frame: 0,
        done: 0,
        total: 0,
        current: 'starting',
        elapsed: const Duration(seconds: 65),
        columns: 80,
      );
      expect(line, contains('1m5s'));
      expect(line, contains('starting'));
      expect(line, isNot(contains('%')));
    });

    test('only forwards log lines when the UI is plain', () {
      final out = StringBuffer();
      final bar = TerminalUi.plain(out).bar(total: 3, columns: () => 80)
        ..start('x')
        ..update(done: 1, current: 'y')
        ..log('hello')
        ..finish();
      expect(out.toString(), 'hello\n');
      bar.finish();
    });

    test('clears and redraws around log lines when interactive', () async {
      final out = StringBuffer();
      final bar = TerminalUi(
        out,
        interactive: true,
      ).bar(total: 2, columns: () => 80)..start('first');
      bar
        ..log('line')
        ..finish();
      final text = out.toString();
      expect(text, contains('line\n'));
      expect(text, endsWith('\r\x1B[2K'));
    });
  });

  group('TerminalUi', () {
    test('plain text stays unstyled', () {
      final ui = TerminalUi.plain(StringBuffer());
      expect(ui.ok('built'), 'built');
      expect(ui.bad('x'), 'x');
    });

    test('box rows share one width', () {
      final ui = TerminalUi(StringBuffer());
      final rows = ui
          .box('Done', ['built     3', 'a much longer line'])
          .split('\n');
      expect(rows.map((r) => r.length).toSet(), hasLength(1));
    });

    test('does not detect a terminal for a plain sink', () {
      final ui = TerminalUi.detect(StringBuffer());
      expect(ui.interactive, isFalse);
      expect(ui.canPrompt, isFalse);
    });
  });
}
