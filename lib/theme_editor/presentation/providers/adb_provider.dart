import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/constants/app_constants.dart';
import '../../core/constants/path_constants.dart';
import '../../core/services/adb/adb_locator.dart';
import '../../core/services/adb/adb_models.dart';
import '../../core/services/adb/adb_service.dart';
import 'lockscreen_provider.dart';
import 'service_providers.dart';
import 'wallpaper_provider.dart';

final adbServiceProvider = Provider<AdbService>(
  (ref) => AdbService(
    AdbLocator(),
    destinationPath: ref.watch(adbThemeDestinationProvider).path,
  ),
);

class AdbThemeDestinationNotifier extends Notifier<AdbThemeDestination> {
  static const preferenceKey = 'adb_theme_destination';

  @override
  AdbThemeDestination build() {
    final stored = ref.watch(sharedPrefsProvider).getString(preferenceKey);
    return AdbThemeDestination.values
            .where((destination) => destination.path == stored)
            .firstOrNull ??
        AdbThemeDestination.downloads;
  }

  Future<void> select(AdbThemeDestination destination) async {
    final saved = await ref
        .read(sharedPrefsProvider)
        .setString(preferenceKey, destination.path);
    if (!saved) throw StateError('Could not save ADB destination');
    state = destination;
  }
}

final adbThemeDestinationProvider =
    NotifierProvider<AdbThemeDestinationNotifier, AdbThemeDestination>(
      AdbThemeDestinationNotifier.new,
    );

enum StepStatus { pending, running, done, failed }

/// Steps shown in the progress list, in order.
const applySteps = [
  AdbStep.locate,
  AdbStep.detect,
  AdbStep.push,
  AdbStep.launch,
];

const _unset = Object();

class ApplyToDeviceState {
  const ApplyToDeviceState({
    this.steps = const {},
    this.isRunning = false,
    this.isBusy = false,
    this.devices = const [],
    this.selectedSerial,
    this.adbPath,
    this.mtzPath,
    this.downloadProgress,
    this.isDownloading = false,
    this.error,
    this.errorStep,
    this.errorDetails = '',
    this.info,
  });

  final Map<AdbStep, StepStatus> steps;
  final bool isRunning;

  /// A secondary action (refresh, connect, pair, test...) is in progress.
  final bool isBusy;
  final List<AdbDevice> devices;
  final String? selectedSerial;
  final String? adbPath;
  final String? mtzPath;
  final double? downloadProgress;
  final bool isDownloading;
  final String? error;
  final AdbStep? errorStep;
  final String errorDetails;
  final String? info;

  bool get adbMissing => adbPath == null;

  bool get hasReadyDevice => devices.any((d) => d.isReady);

  AdbDevice? get selectedDevice =>
      devices.where((d) => d.serial == selectedSerial).firstOrNull;

  StepStatus statusOf(AdbStep step) => steps[step] ?? StepStatus.pending;

  ApplyToDeviceState copyWith({
    Map<AdbStep, StepStatus>? steps,
    bool? isRunning,
    bool? isBusy,
    List<AdbDevice>? devices,
    Object? selectedSerial = _unset,
    Object? adbPath = _unset,
    Object? mtzPath = _unset,
    Object? downloadProgress = _unset,
    bool? isDownloading,
    Object? error = _unset,
    Object? errorStep = _unset,
    String? errorDetails,
    Object? info = _unset,
  }) => ApplyToDeviceState(
    steps: steps ?? this.steps,
    isRunning: isRunning ?? this.isRunning,
    isBusy: isBusy ?? this.isBusy,
    devices: devices ?? this.devices,
    selectedSerial: selectedSerial == _unset
        ? this.selectedSerial
        : selectedSerial as String?,
    adbPath: adbPath == _unset ? this.adbPath : adbPath as String?,
    mtzPath: mtzPath == _unset ? this.mtzPath : mtzPath as String?,
    downloadProgress: downloadProgress == _unset
        ? this.downloadProgress
        : downloadProgress as double?,
    isDownloading: isDownloading ?? this.isDownloading,
    error: error == _unset ? this.error : error as String?,
    errorStep: errorStep == _unset ? this.errorStep : errorStep as AdbStep?,
    errorDetails: errorDetails ?? this.errorDetails,
    info: info == _unset ? this.info : info as String?,
  );
}

class ApplyToDeviceNotifier extends Notifier<ApplyToDeviceState> {
  AdbService get _adb => ref.read(adbServiceProvider);

  @override
  ApplyToDeviceState build() {
    final prefs = ref.read(sharedPrefsProvider);
    return ApplyToDeviceState(
      selectedSerial: prefs.getString(AppConstants.prefsAdbLastSerial),
      adbPath: _adb.adbPath,
    );
  }

  // ── Settings accessors ─────────────────────────────────────────────────────

