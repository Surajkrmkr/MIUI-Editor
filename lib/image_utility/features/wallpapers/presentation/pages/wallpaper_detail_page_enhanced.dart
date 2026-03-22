import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/domain/entities/wallpaper.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/wallpaper_providers.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/providers/download_provider.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/widgets/crop_dialog.dart';
import 'package:miui_icon_generator/image_utility/features/wallpapers/presentation/widgets/shimmer_widgets.dart';
import 'package:http/http.dart' as http;

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
      // Download image data
      final response = await http.get(Uri.parse(wallpaper.largeUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to load image');
      }

      setState(() => _downloadStatus = null);

      if (!mounted) return;

      // Show crop dialog
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
            const SnackBar(
              content: Text('Image cropped! Ready to download.'),
              backgroundColor: Colors.green,
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
          // Wait for service to load
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
          _croppedImageData = null; // Reset after download
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
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Download Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResultRow('AI Name', result.aiName),
            const SizedBox(height: 8),
            _buildResultRow('Tags', result.tags.join(', ')),
            const SizedBox(height: 8),
            _buildResultRow('Image', result.imagePath.split('/').last),
            const SizedBox(height: 8),
            _buildResultRow('Tags File', result.tagsFilePath.split('/').last),
            const SizedBox(height: 8),
            _buildResultRow(
                'Copyright', result.copyrightZipPath.split('/').last),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Resolution: 1080×2340 (6:13 ratio)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
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
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share
            },
          ),
        ],
      ),
      body: wallpaperAsync.when(
        data: (wallpaper) {
          if (wallpaper == null) {
            return const Center(child: Text('Wallpaper not found'));
          }
          return _buildDetailView(context, wallpaper);
        },
        loading: () => const WallpaperDetailShimmer(), // Changed to shimmer
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
      ),
    );
  }

  Widget _buildDetailView(BuildContext context, Wallpaper wallpaper) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with phone wallpaper aspect ratio
              Hero(
                tag: 'wallpaper_${wallpaper.id}',
                child: SizedBox(
                  height: 400,
                  width: double.infinity,
                  child: _croppedImageData != null
                      ? Image.memory(
                          _croppedImageData!,
                          fit: BoxFit.cover,
                        )
                      : CachedNetworkImage(
                          imageUrl: wallpaper.largeUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                                child: CircularProgressIndicator()),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          ),
                        ),
                ),
              ),

              // Crop indicator
              if (_croppedImageData != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.green,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Image cropped and ready to download',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photographer Info
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(wallpaper.photographer[0].toUpperCase()),
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
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Description
                    if (wallpaper.description != null &&
                        wallpaper.description!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(wallpaper.description!),
                          const SizedBox(height: 24),
                        ],
                      ),

                    // Dimensions
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Original Size',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              Text('${wallpaper.width} × ${wallpaper.height}'),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Output Size',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const Text('1080 × 2340'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Tags
                    if (wallpaper.tags != null && wallpaper.tags!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tags',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: wallpaper.tags!.map((tag) {
                              return Chip(label: Text(tag));
                            }).toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),

                    // Info Card
                    const Card(
                      color: Colors.blueGrey,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.auto_awesome, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'AI Processing',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text('• Manual crop with 6:13 phone ratio',
                                style: TextStyle(fontSize: 12)),
                            Text('• AI-generated filename (max 10 chars)',
                                style: TextStyle(fontSize: 12)),
                            Text('• 6 AI-selected tags',
                                style: TextStyle(fontSize: 12)),
                            Text('• Copyright info saved as .zip',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 120), // Space for buttons
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom action buttons
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_downloadStatus != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Text(_downloadStatus!),
                      ],
                    ),
                  ),

                // Crop button
                if (_croppedImageData == null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isDownloading
                          ? null
                          : () => _showCropDialog(wallpaper),
                      icon: const Icon(Icons.crop),
                      label: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Crop Image (6:13)'),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),

                // Download button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading
                        ? null
                        : () => _handleDownload(wallpaper),
                    icon: const Icon(Icons.download),
                    label: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_isDownloading
                          ? 'Processing...'
                          : _croppedImageData != null
                              ? 'Download Cropped Image'
                              : 'Download & Auto-Crop'),
                    ),
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
