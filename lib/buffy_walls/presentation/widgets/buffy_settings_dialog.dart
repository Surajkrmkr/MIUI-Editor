import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../application/providers/buffy_settings_provider.dart';
import '../../application/providers/buffy_cms_provider.dart';
import '../../application/providers/buffy_credentials_provider.dart';
import '../../application/providers/buffy_analytics_provider.dart';
import '../../domain/models/buffy_credential_models.dart';
import '../../infrastructure/services/buffy_settings_service.dart';

class BuffySettingsDialog extends ConsumerStatefulWidget {
  const BuffySettingsDialog({super.key});

  @override
  ConsumerState<BuffySettingsDialog> createState() => _BuffySettingsDialogState();
}

class _BuffySettingsDialogState extends ConsumerState<BuffySettingsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 660),
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: cs.outline.withValues(alpha: 0.2))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings_rounded, color: context.appColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'BuffyWalls Settings',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabCtrl,
                    tabs: const [
                      Tab(icon: Icon(Icons.folder_special_rounded, size: 16), text: 'Project'),
                      Tab(icon: Icon(Icons.vpn_key_rounded, size: 16), text: 'Credentials'),
                      Tab(icon: Icon(Icons.analytics_rounded, size: 16), text: 'Analytics'),
                    ],
                    labelColor: cs.primary,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    indicatorColor: cs.primary,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _ProjectTab(),
                  _CredentialsTab(),
                  _AnalyticsTab(),
                ],
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: cs.outline.withValues(alpha: 0.15))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Done'),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Tab — Project
// =============================================================================

