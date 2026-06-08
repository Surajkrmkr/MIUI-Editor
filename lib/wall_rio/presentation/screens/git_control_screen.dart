import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../application/providers/git_provider.dart';
import '../widgets/sidebar.dart';

class GitControlScreen extends ConsumerStatefulWidget {
  const GitControlScreen({super.key});

  @override
  ConsumerState<GitControlScreen> createState() => _GitControlScreenState();
}

class _GitControlScreenState extends ConsumerState<GitControlScreen> {
  final _commitController = TextEditingController();

  @override
  void dispose() {
    _commitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gitStatus = ref.watch(gitStateProvider);
    final activeTarget = ref.watch(activeGitTargetProvider);
    final colors = context.appColors;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Source Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(gitStateProvider.notifier).refresh(),
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _handlePull(),
            tooltip: 'Pull',
          ),
          IconButton(
            icon: const Icon(Icons.upload),
            onPressed: () => _handlePush(),
            tooltip: 'Push',
          ),
        ],
      ),
      drawer: const Sidebar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  _buildTargetBtn('JSON Data', GitRepoTarget.json, activeTarget == GitRepoTarget.json),
                  _buildTargetBtn('Wallpapers', GitRepoTarget.wallpapers, activeTarget == GitRepoTarget.wallpapers),
                ],
              ),
            ),
          ),
          Expanded(
            child: gitStatus.when(
              data: (status) {
                if (status == null || !status.isRepository) {
                  return const Center(
                    child: Text('Not a git repository or no file opened.'),
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commitController,
                              decoration: const InputDecoration(
                                hintText: 'Commit message',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _commitController.text.trim().isEmpty 
                                ? null 
                                : () => _handleCommit(),
                            child: const Text('Commit'),
                          ),
                        ],
                      ),
                    ),
                    if (status.ahead > 0 || status.behind > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            if (status.behind > 0)
                              Chip(
                                avatar: const Icon(Icons.arrow_downward, size: 16),
                                label: Text('${status.behind} behind'),
                              ),
                            const SizedBox(width: 8),
                            if (status.ahead > 0)
                              Chip(
                                avatar: const Icon(Icons.arrow_upward, size: 16),
                                label: Text('${status.ahead} ahead'),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView(
                        children: [
                          if (status.stagedFiles.isNotEmpty) ...[
                            _SectionHeader(
                              title: 'STAGED CHANGES',
                              count: status.stagedFiles.length,
                              onAction: () => ref.read(gitStateProvider.notifier).unstageAll(),
                              actionIcon: Icons.remove,
                              actionTooltip: 'Unstage All',
                            ),
                            ...status.stagedFiles.map((f) => _FileItem(
                                  path: f,
                                  isStaged: true,
                                  onAction: () => ref.read(gitStateProvider.notifier).unstageFile(f),
                                )),
                          ],
                          if (status.modifiedFiles.isNotEmpty) ...[
                            _SectionHeader(
                              title: 'CHANGES',
                              count: status.modifiedFiles.length,
                              onAction: () => ref.read(gitStateProvider.notifier).stageAll(),
                              actionIcon: Icons.add,
                              actionTooltip: 'Stage All',
                            ),
                            ...status.modifiedFiles.map((f) => _FileItem(
                                  path: f,
                                  isStaged: false,
                                  onAction: () => ref.read(gitStateProvider.notifier).stageFile(f),
                                )),
                          ],
                          if (status.untrackedFiles.isNotEmpty) ...[
                            _SectionHeader(
                              title: 'UNTRACKED',
                              count: status.untrackedFiles.length,
                              onAction: () => ref.read(gitStateProvider.notifier).stageAll(),
                              actionIcon: Icons.add,
                              actionTooltip: 'Stage All',
                            ),
                            ...status.untrackedFiles.map((f) => _FileItem(
                                  path: f,
                                  isStaged: false,
                                  onAction: () => ref.read(gitStateProvider.notifier).stageFile(f),
                                )),
                          ],
                          if (status.stagedFiles.isEmpty && 
                              status.modifiedFiles.isEmpty && 
                              status.untrackedFiles.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(32.0),
                                child: Text('No changes detected.'),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetBtn(String label, GitRepoTarget target, bool isSelected) {
    final colors = context.appColors;
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(activeGitTargetProvider.notifier).set(target),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? colors.primarySelection : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? colors.primary : colors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCommit() async {
    final message = _commitController.text.trim();
    final result = await ref.read(gitStateProvider.notifier).commit(message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      if (result.success) {
        _commitController.clear();
      }
    }
  }

  Future<void> _handlePush() async {
    final result = await ref.read(gitStateProvider.notifier).push();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }

  Future<void> _handlePull() async {
    final result = await ref.read(gitStateProvider.notifier).pull();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final VoidCallback onAction;
  final IconData actionIcon;
  final String actionTooltip;

  const _SectionHeader({
    required this.title,
    required this.count,
    required this.onAction,
    required this.actionIcon,
    required this.actionTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          IconButton(
            icon: Icon(actionIcon, size: 16),
            onPressed: onAction,
            tooltip: actionTooltip,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _FileItem extends StatelessWidget {
  final String path;
  final bool isStaged;
  final VoidCallback onAction;

  const _FileItem({
    required this.path,
    required this.isStaged,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isStaged ? Icons.check_circle_outline : Icons.fiber_manual_record,
        size: 16,
        color: isStaged ? Colors.green : Colors.blue,
      ),
      title: Text(path, style: const TextStyle(fontSize: 14)),
      trailing: IconButton(
        icon: Icon(isStaged ? Icons.remove : Icons.add, size: 20),
        onPressed: onAction,
        tooltip: isStaged ? 'Unstage' : 'Stage',
      ),
      dense: true,
    );
  }
}
