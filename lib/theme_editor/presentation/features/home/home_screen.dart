import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/wallpaper_provider.dart';
import 'workspace_shell.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    required this.folderNum,
    required this.weekNum,
    this.loadOnStart = true,
  });
  final String folderNum;
  final String weekNum;

  /// False when the theme was already opened, e.g. from a spec file.
  final bool loadOnStart;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    if (!widget.loadOnStart) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(wallpaperProvider.notifier)
          .loadFolder(widget.folderNum, widget.weekNum);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const WorkspaceShell();
  }
}