  String get userAdbPath =>
      ref.read(sharedPrefsProvider).getString(AppConstants.prefsAdbPath) ?? '';

  String get lastWirelessTarget =>
      ref
          .read(sharedPrefsProvider)
          .getString(AppConstants.prefsAdbLastWireless) ??
      '';

  Map<String, String> get _activityCache {
    final raw = ref
        .read(sharedPrefsProvider)
        .getString(AppConstants.prefsAdbActivityCache);
    if (raw == null || raw.isEmpty) return {};
    try {
      return (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v.toString()),
      );
    } on FormatException {
      return {};
    }
  }

  Future<void> _saveActivity(String serial, String component) async {
    final cache = _activityCache..[serial] = component;
    await ref
        .read(sharedPrefsProvider)
        .setString(AppConstants.prefsAdbActivityCache, jsonEncode(cache));
  }

  Future<void> _saveWireless(String target) => ref
      .read(sharedPrefsProvider)
      .setString(AppConstants.prefsAdbLastWireless, target);

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Called when the dialog opens: resolve mtz + adb, then list devices.
  Future<void> init() async {
    state = state.copyWith(
      mtzPath: resolveMtzPath(),
      error: null,
      errorStep: null,
      errorDetails: '',
      info: null,
    );
    await locate();
    if (!state.adbMissing) await refreshDevices();
  }

  /// Finds the already-exported .mtz for the current theme.
  ///
  /// With dual export enabled the `_V3` file is preferred.
  String? resolveMtzPath() {
    final ws = ref.read(wallpaperProvider);
    final name = ws.currentThemeName;
    if (ws.weekNum == null || name == null) return null;
    final themePath = PathConstants.themePath(ws.weekNum!, name);
    final parent = Directory(themePath).parent.path;
    final dual = ref.read(lockscreenProvider).dualMtzExport;
    final names = dual
        ? ['${name}_V3.mtz', '$name.mtz']
        : ['$name.mtz', '${name}_V3.mtz'];
    for (final n in names) {
      final path = p.join(parent, n);
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  // ── ADB binary ─────────────────────────────────────────────────────────────

  Future<void> locate({bool force = false}) async {
    final r = await _adb.locateAdb(userPath: userAdbPath, forceRefresh: force);
    state = state.copyWith(adbPath: r.ok ? r.value : null);
    if (!r.ok) _fail(r);
  }

  Future<void> saveUserAdbPath(String path) async {
    await ref
        .read(sharedPrefsProvider)
        .setString(AppConstants.prefsAdbPath, path.trim());
    _adb.resetAdbCache();
    state = state.copyWith(adbPath: null);
  }

  /// Runs `adb version` on [path]. Returns a user-facing message.
  Future<String> testAdbPath(String path) async {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return 'Enter the path to adb first.';
    final target = Directory(trimmed).existsSync()
        ? p.join(trimmed, AdbLocator.exeName)
        : trimmed;
    state = state.copyWith(isBusy: true);
    final r = await _adb.testAdbPath(target);
    state = state.copyWith(isBusy: false);
    return r.ok
        ? 'OK: ${r.value!.split(RegExp(r'\r?\n')).first}'
        : 'Failed: ${r.message}${r.details.isEmpty ? '' : '\n${r.details}'}';
  }

  Future<void> downloadAdb() async {
    state = state.copyWith(
      isDownloading: true,
      downloadProgress: null,
      error: null,
      info: null,
    );
    final r = await _adb.downloadAdb(
      onProgress: (v) => state = state.copyWith(downloadProgress: v),
    );
    state = state.copyWith(isDownloading: false, downloadProgress: null);
    if (!r.ok) {
      _fail(r);
      return;
    }
    state = state.copyWith(
      adbPath: r.value,
      info: 'ADB downloaded: ${r.value}',
    );
    await refreshDevices();
  }

  // ── Devices ────────────────────────────────────────────────────────────────

  Future<void> refreshDevices() async {
    state = state.copyWith(isBusy: true);
    if (state.adbMissing) await locate();
    if (state.adbMissing) {
      state = state.copyWith(isBusy: false);
      return;
    }
    var r = await _adb.listDevices();
    if (r.ok &&
        !r.value!.any((d) => d.isReady) &&
        lastWirelessTarget.isNotEmpty) {
      final (ip, port) = AdbService.parseTarget(lastWirelessTarget);
      if (ip != null && (await _adb.connectWireless(ip, port)).ok) {
        r = await _adb.listDevices();
      }
    }
    state = state.copyWith(isBusy: false);
    if (!r.ok) {
      _fail(r);
      return;
    }
    _setDevices(r.value!);
  }

  void _setDevices(List<AdbDevice> devices) {
    final ready = devices.where((d) => d.isReady).toList();
    var selected = state.selectedSerial;
    if (!ready.any((d) => d.serial == selected)) {
      selected = ready.length == 1 ? ready.single.serial : null;
    }
    state = state.copyWith(
      devices: devices,
      selectedSerial: selected,
      error: ready.isEmpty ? AdbService.describeDeviceProblem(devices) : null,
      errorStep: ready.isEmpty ? AdbStep.detect : null,
      errorDetails: '',
    );
  }

  Future<void> selectDevice(String? serial) async {
    state = state.copyWith(selectedSerial: serial);
    if (serial != null) {
      await ref
          .read(sharedPrefsProvider)
          .setString(AppConstants.prefsAdbLastSerial, serial);
    }
  }

  Future<void> restartServer() => _busy(() async {
    final r = await _adb.restartServer();
    if (!r.ok) return _fail(r);
    await refreshDevices();
  });

  // ── Wireless ───────────────────────────────────────────────────────────────

  Future<void> connectWireless(String ip, int port) => _busy(() async {
    final r = await _adb.connectWireless(ip, port);
    if (!r.ok) return _fail(r);
    await _saveWireless('${ip.trim()}:$port');
    state = state.copyWith(info: 'Connected to ${ip.trim()}:$port');
    await refreshDevices();
  });

  Future<void> pair(String ip, int pairingPort, String code) => _busy(() async {
    final r = await _adb.pair(ip, pairingPort, code);
    if (!r.ok) return _fail(r);
    state = state.copyWith(
      info:
          'Paired. Now connect using the IP:port shown on the '
          'Wireless debugging screen (not the pairing port).',
    );
  });

  Future<void> switchToWireless() => _busy(() async {
    final serial = state.selectedSerial;
    if (serial == null) return;
    final r = await _adb.switchToWireless(serial);
    if (!r.ok) return _fail(r);
    await _saveWireless(r.value!);
    await selectDevice(r.value);
    state = state.copyWith(
      info: 'Wireless ready at ${r.value}. You can unplug the cable.',
    );
    await refreshDevices();
  });

  // ── Apply ──────────────────────────────────────────────────────────────────

  Future<void> apply() async {
    final mtz = resolveMtzPath();
    state = state.copyWith(
      mtzPath: mtz,
      isRunning: true,
      steps: const {},
      error: null,
      errorStep: null,
      errorDetails: '',
      info: null,
    );
    if (mtz == null) {
      state = state.copyWith(
        isRunning: false,
        error:
            'No exported .mtz found for the current theme. '
            'Use Export or Re-pack MTZ first.',
      );
      return;
    }

    AdbStep? current;
    final r = await _adb.applyToDevice(
      localMtzPath: mtz,
      userAdbPath: userAdbPath,
      preferredSerial: state.selectedSerial,
      lastWirelessTarget: lastWirelessTarget.isEmpty
          ? null
          : lastWirelessTarget,
      cachedActivities: _activityCache,
      onStep: (step) {
        final steps = Map.of(state.steps);
        if (current != null) steps[current!] = StepStatus.done;
        steps[step] = StepStatus.running;
        current = step;
        state = state.copyWith(steps: steps);
      },
    );

    final steps = Map.of(state.steps);
    if (r.ok) {
      for (final s in applySteps) {
        steps[s] = StepStatus.done;
      }
      final outcome = r.value!;
      await _saveActivity(outcome.serial, outcome.activity);
      await selectDevice(outcome.serial);
      final destPath = _adb.destinationPath;
      final info = outcome.isFallback
          ? 'Theme pushed to $destPath.\nThemes app opened on ${outcome.serial}. '
            '(Auto-apply is not supported on HyperOS / modern Theme Manager).'
          : 'Themes app opened on ${outcome.serial}.';
      state = state.copyWith(
        steps: steps,
        isRunning: false,
        adbPath: _adb.adbPath,
        info: info,
      );
      return;
    }

    if (current != null) steps[current!] = StepStatus.failed;
    state = state.copyWith(
      steps: steps,
      isRunning: false,
      adbPath: _adb.adbPath,
    );
    _fail(r);
    if (r.step == AdbStep.detect) {
      final listed = await _adb.listDevices();
      if (listed.ok) {
        state = state.copyWith(devices: listed.value);
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Future<void> _busy(Future<void> Function() action) async {
    state = state.copyWith(isBusy: true, error: null, info: null);
    try {
      await action();
    } finally {
      state = state.copyWith(isBusy: false);
    }
  }

  void _fail(AdbResult<Object?> r) {
    state = state.copyWith(
      error: r.message,
      errorStep: r.step,
      errorDetails: r.details,
    );
  }
}

final applyToDeviceProvider =
    NotifierProvider<ApplyToDeviceNotifier, ApplyToDeviceState>(
      ApplyToDeviceNotifier.new,
    );
