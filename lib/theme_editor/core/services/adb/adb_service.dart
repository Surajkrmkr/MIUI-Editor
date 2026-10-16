import 'dart:io';

import 'adb_locator.dart';
import 'adb_models.dart';
import 'adb_parsers.dart';
import 'adb_process.dart';

/// All adb interaction for pushing and applying an .mtz on a phone.
class AdbService {
  AdbService(this._locator);

  final AdbLocator _locator;

  // Device paths are POSIX on every host OS.
  static const String deviceDir = '/sdcard/Download/auto';
  static const String deviceMtzPath = '$deviceDir/temp.mtz';
  static const String themeManagerPackage = 'com.android.thememanager';
  static const int defaultTcpPort = 5555;

  static const Duration _cmdTimeout = Duration(seconds: 15);
  static const Duration _pushTimeout = Duration(minutes: 5);

  static const Map<String, String> _baseExtras = {
    'theme_file_path': deviceMtzPath,
    'api_called_from': 'ThemeEditor',
  };

  /// Tried in this order.
  static const List<ApplyActivity> applyActivities = [
    ApplyActivity(
      component:
          '$themeManagerPackage/$themeManagerPackage.ApplyThemeForScreenshot2',
      dumpsysForms: [
        '$themeManagerPackage/.ApplyThemeForScreenshot2',
        '$themeManagerPackage/$themeManagerPackage.ApplyThemeForScreenshot2',
      ],
      extras: {..._baseExtras, 'ver2_step': 'ver2_step_init'},
    ),
    ApplyActivity(
      component:
          '$themeManagerPackage/$themeManagerPackage.ApplyThemeForScreenshot',
      dumpsysForms: [
        '$themeManagerPackage/.ApplyThemeForScreenshot',
        '$themeManagerPackage/$themeManagerPackage.ApplyThemeForScreenshot',
      ],
      extras: _baseExtras,
    ),
    ApplyActivity(
      component: '$themeManagerPackage/.activity.ApplyThemeForScreenshot',
      dumpsysForms: [
        '$themeManagerPackage/.activity.ApplyThemeForScreenshot',
        '$themeManagerPackage/$themeManagerPackage.activity.ApplyThemeForScreenshot',
      ],
      extras: _baseExtras,
    ),
  ];

  String? get adbPath => _locator.cachedPath;

  // ── ADB binary ─────────────────────────────────────────────────────────────

  Future<AdbResult<String>> locateAdb({
    String? userPath,
    bool forceRefresh = false,
  }) => _locator.locate(userPath: userPath, forceRefresh: forceRefresh);

  Future<AdbResult<String>> downloadAdb({
    void Function(double? progress)? onProgress,
  }) => _locator.download(onProgress: onProgress);

  Future<AdbResult<String>> testAdbPath(String path) => _locator.verify(path);

  void resetAdbCache() => _locator.clearCache();

  // ── Devices ────────────────────────────────────────────────────────────────

  Future<AdbResult<List<AdbDevice>>> listDevices() async {
    final out = await _adb(AdbStep.detect, const ['devices', '-l']);
    if (out == null) return _noAdb(AdbStep.detect);
    if (!out.ok) {
      return AdbResult.failure(
        AdbStep.detect,
        'adb devices failed',
        stdout: out.stdout,
        stderr: out.stderr,
      );
    }
    return AdbResult.success(
      AdbStep.detect,
      AdbParsers.parseDevices(out.stdout),
      stdout: out.stdout,
    );
  }

  /// Human-readable explanation of why no device is usable.
  static String describeDeviceProblem(List<AdbDevice> devices) {
    if (devices.isEmpty) {
      final driverHint = Platform.isWindows
          ? ' On Windows, a phone that is plugged in but not listed usually '
                'needs its OEM or Google USB driver installed.'
          : '';
      return 'No device found. Enable USB debugging, check the cable '
          '(data-capable) and USB mode, or connect over Wi-Fi.$driverHint';
    }
    if (devices.any((d) => d.state == AdbDeviceState.unauthorized)) {
      return 'Device unauthorized. Unlock the phone and accept the '
          '"Allow USB debugging?" prompt, then refresh.';
    }
    if (devices.any((d) => d.state == AdbDeviceState.offline)) {
      return 'Device offline. Reconnect the cable / Wi-Fi, or click '
          '"Restart ADB server" (adb kill-server) and refresh.';
    }
    if (devices.any((d) => d.state == AdbDeviceState.noPermissions)) {
      return 'No permission to access the device. Replug it and accept any '
          'prompt on the phone.';
    }
    return 'No ready device (${devices.map((d) => d.rawState).join(', ')}).';
  }

  Future<AdbResult<void>> restartServer() async {
    final kill = await _adb(AdbStep.detect, const ['kill-server']);
    if (kill == null) return _noAdb(AdbStep.detect);
    final start = await _adb(AdbStep.detect, const ['start-server']);
    if (start == null || !start.ok) {
      return AdbResult.failure(
        AdbStep.detect,
        'Could not start adb server',
        stdout: start?.stdout ?? '',
        stderr: start?.stderr ?? '',
      );
    }
    return AdbResult.success(AdbStep.detect, null);
  }

