import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../application/providers/git_provider.dart';

class GitPanel extends ConsumerStatefulWidget {
  const GitPanel({super.key});

  @override
  ConsumerState<GitPanel> createState() => _GitPanelState();
}

class _GitPanelState extends ConsumerState<GitPanel>
    with SingleTickerProviderStateMixin {
  final _commitController = TextEditingController();
  late final AnimationController _spinAnim;

  @override
  void initState() {
    super.initState();
    _spinAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _commitController.dispose();
    _spinAnim.dispose();
    super.dispose();
  }

  void _refresh() {
    if (!_spinAnim.isAnimating) {
      _spinAnim.repeat();
      ref.read(gitStateProvider.notifier).refresh();
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          _spinAnim.stop();
          _spinAnim.reset();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gitStatus = ref.watch(gitStateProvider);
    final activeTarget = ref.watch(activeGitTargetProvider);
    final colors = context.appColors;

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: colors.bg,
        border: Border(left: BorderSide(color: colors.borderSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(colors),
          _buildTargetSelector(activeTarget, colors),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: gitStatus.when(
                data: (status) {
                  if (status == null) {
                    return _buildEmptyState(
                      Icons.folder_off_outlined,
                      'No repository configured.\nOpen a file or set a path in settings.',
                      colors,
                      key: const ValueKey('no-repo'),
                    );
                  }
                  if (!status.isRepository) {
                    return _buildEmptyState(
                      Icons.commit,
                      'Not a git repository.',
                      colors,
                      key: const ValueKey('not-repo'),
                    );
                  }
                  return _buildStatusContent(status, colors,
                      key: const ValueKey('content'));
                },
                loading: () => const Center(
                  key: ValueKey('loading'),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (err, _) => _buildEmptyState(
                  Icons.error_outline_rounded,
                  'Error: $err',
                  colors,
                  key: const ValueKey('error'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.source_rounded, color: colors.primary, size: 15),
          ),
          const SizedBox(width: 10),
          Text(
            'SOURCE CONTROL',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.2,
              color: colors.textPrimary,
            ),
          ),
          const Spacer(),
          RotationTransition(
            turns: _spinAnim,
            child: IconButton(
              icon: Icon(Icons.refresh_rounded, size: 16, color: colors.textSecondary),
              onPressed: _refresh,
              tooltip: 'Refresh',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetSelector(GitRepoTarget active, AppColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REPOSITORY TARGET',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: colors.textSecondary,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 36,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: colors.borderSubtle),
            ),
            child: Row(
              children: [
                _buildTargetBtn(
                  'JSON Data', Icons.description_rounded,
                  GitRepoTarget.json, active == GitRepoTarget.json, colors,
                  isLeft: true,
                ),
                Container(width: 1, height: 20, color: colors.borderSubtle),
                _buildTargetBtn(
                  'Wallpapers', Icons.image_rounded,
                  GitRepoTarget.wallpapers, active == GitRepoTarget.wallpapers, colors,
                  isLeft: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetBtn(
    String label,
    IconData icon,
    GitRepoTarget target,
    bool isSelected,
    AppColorScheme colors, {
    required bool isLeft,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () => ref.read(activeGitTargetProvider.notifier).set(target),
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(9) : Radius.zero,
          right: isLeft ? Radius.zero : const Radius.circular(9),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? colors.primarySelection : Colors.transparent,
            borderRadius: BorderRadius.horizontal(
              left: isLeft ? const Radius.circular(9) : Radius.zero,
              right: isLeft ? Radius.zero : const Radius.circular(9),
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? colors.primary : colors.textSecondary,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? colors.primary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    IconData icon,
    String message,
    AppColorScheme colors, {
    Key? key,
  }) {
    return Center(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: colors.textDisabled),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusContent(dynamic status, AppColorScheme colors, {Key? key}) {
    final totalChanges = (status.stagedFiles as List).length +
        (status.modifiedFiles as List).length +
        (status.untrackedFiles as List).length;
    final hasChanges = totalChanges > 0;

    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Commit card ──────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'COMMIT MESSAGE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _commitController,
                    style: const TextStyle(fontSize: 12.5),
                    decoration: InputDecoration(
                      hintText: 'Add a message...',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 6),
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: colors.textDisabled,
                        fontSize: 12.5,
                      ),
                    ),
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 36,
                    child: FilledButton.icon(
                      onPressed:
                          _commitController.text.trim().isEmpty ? null : _handleCommit,
                      icon: const Icon(Icons.check_rounded, size: 15),
                      label: Text(
                        hasChanges
                            ? 'Commit ($totalChanges)'
                            : 'Commit',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handlePull,
                          icon: const Icon(Icons.download_rounded, size: 14),
                          label: const Text('Pull', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _handlePush,
                          icon: const Icon(Icons.upload_rounded, size: 14),
                          label: const Text('Push', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Changed files list ───────────────────────────────────────────────
        Expanded(
          child: ListView(
            padding: const EdgeInsets.only(bottom: 16),
            children: [
              if ((status.stagedFiles as List).isNotEmpty)
                _buildSection(
                  'Staged Changes',
                  status.stagedFiles as List<String>,
                  _FileStatus.staged,
                  colors,
                ),
              if ((status.modifiedFiles as List).isNotEmpty)
                _buildSection(
                  'Modified',
                  status.modifiedFiles as List<String>,
                  _FileStatus.modified,
                  colors,
                ),
              if ((status.untrackedFiles as List).isNotEmpty)
                _buildSection(
                  'Untracked',
                  status.untrackedFiles as List<String>,
                  _FileStatus.untracked,
                  colors,
                ),
              if (!hasChanges)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: colors.success, size: 28),
                      const SizedBox(height: 8),
                      Text(
                        'No changes',
                        style: TextStyle(color: colors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    String title,
    List<String> files,
    _FileStatus status,
    AppColorScheme colors,
  ) {
    final (statusColor, sectionIcon, actionIcon) = switch (status) {
      _FileStatus.staged => (
          colors.success,
          Icons.check_circle_rounded,
          Icons.remove_rounded,
        ),
      _FileStatus.modified => (
          colors.warning,
          Icons.edit_rounded,
          Icons.add_rounded,
        ),
      _FileStatus.untracked => (
          const Color(0xFF74B9FF),
          Icons.fiber_new_rounded,
          Icons.add_rounded,
        ),
    };
    final isStaged = status == _FileStatus.staged;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Row(
            children: [
              Icon(sectionIcon, size: 12, color: statusColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(35),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${files.length}',
                  style: TextStyle(
                    fontSize: 9,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        // File items
        ...files.take(20).map(
              (f) => _FileItem(
                file: f,
                statusColor: statusColor,
                actionIcon: actionIcon,
                isStaged: isStaged,
                onAction: () => isStaged
                    ? ref.read(gitStateProvider.notifier).unstageFile(f)
                    : ref.read(gitStateProvider.notifier).stageFile(f),
              ),
            ),
        if (files.length > 20)
          Padding(
            padding: const EdgeInsets.only(left: 24, bottom: 4),
            child: Text(
              '... and ${files.length - 20} more',
              style: TextStyle(fontSize: 10, color: colors.textDisabled),
            ),
          ),
        const SizedBox(height: 4),
      ],
    );
  }

  Future<void> _handleCommit() async {
    final message = _commitController.text.trim();
    final result = await ref.read(gitStateProvider.notifier).commit(message);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
      if (result.success) {
        _commitController.clear();
        setState(() {});
      }
    }
  }

  Future<void> _handlePush() async {
    final result = await ref.read(gitStateProvider.notifier).push();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  Future<void> _handlePull() async {
    final result = await ref.read(gitStateProvider.notifier).pull();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.message)));
    }
  }
}

// =============================================================================
// File status enum
// =============================================================================

enum _FileStatus { staged, modified, untracked }

// =============================================================================
// Individual file row widget
// =============================================================================

class _FileItem extends StatelessWidget {
  const _FileItem({
    required this.file,
    required this.statusColor,
    required this.actionIcon,
    required this.isStaged,
    required this.onAction,
  });

  final String file;
  final Color statusColor;
  final IconData actionIcon;
  final bool isStaged;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fileName = file.contains('/') ? file.split('/').last : file;
    final dirPart = file.contains('/')
        ? file.substring(0, file.lastIndexOf('/'))
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        fileName,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (dirPart != null)
                        Text(
                          dirPart,
                          style: TextStyle(
                            fontSize: 10,
                            color: colors.textDisabled,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Tooltip(
                  message: isStaged ? 'Unstage' : 'Stage',
                  child: InkWell(
                    onTap: onAction,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        actionIcon,
                        size: 14,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
