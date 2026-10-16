import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_constants.dart';
import 'service_providers.dart';

enum WorkspacePage {
  dashboard,
  svgEditor,
  lockscreen,
  lockscreenPresets, // Preset browser while staying on the lockscreen canvas
  icons, // Retaining for compatibility with existing logic
  export,
  home, // Alias for dashboard or retained for compatibility
}

enum UiMode {
  classic,
  pro,
}

enum InspectorTab {
  design,
  effects,
  textures,
}

class WorkspaceState {
  final WorkspacePage page;
  final UiMode uiMode;
  final bool isSidebarExpanded;
  final InspectorTab activeInspectorTab;

  WorkspaceState({
    required this.page,
    required this.uiMode,
    this.isSidebarExpanded = true,
    this.activeInspectorTab = InspectorTab.design,
  });

  WorkspaceState copyWith({
    WorkspacePage? page,
    UiMode? uiMode,
    bool? isSidebarExpanded,
    InspectorTab? activeInspectorTab,
  }) {
    return WorkspaceState(
      page: page ?? this.page,
      uiMode: uiMode ?? this.uiMode,
      isSidebarExpanded: isSidebarExpanded ?? this.isSidebarExpanded,
      activeInspectorTab: activeInspectorTab ?? this.activeInspectorTab,
    );
  }
}

class WorkspaceNotifier extends Notifier<WorkspaceState> {
  @override
  WorkspaceState build() => WorkspaceState(
        page: WorkspacePage.svgEditor,
        uiMode: UiMode.pro,
      );

  void setPage(WorkspacePage page) => state = state.copyWith(page: page);
  void setUiMode(UiMode mode) => state = state.copyWith(uiMode: mode);
  void toggleUiMode() => state = state.copyWith(
        uiMode: state.uiMode == UiMode.classic ? UiMode.pro : UiMode.classic,
      );
  void toggleSidebar() => state = state.copyWith(isSidebarExpanded: !state.isSidebarExpanded);
  void setInspectorTab(InspectorTab tab) => state = state.copyWith(activeInspectorTab: tab);
}

final workspaceProvider =
    NotifierProvider<WorkspaceNotifier, WorkspaceState>(WorkspaceNotifier.new);

class CanvasLockNotifier extends Notifier<bool> {
  @override
  bool build() {
    try {
      final prefs = ref.watch(sharedPrefsProvider);
      return prefs.getBool(AppConstants.prefsCanvasLock) ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> toggle() async {
    final next = !state;
    state = next;
    try {
      final prefs = ref.read(sharedPrefsProvider);
      await prefs.setBool(AppConstants.prefsCanvasLock, next);
    } catch (_) {}
  }

  Future<void> setLocked(bool locked) async {
    if (state == locked) return;
    state = locked;
    try {
      final prefs = ref.read(sharedPrefsProvider);
      await prefs.setBool(AppConstants.prefsCanvasLock, locked);
    } catch (_) {}
  }
}

final canvasLockProvider =
    NotifierProvider<CanvasLockNotifier, bool>(CanvasLockNotifier.new);


