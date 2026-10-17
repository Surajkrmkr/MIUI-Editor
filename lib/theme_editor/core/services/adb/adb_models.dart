enum AdbThemeDestination {
  downloads('Downloads', '/sdcard/Download/auto/temp.mtz'),
  themeManager(
    'Theme Manager',
    '/sdcard/Android/data/com.android.thememanager/files/temp.mtz',
  );

  const AdbThemeDestination(this.label, this.path);
  final String label;
  final String path;
}

/// Steps of the "Apply to Device" flow, also used to tag results.
enum AdbStep {
  locate('Locating ADB'),
  download('Downloading ADB'),
  detect('Detecting device'),
  connect('Connecting wirelessly'),
  push('Pushing file'),
  launch('Launching');

  const AdbStep(this.label);
  final String label;
}

/// Typed outcome of an adb operation; never throws.
class AdbResult<T> {
  const AdbResult._({
    required this.ok,
    required this.step,
    this.value,
    this.message = '',
    this.stdout = '',
    this.stderr = '',
  });

  factory AdbResult.success(AdbStep step, T value, {String stdout = ''}) =>
      AdbResult._(ok: true, step: step, value: value, stdout: stdout);

  factory AdbResult.failure(
    AdbStep step,
    String message, {
    String stdout = '',
    String stderr = '',
  }) => AdbResult._(
    ok: false,
    step: step,
    message: message,
    stdout: stdout,
    stderr: stderr,
  );

  final bool ok;
  final AdbStep step;
  final T? value;
  final String message;
  final String stdout;
  final String stderr;

  /// Combined raw output for "details" views.
  String get details => [
    if (stdout.trim().isNotEmpty) 'stdout:\n${stdout.trim()}',
    if (stderr.trim().isNotEmpty) 'stderr:\n${stderr.trim()}',
  ].join('\n\n');

  /// Re-types a failure so it can be propagated from another method.
  AdbResult<R> cast<R>() => AdbResult<R>._(
    ok: ok,
    step: step,
    message: message,
    stdout: stdout,
    stderr: stderr,
  );
}

/// Raw output of a single process invocation.
class ProcessOutput {
  const ProcessOutput({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.timedOut = false,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
  final bool timedOut;

  bool get ok => exitCode == 0 && !timedOut;
}

enum AdbDeviceState { device, unauthorized, offline, noPermissions, unknown }

/// One row of `adb devices -l`.
class AdbDevice {
  const AdbDevice({
    required this.serial,
    required this.state,
    required this.rawState,
    this.model,
    this.product,
    this.transportId,
  });

  final String serial;
  final AdbDeviceState state;
  final String rawState;
  final String? model;
  final String? product;
  final String? transportId;

  bool get isReady => state == AdbDeviceState.device;

  bool get isWireless =>
      serial.contains(':') || serial.contains('._adb-tls-connect.');

  String get displayName {
    final name = model?.replaceAll('_', ' ') ?? serial;
    final via = isWireless ? 'Wi-Fi' : 'USB';
    return '$name ($serial, $via, $rawState)';
  }
}

/// A Themes-app activity that can apply an .mtz.
class ApplyActivity {
  const ApplyActivity({
    required this.component,
    required this.dumpsysForms,
    required this.extras,
  });

  /// Value passed to `am start -n`.
  final String component;

  /// Forms in which `dumpsys package` may print this activity.
  final List<String> dumpsysForms;

  /// `-e key value` pairs.
  final Map<String, String> extras;
}

/// Successful end of [AdbService.applyToDevice].
class ApplyOutcome {
  const ApplyOutcome({required this.serial, required this.activity});
  final String serial;
  final String activity;
}
