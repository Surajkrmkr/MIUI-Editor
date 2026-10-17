import 'dart:io';

import 'package:path/path.dart' as path;

import '../layout/theme_layout.dart';

/// Names and expected outputs of the modules inside a theme.
abstract final class ThemeModules {
  /// HyperOS 3 system app modules generated from the style.
  static const system = [
    'miui.systemui.plugin',
    'com.android.systemui',
    'com.android.contacts',
    'com.android.mms',
    'com.android.settings',
  ];

  /// Every module directory that gets zipped into the `.mtz`, in pack order.
  static const packed = ['icons', 'clock_2x4', 'lockscreen', ...system];

  /// Relative to a system module directory.
  static const drawableDir = 'res/drawable-xxhdpi/';

  /// One key file per module; missing means the render stopped half way.
  static const _requiredDrawable = {
    'miui.systemui.plugin': 'qs_background_enabled.png',
    'com.android.systemui': 'notification_item_bg.9.png',
    'com.android.mms': 'miuix_appcompat_action_button_main_new.png',
    'com.android.settings': 'ic_wifi_settings.png',
  };

  /// Key generated files absent from [layout]; used to reject half-written
  /// themes before packing.
  static List<String> missingOutputs(ThemeLayout layout) => [
    for (final m in system) ...[
      if (!File(path.join(layout.module(m), 'theme_values.xml')).existsSync())
        '$m/theme_values.xml',
      if (_requiredDrawable[m] case final f?
          when !File(path.join(layout.moduleDrawables(m), f)).existsSync())
        '$m/$drawableDir$f',
    ],
  ];
}
