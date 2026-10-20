import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/spec_provider.dart';
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
    ref.watch(themeSpecAutoSaveProvider);
    final busy =
        ref.watch(themeOpeningProvider) ||
        ref.watch(wallpaperProvider.select((s) => s.isLoading));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmLeave()) navigator.pop();
      },
      child: Stack(
        children: [
          const WorkspaceShell(),
          if (busy) const Positioned.fill(child: _OpeningOverlay()),
        ],
      ),
    );
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Leave the designer?'),
        content: const Text(
          'Your design is saved to the theme\'s spec, so you can pick up '
          'where you left off.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }
}

class _OpeningOverlay extends StatelessWidget {
  const _OpeningOverlay();

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Opening theme…',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
