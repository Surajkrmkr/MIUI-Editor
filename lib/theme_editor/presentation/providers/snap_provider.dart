import 'package:flutter_riverpod/flutter_riverpod.dart';

class SnapGuide {
  const SnapGuide({this.lineX, this.lineY});

  /// Canvas X-coordinate for the vertical snap guide (null = hidden).
  final double? lineX;

  /// Canvas Y-coordinate for the horizontal snap guide (null = hidden).
  final double? lineY;

  bool get hasGuides => lineX != null || lineY != null;
}

class SnapGuideNotifier extends Notifier<SnapGuide> {
  @override
  SnapGuide build() => const SnapGuide();

  void show({double? lineX, double? lineY}) =>
      state = SnapGuide(lineX: lineX, lineY: lineY);

  void clear() => state = const SnapGuide();
}

final snapGuideProvider =
    NotifierProvider<SnapGuideNotifier, SnapGuide>(SnapGuideNotifier.new);
