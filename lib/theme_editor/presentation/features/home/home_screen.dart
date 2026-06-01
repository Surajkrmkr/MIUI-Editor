import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/wallpaper_provider.dart';
import 'workspace_shell.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.folderNum, required this.weekNum});
  final String folderNum;
  final String weekNum;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
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
