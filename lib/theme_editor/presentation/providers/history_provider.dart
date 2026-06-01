import 'package:flutter_riverpod/flutter_riverpod.dart';

class HistoryItem {
  final String action;
  final DateTime timestamp;
  final String? details;

  HistoryItem({
    required this.action,
    required this.timestamp,
    this.details,
  });
}

class HistoryNotifier extends Notifier<List<HistoryItem>> {
  @override
  List<HistoryItem> build() => [
    HistoryItem(action: 'Project Created', timestamp: DateTime.now().subtract(const Duration(minutes: 10))),
    HistoryItem(action: 'Imported Wallpaper', timestamp: DateTime.now().subtract(const Duration(minutes: 5)), details: 'wall.png'),
  ];

  void addAction(String action, {String? details}) {
    state = [
      HistoryItem(action: action, timestamp: DateTime.now(), details: details),
      ...state,
    ];
  }

  void clear() => state = [];
}

final historyProvider = NotifierProvider<HistoryNotifier, List<HistoryItem>>(HistoryNotifier.new);
