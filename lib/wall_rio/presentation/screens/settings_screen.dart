import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import '../../application/providers/analytics_provider.dart';
import '../../application/providers/catalog_provider.dart';
import '../../application/providers/credentials_provider.dart';
import '../../domain/models/catalog.dart';
import '../../domain/models/credential_models.dart';
import '../../infrastructure/services/app_settings_service.dart';

// ── Public entry point ────────────────────────────────────────────────────────

Future<void> showWallRioSettings(BuildContext context) => showDialog(
      context: context,
      builder: (_) => const _WallRioSettingsDialog(),
    );

// ── SettingsScreen (kept for GoRouter /settings route compat) ─────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showWallRioSettings(context).then((_) {
        if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      });
    });
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// =============================================================================
// Dialog shell
// =============================================================================

class _WallRioSettingsDialog extends ConsumerStatefulWidget {
  const _WallRioSettingsDialog();

  @override
  ConsumerState<_WallRioSettingsDialog> createState() =>
      _WallRioSettingsDialogState();
}

class _WallRioSettingsDialogState extends ConsumerState<_WallRioSettingsDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
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
                color: cs.primary.withAlpha(20),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                border:
                    Border(bottom: BorderSide(color: cs.outline.withAlpha(40))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings_rounded,
                          color: context.appColors.primary),
                      const SizedBox(width: 12),
                      Text(
                        'WallRio Settings',
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
                      Tab(
                          icon: Icon(Icons.cloud_rounded, size: 16),
                          text: 'Storage'),
                      Tab(
                          icon: Icon(Icons.vpn_key_rounded, size: 16),
                          text: 'Credentials'),
                    ],
                    labelColor: cs.primary,
                    unselectedLabelColor: cs.onSurfaceVariant,
                    indicatorColor: cs.primary,
                    dividerColor: Colors.transparent,
                    labelStyle: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: const [
                  _StorageTab(),
                  _CredentialsTab(),
                ],
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                border:
                    Border(top: BorderSide(color: cs.outline.withAlpha(30))),
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
// Tab — Storage
// =============================================================================

class _StorageTab extends ConsumerStatefulWidget {
  const _StorageTab();

  @override
  ConsumerState<_StorageTab> createState() => _StorageTabState();
}

class _StorageTabState extends ConsumerState<_StorageTab> {
  final _bucketCtrl = TextEditingController();
  final _jsonFolderCtrl = TextEditingController();
  final _imagesRootCtrl = TextEditingController();
  final _liveRootCtrl = TextEditingController();
  bool _loaded = false;

