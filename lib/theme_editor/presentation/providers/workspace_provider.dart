import 'package:flutter_riverpod/flutter_riverpod.dart';

enum WorkspacePage {
  dashboard,
  svgEditor,
  lockscreen,
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


