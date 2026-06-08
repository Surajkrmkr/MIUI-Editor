import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/git_provider.dart';

class GitPanel extends ConsumerStatefulWidget {
  const GitPanel({super.key});

  @override
  ConsumerState<GitPanel> createState() => _GitPanelState();
}

class _GitPanelState extends ConsumerState<GitPanel> {
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

    return Container(
      width: 320,
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        border: Border(left: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTargetSelector(activeTarget),
          Expanded(
            child: gitStatus.when(
              data: (status) {
                if (status == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text(
                        'Path not configured or no file opened.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  );
                }
                if (!status.isRepository) {
                  return const Center(
                    child: Text('Not a git repository.', style: TextStyle(color: Colors.grey)),
                  );
                }
                return _buildStatusContent(status);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelector(GitRepoTarget active) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REPOSITORY TARGET',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1),
          ),
          const SizedBox(height: 8),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                _buildTargetBtn('JSON Data', GitRepoTarget.json, active == GitRepoTarget.json),
                _buildTargetBtn('Wallpapers', GitRepoTarget.wallpapers, active == GitRepoTarget.wallpapers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetBtn(String label, GitRepoTarget target, bool isSelected) {
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(activeGitTargetProvider.notifier).set(target),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.purpleAccent.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected ? Border.all(color: Colors.purpleAccent.withValues(alpha: 0.4)) : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                target == GitRepoTarget.json ? Icons.description : Icons.image,
                size: 14,
                color: isSelected ? Colors.purpleAccent : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.source, color: Colors.purpleAccent, size: 20),
          const SizedBox(width: 8),
          const Text(
            'SOURCE CONTROL',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            onPressed: () => ref.read(gitStateProvider.notifier).refresh(),
            tooltip: 'Refresh',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusContent(status) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              TextField(
                controller: _commitController,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Commit message...',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _commitController.text.trim().isEmpty ? null : _handleCommit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purpleAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Commit'),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handlePull,
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Pull', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handlePush,
                      icon: const Icon(Icons.upload, size: 16),
                      label: const Text('Push', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 32),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              if (status.stagedFiles.isNotEmpty)
                _buildSection('Staged', status.stagedFiles, true),
              if (status.modifiedFiles.isNotEmpty)
                _buildSection('Modified', status.modifiedFiles, false),
              if (status.untrackedFiles.isNotEmpty)
                _buildSection('Untracked', status.untrackedFiles, false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> files, bool isStaged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Text(
            '$title (${files.length})',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        ...files.take(20).map((f) => ListTile(
          title: Text(f, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: IconButton(
            icon: Icon(isStaged ? Icons.remove : Icons.add, size: 16),
            onPressed: () => isStaged 
                ? ref.read(gitStateProvider.notifier).unstageFile(f)
                : ref.read(gitStateProvider.notifier).stageFile(f),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          dense: true,
          visualDensity: VisualDensity.compact,
        )),
        if (files.length > 20)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text('... and ${files.length - 20} more', style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ),
      ],
    );
  }

  Future<void> _handleCommit() async {
    final message = _commitController.text.trim();
    final result = await ref.read(gitStateProvider.notifier).commit(message);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      if (result.success) _commitController.clear();
    }
  }

  Future<void> _handlePush() async {
    final result = await ref.read(gitStateProvider.notifier).push();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
  }

  Future<void> _handlePull() async {
    final result = await ref.read(gitStateProvider.notifier).pull();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
  }
}
