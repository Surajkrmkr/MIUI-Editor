import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/settings_provider.dart';
import '../../application/providers/credentials_provider.dart';
import '../../infrastructure/services/app_settings_service.dart';
import '../widgets/sidebar.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedPathsState = ref.watch(savedPathsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      drawer: const Sidebar(),
      body: savedPathsState.when(
        data: (paths) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Global Repository Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure the base local path for your wallpaper assets.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const _WallpaperRepoTile(),
            const SizedBox(height: 40),
            const Text(
              'JSON Project Slots (Max 3)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure up to 3 JSON files to easily switch between them.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            for (int i = 0; i < 3; i++)
              _JsonSlotTile(
                index: i,
                savedPath: i < paths.length ? paths[i] : null,
              ),
            const SizedBox(height: 40),
            const Text(
              'Operational Credentials',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure OAuth credentials and connect your Google account for FCM, AdMob, and Play Console integration.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const _CredentialsSection(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _CredentialsSection extends ConsumerStatefulWidget {
  const _CredentialsSection();

  @override
  ConsumerState<_CredentialsSection> createState() => _CredentialsSectionState();
}

class _CredentialsSectionState extends ConsumerState<_CredentialsSection> {
  final _pubIdController = TextEditingController();
  final _pkgNameController = TextEditingController();
  
  final _clientIdController = TextEditingController();
  final _clientSecretController = TextEditingController();
  final _fcmProjectIdController = TextEditingController();

  final _settingsService = AppSettingsService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final pubId = await _settingsService.getAdMobPublisherId();
    final pkgName = await _settingsService.getPlayPackageName();
    
    // Initial load from provider state if available
    final state = ref.read(credentialsStateProvider).value;
    if (state != null) {
      _clientIdController.text = state.clientId ?? '';
      _clientSecretController.text = state.clientSecret ?? '';
      _fcmProjectIdController.text = state.firebaseProjectId ?? '';
    }

    if (mounted) {
      setState(() {
        _pubIdController.text = pubId ?? '';
        _pkgNameController.text = pkgName ?? '';
      });
    }
  }

  @override
  void dispose() {
    _pubIdController.dispose();
    _pkgNameController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    _fcmProjectIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(credentialsStateProvider);

    return state.when(
      data: (status) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Google OAuth Configuration (Desktop App)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _clientIdController,
            decoration: const InputDecoration(
              labelText: 'Client ID',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _clientSecretController,
            decoration: const InputDecoration(
              labelText: 'Client Secret',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fcmProjectIdController,
            decoration: const InputDecoration(
              labelText: 'FCM Project ID',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ref.read(credentialsStateProvider.notifier).saveConfig(
                  clientId: _clientIdController.text.trim(),
                  clientSecret: _clientSecretController.text.trim(),
                  projectId: _fcmProjectIdController.text.trim(),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Configuration saved')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('Save OAuth Configuration'),
            ),
          ),
          const SizedBox(height: 32),
          _CredentialCard(
            title: 'Firebase Service Account (FCM)',
            subtitle: status.isSignedIn ? 'Signed In' : 'Not Authenticated',
            isSignedIn: status.isSignedIn,
            onConnect: (status.clientId?.isEmpty ?? true) ? null : () => _handleSignIn(context, ref),
          ),
          const SizedBox(height: 16),
          _CredentialCard(
            title: 'Google Cloud Service Account (AdMob/Play)',
            subtitle: status.isSignedIn ? 'Signed In' : 'Not Authenticated',
            isSignedIn: status.isSignedIn,
            onConnect: (status.clientId?.isEmpty ?? true) ? null : () => _handleSignIn(context, ref),
          ),
          const SizedBox(height: 40),
          const Text(
            'Analytics Targets',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pubIdController,
                  decoration: const InputDecoration(
                    labelText: 'AdMob Publisher ID',
                    hintText: 'pub-1234567890',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) => _settingsService.setAdMobPublisherId(val.trim()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _pkgNameController,
                  decoration: const InputDecoration(
                    labelText: 'Play Package Name',
                    hintText: 'com.example.app',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (val) => _settingsService.setPlayPackageName(val.trim()),
                ),
              ),
            ],
          ),
          if (status.isSignedIn)
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => ref.read(credentialsStateProvider.notifier).clearAll(),
                  icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  label: const Text('Sign Out & Clear All Data', style: TextStyle(color: Colors.redAccent)),
                ),
              ),
            ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Text('Error loading credentials: $err'),
    );
  }

  Future<void> _handleSignIn(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(credentialsStateProvider.notifier).signIn();
    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully signed in with Google')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to sign in. Check your Client ID and Secret.')),
        );
      }
    }
  }
}

