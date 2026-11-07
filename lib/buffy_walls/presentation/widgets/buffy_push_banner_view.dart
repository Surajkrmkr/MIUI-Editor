import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';

import '../../../wall_rio/infrastructure/services/storage_client.dart';
import '../../application/providers/buffy_storage_provider.dart';
import '../../domain/buffy_storage_layout.dart';

/// FCM drops notification images larger than this.
const _kFcmImageLimit = 1024 * 1024;

class _PickedImage {
  _PickedImage(this.name, this.bytes, this.width, this.height);
  final String name;
  final Uint8List bytes;
  final int width;
  final int height;
}

/// Uploads push notification banners to Firebase Storage and gives their links.
class BuffyPushBannerView extends ConsumerStatefulWidget {
  const BuffyPushBannerView({super.key});

  @override
  ConsumerState<BuffyPushBannerView> createState() => _BuffyPushBannerViewState();
}

class _BuffyPushBannerViewState extends ConsumerState<BuffyPushBannerView> {
  _PickedImage? _picked;
  bool _dragging = false;
  bool _uploading = false;
  String? _uploadedUrl;
  String? _error;
  late Future<List<StorageObject>> _uploads = _loadUploads();

  Future<List<StorageObject>> _loadUploads() async {
    final publisher = await ref.read(buffyCatalogPublisherProvider.future);
    return publisher.listFolder(kBuffyPushFolder);
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final path = result?.files.single.path;
    if (path != null) await _load(path);
  }

  Future<void> _load(String path) async {
    final file = File(path);
    try {
      final bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final picked = _PickedImage(file.uri.pathSegments.last, bytes, image.width, image.height);
      image.dispose();
      setState(() {
        _picked = picked;
        _uploadedUrl = null;
        _error = null;
      });
    } catch (_) {
      setState(() => _error = 'Not a readable image: ${file.uri.pathSegments.last}');
    }
  }

  Future<void> _upload() async {
    final picked = _picked!;
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final publisher = await ref.read(buffyCatalogPublisherProvider.future);
      final url = await publisher.uploadImage(kBuffyPushFolder, picked.name, picked.bytes);
      setState(() {
        _uploadedUrl = url;
        _uploads = _loadUploads();
      });
    } catch (e) {
      setState(() => _error = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _copy(String url) {
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 440, child: SingleChildScrollView(child: _buildUploader(context))),
          const SizedBox(width: 24),
          Expanded(child: _buildUploads(context)),
        ],
      ),
    );
  }

  Widget _buildUploader(BuildContext context) {
    final colors = context.appColors;
    final picked = _picked;
    final warnings = [
      if (picked != null && picked.bytes.length > _kFcmImageLimit)
        'Larger than 1 MB: Android will not show it in the notification.',
      if (picked != null && (picked.width / picked.height - 2).abs() > 0.2)
        'Notifications crop to about 2:1 (e.g. 1024 × 512).',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: colors.primary),
              const SizedBox(width: 10),
              Text(
                'Push notification banner',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Upload an image and paste its link as the notification image in '
            'Firebase Console → Messaging.',
            style: TextStyle(fontSize: 12, color: colors.textSecondary),
          ),
          const SizedBox(height: 16),
          DropTarget(
            enable: !_uploading,
            onDragEntered: (_) => setState(() => _dragging = true),
            onDragExited: (_) => setState(() => _dragging = false),
            onDragDone: (details) {
              setState(() => _dragging = false);
              if (details.files.isNotEmpty) _load(details.files.first.path);
            },
            child: InkWell(
              onTap: _uploading ? null : _pick,
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 2,
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: _dragging ? colors.primarySelection : colors.bgSubtle,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _dragging ? colors.primary : colors.border),
                  ),
                  child: picked != null
                      ? Image.memory(picked.bytes, fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 36, color: colors.textDisabled),
                            const SizedBox(height: 8),
                            Text('Drop an image or click to choose',
                                style: TextStyle(color: colors.textSecondary)),
                          ],
                        ),
                ),
              ),
            ),
          ),
          if (picked != null) ...[
            const SizedBox(height: 10),
            Text(
              '${picked.name}  ·  ${picked.width} × ${picked.height}  ·  '
              '${(picked.bytes.length / 1024).toStringAsFixed(0)} KB',
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
          for (final w in warnings)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 16, color: colors.warning),
                  const SizedBox(width: 6),
                  Expanded(child: Text(w, style: TextStyle(fontSize: 12, color: colors.warning))),
                ],
              ),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: picked == null || _uploading || _uploadedUrl != null ? null : _upload,
            icon: _uploading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(_uploading ? 'Uploading…' : 'Upload & get link'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            SelectableText(_error!, style: TextStyle(color: colors.error, fontSize: 12)),
          ],
          if (_uploadedUrl != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.success.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 18, color: colors.success),
                      const SizedBox(width: 6),
                      Text('Uploaded', style: TextStyle(fontWeight: FontWeight.w700, color: colors.success)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _copy(_uploadedUrl!),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Copy link'),
                      ),
                    ],
                  ),
                  SelectableText(
                    _uploadedUrl!,
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: colors.textPrimary),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploads(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Uploaded banners',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colors.textPrimary),
            ),
            const SizedBox(width: 12),
            Text('$kBuffyMediaRoot/$kBuffyPushFolder', style: TextStyle(color: colors.textSecondary)),
            const Spacer(),
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => setState(() => _uploads = _loadUploads()),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<StorageObject>>(
            future: _uploads,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: SelectableText('${snapshot.error}', style: TextStyle(color: colors.error)),
                );
              }
              final objects = snapshot.data;
              if (objects == null) return const Center(child: CircularProgressIndicator());
              if (objects.isEmpty) {
                return Center(
                  child: Text('No push banners yet', style: TextStyle(color: colors.textSecondary)),
                );
              }
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 340,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.35,
                ),
                itemCount: objects.length,
                itemBuilder: (context, i) => _UploadCard(
                  object: objects[i],
                  onCopy: _copy,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.object, required this.onCopy});

  final StorageObject object;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final url = buffyDownloadUrl(object.path);
    final updated = object.updated?.toLocal().toString().substring(0, 16) ?? '';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onCopy(url),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => ColoredBox(
                  color: colors.bgSubtle,
                  child: Center(child: Icon(Icons.broken_image_outlined, color: colors.textDisabled)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          object.path.split('/').last,
                          style: TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$updated  ·  ${(object.size / 1024).toStringAsFixed(0)} KB',
                          style: TextStyle(fontSize: 11, color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy link',
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () => onCopy(url),
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