  // ── Wireless ───────────────────────────────────────────────────────────────

  Future<AdbResult<void>> connectWireless(String ip, int port) async {
    final target = '${ip.trim()}:$port';
    final out = await _adb(AdbStep.connect, ['connect', target]);
    if (out == null) return _noAdb(AdbStep.connect);
    if (out.ok && AdbParsers.connectSucceeded(out.stdout)) {
      return AdbResult.success(AdbStep.connect, null, stdout: out.stdout);
    }
    return AdbResult.failure(
      AdbStep.connect,
      'Could not connect to $target. Make sure the phone is on the same '
      'Wi-Fi and wireless/TCP debugging is enabled.',
      stdout: out.stdout,
      stderr: out.stderr,
    );
  }

  /// Android 11+ wireless debugging pairing.
  Future<AdbResult<void>> pair(String ip, int pairingPort, String code) async {
    final out = await _adb(AdbStep.connect, [
      'pair',
      '${ip.trim()}:$pairingPort',
      code.trim(),
    ]);
    if (out == null) return _noAdb(AdbStep.connect);
    if (AdbParsers.pairSucceeded(out.stdout)) {
      return AdbResult.success(AdbStep.connect, null, stdout: out.stdout);
    }
    return AdbResult.failure(
      AdbStep.connect,
      'Pairing failed. Check the pairing port and code shown under '
      'Developer options > Wireless debugging > Pair device with pairing code.',
      stdout: out.stdout,
      stderr: out.stderr,
    );
  }

  /// Switches a USB device to TCP mode and connects to it. Returns "ip:port".
  Future<AdbResult<String>> switchToWireless(String serial) async {
    final ip = await _deviceIp(serial);
    if (ip == null) {
      return AdbResult.failure(
        AdbStep.connect,
        'Could not read the phone\'s Wi-Fi IP. Is Wi-Fi turned on?',
      );
    }
    final tcp = await _adb(AdbStep.connect, [
      'tcpip',
      '$defaultTcpPort',
    ], serial: serial);
    if (tcp == null) return _noAdb(AdbStep.connect);
    if (!tcp.ok) {
      return AdbResult.failure(
        AdbStep.connect,
        'adb tcpip failed',
        stdout: tcp.stdout,
        stderr: tcp.stderr,
      );
    }
    // adbd restarts in TCP mode; give it a moment before connecting.
    await Future<void>.delayed(const Duration(seconds: 2));
    final c = await connectWireless(ip, defaultTcpPort);
    if (!c.ok) return c.cast();
    return AdbResult.success(
      AdbStep.connect,
      '$ip:$defaultTcpPort',
      stdout: c.stdout,
    );
  }

  Future<String?> _deviceIp(String serial) async {
    final addr = await _adb(AdbStep.connect, const [
      'shell',
      'ip',
      '-f',
      'inet',
      'addr',
      'show',
      'wlan0',
    ], serial: serial);
    final fromAddr = addr == null
        ? null
        : AdbParsers.parseInetAddr(addr.stdout);
    if (fromAddr != null) return fromAddr;
    final route = await _adb(AdbStep.connect, const [
      'shell',
      'ip',
      'route',
    ], serial: serial);
    return route == null ? null : AdbParsers.parseRouteSrc(route.stdout);
  }

  // ── Push & launch ──────────────────────────────────────────────────────────

  Future<AdbResult<void>> pushTheme(String serial, String localPath) async {
    final file = File(localPath);
    if (!file.existsSync()) {
      return AdbResult.failure(AdbStep.push, 'File not found: $localPath');
    }
    final size = await file.length();

    final mkdir = await _adb(AdbStep.push, const [
      'shell',
      'mkdir',
      '-p',
      deviceDir,
    ], serial: serial);
    if (mkdir == null) return _noAdb(AdbStep.push);
    if (!mkdir.ok) {
      return AdbResult.failure(
        AdbStep.push,
        'Could not create $deviceDir',
        stdout: mkdir.stdout,
        stderr: mkdir.stderr,
      );
    }

    final push = await _adb(
      AdbStep.push,
      ['push', localPath, deviceMtzPath],
      serial: serial,
      timeout: _pushTimeout,
    );
    if (push == null) return _noAdb(AdbStep.push);
    if (!push.ok) {
      return AdbResult.failure(
        AdbStep.push,
        'adb push failed',
        stdout: push.stdout,
        stderr: push.stderr,
      );
    }

    final ls = await _adb(AdbStep.push, const [
      'shell',
      'ls',
      '-l',
      deviceMtzPath,
    ], serial: serial);
    if (ls == null) return _noAdb(AdbStep.push);
    if (!AdbParsers.lsShowsFile(ls.stdout, deviceMtzPath, size)) {
      return AdbResult.failure(
        AdbStep.push,
        'Pushed file could not be verified on the device (expected $size bytes)',
        stdout: ls.stdout,
        stderr: ls.stderr,
      );
    }
    return AdbResult.success(AdbStep.push, null, stdout: push.stdout);
  }

