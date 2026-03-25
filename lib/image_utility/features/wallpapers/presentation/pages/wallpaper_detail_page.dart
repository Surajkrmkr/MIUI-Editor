import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/wallpaper_providers.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/download_provider.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/widgets/crop_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:miui_icon_generator/theme_editor/core/constants/app_constants.dart';
import 'package:miui_icon_generator/widgets/iphone_frame.dart';

class WallpaperDetailPageEnhanced extends ConsumerStatefulWidget {
  final String wallpaperId;
  final String source;

  const WallpaperDetailPageEnhanced({
    super.key,
    required this.wallpaperId,
    required this.source,
  });

  @override
  ConsumerState<WallpaperDetailPageEnhanced> createState() =>
      _WallpaperDetailPageEnhancedState();
}

class _WallpaperDetailPageEnhancedState
    extends ConsumerState<WallpaperDetailPageEnhanced> {
  bool _isDownloading = false;
  String? _downloadStatus;
  Uint8List? _croppedImageData;

  Future<void> _showCropDialog(Wallpaper wallpaper) async {
    setState(() => _downloadStatus = 'Loading image for cropping...');

    try {
      final response = await http.get(Uri.parse(wallpaper.largeUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load image');
      }

      setState(() => _downloadStatus = null);

      if (!mounted) return;

      final croppedData = await showCropDialog(
        context,
        response.bodyBytes,
        title: 'Crop Wallpaper (6:13)',
      );

      if (croppedData != null) {
        setState(() {
          _croppedImageData = croppedData;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Image cropped! Ready to download.'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              showCloseIcon: true,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _downloadStatus = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Crop failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDownload(Wallpaper wallpaper) async {
    setState(() {
      _isDownloading = true;
      _downloadStatus = 'Processing image...';
    });

    try {
      final downloadService = ref.read(downloadServiceProvider);
      final result = await downloadService.when(
        data: (service) => service.downloadAndProcessWallpaper(wallpaper),
        loading: () async {
          setState(() => _downloadStatus = 'Initializing download service...');
          final service = await ref.watch(downloadServiceProvider.future);
          return service.downloadAndProcessWallpaper(wallpaper);
        },
        error: (error, stack) => throw error,
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadStatus = null;
          _croppedImageData = null;
        });

        _showSuccessDialog(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadStatus = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(DownloadResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _RenameDialog(
        result: result,
        downloadServiceAsync: ref.read(downloadServiceProvider),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallpaperAsync = ref.watch(
      wallpaperByIdProvider((id: widget.wallpaperId, source: widget.source)),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Wallpaper Detail'),
      ),
      body: wallpaperAsync.when(
        data: (wallpaper) {
          if (wallpaper == null) {
            return const Center(child: Text('Wallpaper not found'));
          }
          return _buildDetailView(context, wallpaper);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildDetailView(BuildContext context, Wallpaper wallpaper) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Phone mockup preview
        Padding(
          padding: const EdgeInsets.only(left: 12, top: 12, right: 12),
          child: IPhoneFrame(
            child: screenContent(wallpaper),
          ),
        ),

        // Divider
        const VerticalDivider(width: 1),

        // Right: Info + Actions
        Expanded(
          flex: 6,
          child: _buildInfoPanel(context, wallpaper),
        ),
      ],
    );
  }

  Widget screenContent(Wallpaper wallpaper) {
    return SizedBox(
      height: AppConstants.screenHeight,
      width: AppConstants.screenWidth,
      child: Hero(
        tag: 'wallpaper_${wallpaper.id}',
        child: _croppedImageData != null
            ? Image.memory(
                _croppedImageData!,
                fit: BoxFit.cover,
              )
            : CachedNetworkImage(
                imageUrl: wallpaper.largeUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoPanel(BuildContext context, Wallpaper wallpaper) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photographer info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Text(
                        wallpaper.photographer[0].toUpperCase(),
                        style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wallpaper.photographer,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            wallpaper.source.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Description
                if (wallpaper.description != null &&
                    wallpaper.description!.isNotEmpty) ...[
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(wallpaper.description!,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 20),
                ],

                // Resolution row
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        label: 'Original',
                        value: '${wallpaper.width} × ${wallpaper.height}',
                        icon: Icons.image,
                      ),
                    ),
                    Icon(Icons.arrow_forward,
                        size: 16, color: Theme.of(context).colorScheme.outline),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: _InfoTile(
                        label: 'Output',
                        value: '1080 × 2340',
                        icon: Icons.crop,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Tags
                if (wallpaper.tags != null && wallpaper.tags!.isNotEmpty) ...[
                  Text(
                    'Tags',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: wallpaper.tags!.map((tag) {
                      return Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // AI processing card
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.auto_awesome,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'AI Processing',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...[
                          'Manual crop with 6:13 phone ratio',
                          'AI-generated filename (max 10 chars)',
                          '6 AI-selected tags',
                          'Copyright info saved as .zip',
                        ].map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Text('• $item',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Action buttons at bottom of right panel
        _buildActionBar(wallpaper),
      ],
    );
  }

  Widget _buildActionBar(Wallpaper wallpaper) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_downloadStatus != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(_downloadStatus!,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          Row(
            children: [
              // Crop button
              if (_croppedImageData == null)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDownloading
                        ? null
                        : () => _showCropDialog(wallpaper),
                    icon: const Icon(Icons.crop, size: 18),
                    label: const Text('Crop (6:13)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),

              if (_croppedImageData == null) const SizedBox(width: 10),

              // Download button
              Expanded(
                flex: _croppedImageData != null ? 1 : 0,
                child: FilledButton.icon(
                  onPressed:
                      _isDownloading ? null : () => _handleDownload(wallpaper),
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.download, size: 18),
                  label: Text(_isDownloading
                      ? 'Processing...'
                      : _croppedImageData != null
                          ? 'Download Cropped'
                          : 'Download'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14, horizontal: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Rename dialog – stateful so the text field and rename-in-progress state work
// ──────────────────────────────────────────────────────────────────────────────

class _RenameDialog extends StatefulWidget {
  final DownloadResult result;
  final AsyncValue<DownloadService> downloadServiceAsync;

  const _RenameDialog({
    required this.result,
    required this.downloadServiceAsync,
  });

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _nameController;
  late DownloadResult _current;
  bool _isRenaming = false;
  String? _renameError;

  @override
  void initState() {
    super.initState();
    _current = widget.result;
    _nameController = TextEditingController(text: _current.aiName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _rename() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) {
      setState(() => _renameError = 'Name cannot be empty');
      return;
    }
    if (newName == _current.aiName) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isRenaming = true;
      _renameError = null;
    });

    try {
      final service = await widget.downloadServiceAsync.when(
        data: (s) async => s,
        loading: () async => throw Exception('Service not ready'),
        error: (e, _) async => throw e,
      );

      final renamed = await service.renameWallpaper(_current, newName);
      setState(() {
        _current = renamed;
        _nameController.text = renamed.aiName;
        _isRenaming = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Renamed to "${renamed.aiName}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isRenaming = false;
        _renameError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nameChanged = _nameController.text.trim() != _current.aiName;

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Download Complete'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Editable filename
            Text(
              'File Name',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() => _renameError = null),
              decoration: InputDecoration(
                hintText: 'Enter file name',
                errorText: _renameError,
                border: const OutlineInputBorder(),
                suffixIcon: _isRenaming
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                helperText:
                    'Renames image (.jpg), tags (.txt) & copyright (.zip)',
              ),
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),

            // AI tags
            _ResultRow(
              label: 'Tags',
              value: _current.tags.join(', '),
            ),
            const SizedBox(height: 8),
            _ResultRow(
              label: 'Image',
              value: _current.imagePath.split('/').last,
            ),
            const SizedBox(height: 8),
            _ResultRow(
              label: 'Tags File',
              value: _current.tagsFilePath.split('/').last,
            ),
            const SizedBox(height: 8),
            _ResultRow(
              label: 'Copyright',
              value: _current.copyrightZipPath.split('/').last,
            ),
            const SizedBox(height: 8),
            Text(
              'Resolution: 1080×2340 (6:13 ratio)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isRenaming ? null : () => Navigator.pop(context),
          child: const Text('Done'),
        ),
        FilledButton.icon(
          onPressed: _isRenaming ? null : _rename,
          icon: const Icon(Icons.drive_file_rename_outline, size: 16),
          label: Text(nameChanged ? 'Rename & Save' : 'Close'),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )),
              Text(value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      )),
            ],
          ),
        ],
      ),
    );
  }
}