class _ProjectTab extends ConsumerWidget {
  const _ProjectTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(buffySettingsProvider);
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'BuffyWalls Project Paths',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Configure the local repository and JSON data file.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              _LabeledField(
                label: 'Local Repo Path',
                child: _PickerField(
                  value: settings.localRepoPath,
                  hint: 'Select directory...',
                  onPick: () async {
                    String? result = await FilePicker.platform.getDirectoryPath();
                    if (result != null) {
                      ref.read(buffySettingsProvider.notifier).setLocalRepoPath(result);
                    }
                  },
                ),
              ),
              const SizedBox(height: 20),
              _LabeledField(
                label: 'JSON File Path',
                child: _PickerField(
                  value: settings.jsonFilePath,
                  hint: 'Select buffy.json...',
                  onPick: () async {
                    FilePickerResult? result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['json'],
                    );
                    if (result != null && result.files.single.path != null) {
                      final path = result.files.single.path!;
                      ref.read(buffySettingsProvider.notifier).setJsonFilePath(path);
                      ref.read(buffyCmsProvider.notifier).loadFile(path);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Tab — Credentials
// =============================================================================

class _CredentialsTab extends ConsumerStatefulWidget {
  const _CredentialsTab();

  @override
  ConsumerState<_CredentialsTab> createState() => _CredentialsTabState();
}

class _CredentialsTabState extends ConsumerState<_CredentialsTab> {
  final _clientIdCtrl = TextEditingController();
  final _clientSecretCtrl = TextEditingController();
  final _fcmProjectIdCtrl = TextEditingController();
  bool _loaded = false;
  bool _showSecret = false;
  bool _savingOAuth = false;
  bool _signingIn = false;

  @override
  void dispose() {
    _clientIdCtrl.dispose();
    _clientSecretCtrl.dispose();
    _fcmProjectIdCtrl.dispose();
    super.dispose();
  }

  void _load(BuffyCredentialStatus status) {
    if (_loaded) return;
    _loaded = true;
    _clientIdCtrl.text = status.clientId ?? '';
    _clientSecretCtrl.text = status.clientSecret ?? '';
    _fcmProjectIdCtrl.text = status.firebaseProjectId ?? '';
  }

  Future<void> _saveOAuth(BuildContext context) async {
    setState(() => _savingOAuth = true);
    try {
      await ref.read(buffyCredentialsProvider.notifier).saveConfig(
            clientId: _clientIdCtrl.text.trim(),
            clientSecret: _clientSecretCtrl.text.trim(),
            projectId: _fcmProjectIdCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Buffy OAuth configuration saved')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingOAuth = false);
    }
  }

  Future<void> _handleSignIn(BuildContext context) async {
    setState(() => _signingIn = true);
    try {
      final success = await ref.read(buffyCredentialsProvider.notifier).signIn();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success ? 'Signed in with Google (Buffy)' : 'Sign-in failed'),
          backgroundColor: success ? null : Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final credState = ref.watch(buffyCredentialsProvider);
    final cs = Theme.of(context).colorScheme;

    return credState.when(
      data: (status) {
        Future.microtask(() => _load(status));
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Google OAuth (Buffy)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Provide Buffy-specific OAuth credentials.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    _LabeledField(
                      label: 'Client ID',
                      child: TextField(
                        controller: _clientIdCtrl,
                        decoration: const InputDecoration(hintText: 'OAuth Client ID'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LabeledField(
                      label: 'Client Secret',
                      child: TextField(
                        controller: _clientSecretCtrl,
                        obscureText: !_showSecret,
                        decoration: InputDecoration(
                          hintText: 'OAuth Client Secret',
                          suffixIcon: IconButton(
                            icon: Icon(_showSecret ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                            onPressed: () => setState(() => _showSecret = !_showSecret),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LabeledField(
                      label: 'FCM Project ID',
                      child: TextField(
                        controller: _fcmProjectIdCtrl,
                        decoration: const InputDecoration(hintText: 'Firebase project ID'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        icon: _savingOAuth
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(_savingOAuth ? 'Saving…' : 'Save OAuth Configuration'),
                        onPressed: _savingOAuth ? null : () => _saveOAuth(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Service Accounts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.primary),
                    ),
                    const SizedBox(height: 16),
                    _ServiceAccountRow(
                      title: 'Google Cloud (Buffy)',
                      isSignedIn: status.isSignedIn,
                      disabled: status.clientId?.isEmpty ?? true,
                      loading: _signingIn,
                      onConnect: () => _handleSignIn(context),
                    ),
                    if (status.isSignedIn) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => ref.read(buffyCredentialsProvider.notifier).clearAll(),
                          icon: Icon(Icons.delete_forever_rounded, color: cs.error),
                          label: Text('Sign Out & Clear All Data', style: TextStyle(color: cs.error)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

// =============================================================================
// Tab — Analytics
// =============================================================================

class _AnalyticsTab extends ConsumerStatefulWidget {
  const _AnalyticsTab();

  @override
  ConsumerState<_AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends ConsumerState<_AnalyticsTab> {
  final _pubIdCtrl = TextEditingController();
  final _pkgNameCtrl = TextEditingController();
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(buffySettingsProvider);
    _pubIdCtrl.text = settings.admobPublisherId;
    _pkgNameCtrl.text = settings.playPackageName;
  }

  @override
  void dispose() {
    _pubIdCtrl.dispose();
    _pkgNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAndRefresh(BuildContext context) async {
    setState(() => _refreshing = true);
    try {
      await ref.read(buffySettingsProvider.notifier).setAdMobPublisherId(_pubIdCtrl.text.trim());
      await ref.read(buffySettingsProvider.notifier).setPlayPackageName(_pkgNameCtrl.text.trim());
      
      final creds = await ref.read(buffyCredentialsProvider.future);
      if (creds.isSignedIn) {
        await ref.read(buffyAnalyticsStateProvider.notifier).refresh();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Buffy Analytics targets saved')));
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Analytics Targets (Buffy)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: cs.primary),
                ),
                const SizedBox(height: 20),
                _LabeledField(
                  label: 'AdMob Publisher ID',
                  child: TextField(
                    controller: _pubIdCtrl,
                    decoration: const InputDecoration(hintText: 'pub-XXXX for all, or ca-app-pub-XXXX~YYYY'),
                  ),
                ),
                const SizedBox(height: 14),
                _LabeledField(
                  label: 'Play Package Name',
                  child: TextField(
                    controller: _pkgNameCtrl,
                    decoration: const InputDecoration(hintText: 'com.buffy.walls'),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 44,
                  child: FilledButton.icon(
                    icon: _refreshing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.sync_rounded, size: 18),
                    label: Text(_refreshing ? 'Refreshing…' : 'Save & Refresh Analytics'),
                    onPressed: _refreshing ? null : () => _saveAndRefresh(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Helper Widgets (mirrored from WallRio settings)
// =============================================================================

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: context.appColors.textSecondary)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.value, required this.hint, required this.onPick});
  final String value;
  final String hint;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            child: Text(
              value.isEmpty ? hint : value,
              style: TextStyle(color: value.isEmpty ? Colors.white38 : Colors.white, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.outlined(onPressed: onPick, icon: const Icon(Icons.folder_open_rounded, size: 18)),
      ],
    );
  }
}

class _ServiceAccountRow extends StatelessWidget {
  const _ServiceAccountRow({required this.title, required this.isSignedIn, required this.disabled, required this.onConnect, this.loading = false});
  final String title;
  final bool isSignedIn;
  final bool disabled;
  final bool loading;
  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: colors.bgSubtle, borderRadius: BorderRadius.circular(10), border: Border.all(color: colors.borderSubtle)),
      child: Row(
        children: [
          Icon(isSignedIn ? Icons.lock_open_rounded : Icons.lock_outline_rounded, color: Colors.orangeAccent, size: 16),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
          OutlinedButton.icon(
            onPressed: (disabled || loading) ? null : onConnect,
            icon: loading ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)) : Icon(isSignedIn ? Icons.sync_rounded : Icons.login_rounded, size: 14),
            label: Text(loading ? 'Connecting…' : isSignedIn ? 'Switch' : 'Connect', style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
