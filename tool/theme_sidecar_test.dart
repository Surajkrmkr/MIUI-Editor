// Headless render process for `theme build`: run via `flutter test`, which
// supplies the engine and the asset bundle. Without THEME_JOBS it does nothing.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theme_raster_flutter/theme_raster_flutter.dart';

const _jobs = String.fromEnvironment('THEME_JOBS');
const _results = String.fromEnvironment('THEME_RESULTS');

void main() {
  testWidgets(
    'build themes',
    (tester) async {
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      await tester.runAsync(
        () => runBuildJobs(
          jobsFile: _jobs,
          resultsFile: _results,
          context: context,
          // ignore: avoid_print
          log: (m) => print('[theme] $m'),
        ),
      );
    },
    skip: _jobs.isEmpty || _results.isEmpty,
    timeout: Timeout.none,
  );
}
