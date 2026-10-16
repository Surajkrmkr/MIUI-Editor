import 'dart:convert';

import 'adb_models.dart';

/// Pure parsers for adb output, kept separate so they can be unit tested.
abstract final class AdbParsers {
  static final RegExp _ws = RegExp(r'\s+');
  static final RegExp _inetAddr = RegExp(r'inet\s+(\d{1,3}(?:\.\d{1,3}){3})/');
  static final RegExp _routeSrc = RegExp(r'\bsrc\s+(\d{1,3}(?:\.\d{1,3}){3})');

  /// Parses `adb devices -l`. Handles both `\n` and `\r\n`.
  static List<AdbDevice> parseDevices(String output) {
    final devices = <AdbDevice>[];
    for (final raw in const LineSplitter().convert(output)) {
      final line = raw.trim();
      if (line.isEmpty ||
          line.startsWith('List of devices') ||
          line.startsWith('*') ||
          line.startsWith('adb server')) {
        continue;
      }
      final parts = line.split(_ws);
      if (parts.length < 2) continue;

      var rawState = parts[1];
      var propsStart = 2;
      // Linux/udev style: "no permissions (...)"
      if (rawState == 'no' && parts.length > 2 && parts[2] == 'permissions') {
        rawState = 'no permissions';
        propsStart = 3;
      }

      final props = <String, String>{};
      for (final token in parts.skip(propsStart)) {
        final i = token.indexOf(':');
        if (i > 0) props[token.substring(0, i)] = token.substring(i + 1);
      }

      devices.add(
        AdbDevice(
          serial: parts[0],
          rawState: rawState,
          state: switch (rawState) {
            'device' => AdbDeviceState.device,
            'unauthorized' => AdbDeviceState.unauthorized,
            'offline' => AdbDeviceState.offline,
            'no permissions' => AdbDeviceState.noPermissions,
            _ => AdbDeviceState.unknown,
          },
          model: props['model'],
          product: props['product'],
          transportId: props['transport_id'],
        ),
      );
    }
    return devices;
  }

  /// IPv4 from `ip -f inet addr show wlan0`.
  static String? parseInetAddr(String output) =>
      _inetAddr.firstMatch(output)?.group(1);

  /// IPv4 from `ip route`, preferring wlan interfaces.
  static String? parseRouteSrc(String output) {
    final lines = const LineSplitter().convert(output);
    for (final line in lines.where((l) => l.contains('wlan'))) {
      final m = _routeSrc.firstMatch(line);
      if (m != null) return m.group(1);
    }
    for (final line in lines) {
      final m = _routeSrc.firstMatch(line);
      if (m != null) return m.group(1);
    }
    return null;
  }

  /// True when `am start` reported that the activity could not be started.
  static bool amStartFailed(String output) =>
      output.contains('Error') ||
      output.contains('does not exist') ||
      output.contains('Exception');

  /// True when `dumpsys package` lists the activity in any known form.
  static bool dumpsysHasActivity(String dumpsys, ApplyActivity activity) =>
      activity.dumpsysForms.any(
        (form) => RegExp(
          '(?:^|\\s)${RegExp.escape(form)}(?=\\s|\$)',
          multiLine: true,
        ).hasMatch(dumpsys),
      );

  /// True when `adb connect` output indicates success.
  static bool connectSucceeded(String output) {
    final lower = output.toLowerCase();
    return lower.contains('connected to') &&
        !lower.contains('cannot') &&
        !lower.contains('failed') &&
        !lower.contains('unable');
  }

  /// True when `adb pair` output indicates success.
  static bool pairSucceeded(String output) =>
      output.toLowerCase().contains('successfully paired');

  /// True when `ls -l` output shows [devicePath] with [expectedSize] bytes.
  static bool lsShowsFile(String output, String devicePath, int expectedSize) {
    if (output.contains('No such file') || !output.contains(devicePath)) {
      return false;
    }
    return output.split(_ws).contains(expectedSize.toString());
  }
}