class _WallpaperRepoTile extends ConsumerStatefulWidget {
  const _WallpaperRepoTile();

  @override
  ConsumerState<_WallpaperRepoTile> createState() => _WallpaperRepoTileState();
}

class _WallpaperRepoTileState extends ConsumerState<_WallpaperRepoTile> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repoPath = ref.watch(wallpaperRepoPathProvider);

    return repoPath.when(
      data: (path) {
        if (_controller.text != (path ?? '')) {
          _controller.text = path ?? '';
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wallpaper Repository Path',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Select folder...',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        readOnly: true,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: _pickDirectory,
                    ),
                  ],
                ),
                if (path != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Current: $path',
                    style: const TextStyle(fontSize: 12, color: Colors.blueAccent),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (err, _) => Text('Error: $err'),
    );
  }

  Future<void> _pickDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      await ref.read(wallpaperRepoPathProvider.notifier).setPath(result);
    }
  }
}

class _JsonSlotTile extends ConsumerStatefulWidget {
  final int index;
  final dynamic savedPath; // SavedFilePath?

  const _JsonSlotTile({required this.index, this.savedPath});

  @override
  ConsumerState<_JsonSlotTile> createState() => _JsonSlotTileState();
}

class _JsonSlotTileState extends ConsumerState<_JsonSlotTile> {
  late TextEditingController _labelController;
  late TextEditingController _pathController;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.savedPath?.label ?? 'JSON ${widget.index + 1}');
    _pathController = TextEditingController(text: widget.savedPath?.path ?? '');
  }

  @override
  void didUpdateWidget(_JsonSlotTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.savedPath != oldWidget.savedPath) {
      _labelController.text = widget.savedPath?.label ?? 'JSON ${widget.index + 1}';
      _pathController.text = widget.savedPath?.path ?? '';
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  child: Text('${widget.index + 1}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Project Label',
                      hintText: 'e.g., Production',
                      isDense: true,
                    ),
                  ),
                ),
                if (widget.savedPath != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => ref.read(savedPathsProvider.notifier).removePath(widget.savedPath!.path),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: 'JSON File Path',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    readOnly: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _pickFile,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _pathController.text.isEmpty ? null : _save,
                child: const Text('Save Slot'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _pathController.text = result.files.single.path!;
      });
    }
  }

  void _save() {
    ref.read(savedPathsProvider.notifier).savePath(
      _pathController.text.trim(),
      _labelController.text.trim(),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Slot updated successfully')),
    );
  }
}

class _CredentialCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSignedIn;
  final VoidCallback? onConnect;

  const _CredentialCard({
    required this.title,
    required this.subtitle,
    required this.isSignedIn,
    this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orangeAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isSignedIn ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
            color: Colors.orangeAccent,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: isSignedIn ? Colors.greenAccent : Colors.grey,
            fontSize: 12,
          ),
        ),
        trailing: ElevatedButton.icon(
          onPressed: onConnect,
          icon: Icon(isSignedIn ? Icons.sync : Icons.login),
          label: Text(isSignedIn ? 'Switch Account' : 'Connect'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white10,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}