  @override
  void dispose() {
    _bucketCtrl.dispose();
    _jsonFolderCtrl.dispose();
    _imagesRootCtrl.dispose();
    _liveRootCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    String clean(TextEditingController c) =>
        c.text.trim().replaceAll(RegExp(r'^/+|/+$'), '');
    final settings = StorageSettings(
      bucket: clean(_bucketCtrl),
      jsonFolder: clean(_jsonFolderCtrl),
      imagesRoot: clean(_imagesRootCtrl),
      liveRoot: clean(_liveRootCtrl),
    );
    await ref.read(storageSettingsProvider.notifier).save(settings);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Storage settings saved')),
    );
  }

  void _reset() {
    const defaults = StorageSettings();
    setState(() {
      _bucketCtrl.text = defaults.bucket;
      _jsonFolderCtrl.text = defaults.jsonFolder;
      _imagesRootCtrl.text = defaults.imagesRoot;
      _liveRootCtrl.text = defaults.liveRoot;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ref.watch(storageSettingsProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err')),
          data: (settings) {
            if (!_loaded) {
              _loaded = true;
              _bucketCtrl.text = settings.bucket;
              _jsonFolderCtrl.text = settings.jsonFolder;
              _imagesRootCtrl.text = settings.imagesRoot;
              _liveRootCtrl.text = settings.liveRoot;
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Firebase Storage',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Where the catalogs and wallpapers live. The defaults are the live '
                        'app data. To try things out safely, point both folders at a test '
                        'prefix (e.g. cms_test/wallriojson) holding a copy of the JSON.',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 20),
                      _LabeledField(
                        label: 'Bucket',
                        child: TextField(controller: _bucketCtrl),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: 'JSON folder (rio.Json, desktop.json, live_wall.json, collections.json, history/)',
                        child: TextField(controller: _jsonFolderCtrl),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: 'Images root (<category>/…, Desktop/…, <collection>/…)',
                        child: TextField(controller: _imagesRootCtrl),
                      ),
                      const SizedBox(height: 14),
                      _LabeledField(
                        label: 'Live root (livewalls/, previews/, thumbnails/)',
                        child: TextField(controller: _liveRootCtrl),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          TextButton(onPressed: _reset, child: const Text('Reset to defaults')),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: _save,
                            icon: const Icon(Icons.save_rounded, size: 16),
                            label: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
  final _pubIdCtrl = TextEditingController();
  final _pkgNameCtrl = TextEditingController();
  final _clientIdCtrl = TextEditingController();
  final _clientSecretCtrl = TextEditingController();
  final _fcmProjectIdCtrl = TextEditingController();
  final _settingsService = AppSettingsService();
  bool _loaded = false;
  bool _showSecret = false;
  bool _savingOAuth = false;
  bool _signingIn = false;
  bool _refreshingAnalytics = false;

  @override
  void dispose() {
    _pubIdCtrl.dispose();
    _pkgNameCtrl.dispose();
    _clientIdCtrl.dispose();
    _clientSecretCtrl.dispose();
    _fcmProjectIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(CredentialStatus status) async {
    if (_loaded) return;
    _loaded = true;
    final pubId = await _settingsService.getAdMobPublisherId();
    final pkgName = await _settingsService.getPlayPackageName();
    if (mounted) {
      setState(() {
        _clientIdCtrl.text = status.clientId ?? '';
        _clientSecretCtrl.text = status.clientSecret ?? '';
        _fcmProjectIdCtrl.text = status.firebaseProjectId ?? '';
        _pubIdCtrl.text = pubId ?? '';
        _pkgNameCtrl.text = pkgName ?? '';
      });
    }
  }

  Future<void> _saveOAuth(BuildContext context) async {
    setState(() => _savingOAuth = true);
    try {
      await ref.read(credentialsStateProvider.notifier).saveConfig(
            clientId: _clientIdCtrl.text.trim(),
            clientSecret: _clientSecretCtrl.text.trim(),
            projectId: _fcmProjectIdCtrl.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OAuth configuration saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _savingOAuth = false);
    }
  }

  Future<void> _handleSignIn(BuildContext context) async {
    setState(() => _signingIn = true);
    try {
      final success = await ref.read(credentialsStateProvider.notifier).signIn();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(success
              ? 'Signed in with Google'
              : 'Sign-in failed. Check your Client ID and Secret.'),
          backgroundColor: success
              ? null
              : Theme.of(context).colorScheme.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _signingIn = false);
    }
  }

  Future<void> _saveAndRefreshAnalytics(BuildContext context) async {
    setState(() => _refreshingAnalytics = true);
    try {
      await Future.wait([
        _settingsService.setAdMobPublisherId(_pubIdCtrl.text.trim()),
        _settingsService.setPlayPackageName(_pkgNameCtrl.text.trim()),
      ]);
      // Only fetch live data if already signed in; saving always works
      final isSignedIn =
          ref.read(credentialsStateProvider).value?.isSignedIn ?? false;
      if (isSignedIn) {
        await ref.read(analyticsStateProvider.notifier).refresh();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isSignedIn
                ? 'Analytics targets saved & refreshed'
                : 'Analytics targets saved'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshingAnalytics = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final credState = ref.watch(credentialsStateProvider);
    final cs = Theme.of(context).colorScheme;

    return credState.when(
      data: (status) {
        Future.microtask(() => _load(status));
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── OAuth ──────────────────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Google OAuth',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create a Desktop app OAuth client in Google Cloud Console.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    _LabeledField(
                      label: 'Client ID',
                      child: TextField(
                        controller: _clientIdCtrl,
                        decoration:
                            const InputDecoration(hintText: 'OAuth Client ID'),
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
                            icon: Icon(
                              _showSecret
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 18,
                            ),
                            onPressed: () =>
                                setState(() => _showSecret = !_showSecret),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _LabeledField(
                      label: 'FCM Project ID',
                      child: TextField(
                        controller: _fcmProjectIdCtrl,
                        decoration: const InputDecoration(
                            hintText: 'Firebase project ID'),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        icon: _savingOAuth
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded, size: 18),
                        label: Text(_savingOAuth ? 'Saving…' : 'Save OAuth Configuration'),
                        onPressed: _savingOAuth
                            ? null
                            : () => _saveOAuth(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Service accounts ───────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Service Accounts',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Save OAuth config first, then click Connect — a browser window will open for Google sign-in.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    _ServiceAccountRow(
                      title: 'Firebase (FCM)',
                      isSignedIn: status.isSignedIn,
                      disabled: status.clientId?.isEmpty ?? true,
                      loading: _signingIn,
                      onConnect: () => _handleSignIn(context),
                    ),
                    const SizedBox(height: 10),
                    _ServiceAccountRow(
                      title: 'Google Cloud (AdMob / Play / Storage)',
                      isSignedIn: status.isSignedIn,
                      disabled: status.clientId?.isEmpty ?? true,
                      loading: _signingIn,
                      onConnect: () => _handleSignIn(context),
                    ),
                    if (status.isSignedIn) ...[
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton.icon(
                          onPressed: () => ref
                              .read(credentialsStateProvider.notifier)
                              .clearAll(),
                          icon: Icon(Icons.delete_forever_rounded,
                              color: cs.error),
                          label: Text('Sign Out & Clear All Data',
                              style: TextStyle(color: cs.error)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Analytics targets ──────────────────────────────────────
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Analytics Targets',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.primary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requires signed-in service accounts above.',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _LabeledField(
                            label: 'AdMob Publisher ID',
                            child: TextField(
                              controller: _pubIdCtrl,
                              decoration: const InputDecoration(
                                  hintText: 'ca-app-pub-XXXX~YYYY for per-app, or pub-XXXX for all'),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _LabeledField(
                            label: 'Play Package Name',
                            child: TextField(
                              controller: _pkgNameCtrl,
                              decoration: const InputDecoration(
                                  hintText: 'com.example.app'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 44,
                      child: FilledButton.icon(
                        icon: _refreshingAnalytics
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.sync_rounded, size: 18),
                        label: Text(_refreshingAnalytics
                            ? 'Refreshing…'
                            : 'Save & Refresh Analytics'),
                        onPressed: _refreshingAnalytics
                            ? null
                            : () => _saveAndRefreshAnalytics(context),
                      ),
                    ),
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
// Service account row
// =============================================================================

class _ServiceAccountRow extends StatelessWidget {
  const _ServiceAccountRow({
    required this.title,
    required this.isSignedIn,
    required this.disabled,
    required this.onConnect,
    this.loading = false,
  });

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
      decoration: BoxDecoration(
        color: colors.bgSubtle,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: Colors.orangeAccent.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isSignedIn ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
              color: Colors.orangeAccent,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  isSignedIn ? 'Signed In' : 'Not Authenticated',
                  style: TextStyle(
                    color: isSignedIn ? colors.success : colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: (disabled || loading) ? null : onConnect,
            icon: loading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    isSignedIn ? Icons.sync_rounded : Icons.login_rounded,
                    size: 14),
            label: Text(
                loading
                    ? 'Connecting…'
                    : isSignedIn
                        ? 'Switch'
                        : 'Connect',
                style: const TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Shared form helpers (mirrors deployment module's _LabeledField / _PathField)
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
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.appColors.textSecondary,
              ),
        ),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}