  /// Starts the first working apply activity. Returns its component.
  Future<AdbResult<String>> launchApply(
    String serial, {
    String? cachedComponent,
  }) async {
    final ordered = <ApplyActivity>[];
    final cached = applyActivities
        .where((a) => a.component == cachedComponent)
        .firstOrNull;
    if (cached != null) {
      ordered.add(cached);
    } else {
      final dump = await _adb(AdbStep.launch, const [
        'shell',
        'dumpsys',
        'package',
        themeManagerPackage,
      ], serial: serial);
      if (dump == null) return _noAdb(AdbStep.launch);
      final found = applyActivities
          .where((a) => AdbParsers.dumpsysHasActivity(dump.stdout, a))
          .toList();
      ordered.addAll(found);
    }
    // Fall back to trying everything if detection found nothing usable.
    ordered.addAll(applyActivities.where((a) => !ordered.contains(a)));

    final log = StringBuffer();
    for (final activity in ordered) {
      final args = <String>['shell', 'am', 'start', '-n', activity.component];
      activity.extras.forEach((k, v) => args.addAll(['-e', k, v]));
      final out = await _adb(AdbStep.launch, args, serial: serial);
      if (out == null) return _noAdb(AdbStep.launch);
      final combined = '${out.stdout}\n${out.stderr}';
      log.writeln('> ${activity.component}\n${combined.trim()}\n');
      if (out.ok && !AdbParsers.amStartFailed(combined)) {
        return AdbResult.success(
          AdbStep.launch,
          activity.component,
          stdout: out.stdout,
        );
      }
    }
    return AdbResult.failure(
      AdbStep.launch,
      'No apply activity could be started. Is the Themes app '
      '($themeManagerPackage) installed and up to date?',
      stdout: log.toString(),
    );
  }

  // ── Orchestration ──────────────────────────────────────────────────────────

  /// Locate → detect (with wireless auto-reconnect) → push → launch.
  Future<AdbResult<ApplyOutcome>> applyToDevice({
    required String localMtzPath,
    String? userAdbPath,
    String? preferredSerial,
    String? lastWirelessTarget,
    Map<String, String> cachedActivities = const {},
    void Function(AdbStep step)? onStep,
  }) async {
    onStep?.call(AdbStep.locate);
    final located = await locateAdb(userPath: userAdbPath);
    if (!located.ok) return located.cast();

    onStep?.call(AdbStep.detect);
    var listed = await listDevices();
    if (!listed.ok) return listed.cast();
    var ready = listed.value!.where((d) => d.isReady).toList();

    if (ready.isEmpty && lastWirelessTarget != null) {
      final (ip, port) = parseTarget(lastWirelessTarget);
      if (ip != null) {
        final c = await connectWireless(ip, port);
        if (c.ok) {
          listed = await listDevices();
          if (!listed.ok) return listed.cast();
          ready = listed.value!.where((d) => d.isReady).toList();
        }
      }
    }

    if (ready.isEmpty) {
      return AdbResult.failure(
        AdbStep.detect,
        describeDeviceProblem(listed.value!),
        stdout: listed.stdout,
      );
    }

    final AdbDevice device;
    final preferred = ready
        .where((d) => d.serial == preferredSerial)
        .firstOrNull;
    if (preferred != null) {
      device = preferred;
    } else if (ready.length == 1) {
      device = ready.single;
    } else {
      return AdbResult.failure(
        AdbStep.detect,
        'Multiple devices connected. Pick one in the device list.',
        stdout: listed.stdout,
      );
    }

    onStep?.call(AdbStep.push);
    final pushed = await pushTheme(device.serial, localMtzPath);
    if (!pushed.ok) return pushed.cast();

    onStep?.call(AdbStep.launch);
    final launched = await launchApply(
      device.serial,
      cachedComponent: cachedActivities[device.serial],
    );
    if (!launched.ok) return launched.cast();

    return AdbResult.success(
      AdbStep.launch,
      ApplyOutcome(serial: device.serial, activity: launched.value!),
      stdout: launched.stdout,
    );
  }

  /// Splits "ip:port" (port defaults to 5555).
  static (String?, int) parseTarget(String target) {
    final t = target.trim();
    if (t.isEmpty) return (null, defaultTcpPort);
    final i = t.lastIndexOf(':');
    if (i <= 0) return (t, defaultTcpPort);
    return (
      t.substring(0, i),
      int.tryParse(t.substring(i + 1)) ?? defaultTcpPort,
    );
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  /// Runs adb with optional `-s serial`. Returns null if adb isn't located.
  Future<ProcessOutput?> _adb(
    AdbStep step,
    List<String> args, {
    String? serial,
    Duration timeout = _cmdTimeout,
  }) async {
    final adb = _locator.cachedPath;
    if (adb == null) return null;
    return runProcess(adb, [
      if (serial != null) ...['-s', serial],
      ...args,
    ], timeout: timeout);
  }

  AdbResult<T> _noAdb<T>(AdbStep step) => AdbResult.failure(
    step,
    'ADB is not configured. Locate or download it first.',
  );
}
