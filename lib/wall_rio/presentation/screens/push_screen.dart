import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';
import 'package:miui_icon_generator/widgets/app_icon_button.dart';

import '../../application/providers/catalog_provider.dart';
import '../../application/providers/push_provider.dart';
import '../../application/services/catalog_service.dart';
import '../widgets/json_value_editor.dart';

/// Uploads a push notification banner, gives its public link (for the
/// Firebase console's "Notification image") and can send the push via FCM.
class PushScreen extends ConsumerStatefulWidget {
  const PushScreen({super.key});

  @override
  ConsumerState<PushScreen> createState() => _PushScreenState();
}

class _PushScreenState extends ConsumerState<PushScreen> {
  // FCM drops notification images over 1 MB.
  static const _maxImageBytes = 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final _image = TextEditingController();
  final _title = TextEditingController();
  final _body = TextEditingController();
  final _topic = TextEditingController(text: 'all');
  final _link = TextEditingController();
  bool _uploading = false;
  bool _sending = false;

  @override
  void dispose() {
    for (final c in [_image, _title, _body, _topic, _link]) {
      c.dispose();
    }
    super.dispose();
  }

  void _toast(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

  void _copy(String url) {
    Clipboard.setData(ClipboardData(text: url));
    _toast('Link copied');
  }

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: CatalogService.imageExtensions,
    );
    final path = result?.files.single.path;
    if (path == null) return;
    if (await File(path).length() > _maxImageBytes) {
      _toast('Image is over 1 MB; FCM will not show it. Compress it first.');
      return;
    }
    setState(() => _uploading = true);
    try {
      final service = await ref.read(catalogServiceProvider.future);
      final url = await service.uploadImage(path, CatalogService.pushFolder);
      _image.text = url;
      ref.invalidate(pushImagesProvider);
      _toast('Banner uploaded');
    } catch (e) {
      _toast('Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final topic = _topic.text.trim();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send push notification?'),
        content: Text('Everyone subscribed to "$topic" gets "${_title.text.trim()}" now. '
            'This can\'t be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _sending = true);
    try {
      await ref.read(pushCampaignsProvider.notifier).sendCampaign(
            title: _title.text.trim(),
            body: _body.text.trim(),
            imageUrl: _image.text.trim().isEmpty ? null : _image.text.trim(),
            deepLink: _link.text.trim().isEmpty ? null : _link.text.trim(),
            targetTopic: topic,
          );
      _toast('Sent to "$topic"');
    } catch (e) {
      _toast('Send failed: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final topics = ref.watch(fcmTopicsProvider).valueOrNull ?? const [];
    final sectionStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textPrimary);
    final hintStyle = TextStyle(fontSize: 12, color: colors.textSecondary);

    return Scaffold(
      appBar: AppBar(
        leading: AppBackButton(onPressed: () => context.go('/')),
        title: const Text('Push notification'),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Banner', style: sectionStyle),
                        const SizedBox(height: 4),
                        Text('JPG or PNG under 1 MB. 2:1 (e.g. 1024×512) shows best on Android.',
                            style: hintStyle),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: AspectRatio(
                            aspectRatio: 2,
                            child: ColoredBox(
                              color: colors.bgSubtle,
                              child: ValueListenableBuilder(
                                valueListenable: _image,
                                builder: (context, value, _) => value.text.trim().isEmpty
                                    ? Center(
                                        child: Icon(Icons.image_outlined, size: 48, color: colors.textDisabled),
                                      )
                                    : UrlPreview(value.text.trim(), fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: _uploading ? null : _upload,
                              icon: _uploading
                                  ? const SizedBox.square(
                                      dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.upload_rounded, size: 18),
                              label: const Text('Upload banner'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _image,
                                decoration: InputDecoration(
                                  labelText: 'Image link',
                                  isDense: true,
                                  suffixIcon: IconButton(
                                    tooltip: 'Copy link',
                                    icon: const Icon(Icons.copy_rounded, size: 18),
                                    onPressed: () {
                                      if (_image.text.trim().isNotEmpty) _copy(_image.text.trim());
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Sending from the Firebase console? Paste this link into '
                            '"Notification image".', style: hintStyle),
                        const SizedBox(height: 32),
                        Text('Notification', style: sectionStyle),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _title,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _body,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(labelText: 'Body'),
                          validator: _required,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _topic,
                                decoration: InputDecoration(
                                  labelText: 'Topic',
                                  suffixIcon: topics.isEmpty
                                      ? null
                                      : PopupMenuButton<String>(
                                          tooltip: 'Pick a topic',
                                          icon: const Icon(Icons.arrow_drop_down),
                                          onSelected: (t) => _topic.text = t,
                                          itemBuilder: (_) => [
                                            for (final t in topics)
                                              PopupMenuItem(value: t.name, child: Text(t.name)),
                                          ],
                                        ),
                                ),
                                validator: _required,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _link,
                                decoration: const InputDecoration(labelText: 'Deep link (optional)'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: _sending ? null : _send,
                            icon: _sending
                                ? const SizedBox.square(
                                    dimension: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.send_rounded, size: 18),
                            label: const Text('Send via FCM'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          VerticalDivider(width: 1, color: colors.borderSubtle),
          SizedBox(width: 360, child: _UploadedBanners(onCopy: _copy, onUse: (url) => _image.text = url)),
        ],
      ),
    );
  }
}

class _UploadedBanners extends ConsumerWidget {
  const _UploadedBanners({required this.onCopy, required this.onUse});

  final ValueChanged<String> onCopy;
  final ValueChanged<String> onUse;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final format = DateFormat('d MMM yyyy, HH:mm');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
          child: Row(
            children: [
              Text('Uploaded banners',
                  style: TextStyle(fontWeight: FontWeight.w700, color: colors.textPrimary)),
              const Spacer(),
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh_rounded, size: 18),
                onPressed: () => ref.invalidate(pushImagesProvider),
              ),
            ],
          ),
        ),
        Expanded(
          child: ref.watch(pushImagesProvider).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText('$err', style: TextStyle(color: colors.error, fontSize: 12)),
                ),
                data: (images) => images.isEmpty
                    ? Center(child: Text('None yet', style: TextStyle(color: colors.textSecondary)))
                    : ListView.builder(
                        itemCount: images.length,
                        itemBuilder: (context, i) {
                          final (:object, :url) = images[i];
                          final updated = object.updated?.toLocal();
                          return ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(width: 64, height: 32, child: UrlPreview(url, fit: BoxFit.cover)),
                            ),
                            title: Text(object.path.split('/').last,
                                overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                            subtitle: Text(
                              '${updated == null ? '' : format.format(updated)} · '
                              '${(object.size / 1024).toStringAsFixed(0)} KB',
                              style: TextStyle(fontSize: 11, color: colors.textSecondary),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Copy link',
                                  icon: const Icon(Icons.link_rounded, size: 18),
                                  onPressed: () => onCopy(url),
                                ),
                                IconButton(
                                  tooltip: 'Use in this notification',
                                  icon: const Icon(Icons.input_rounded, size: 18),
                                  onPressed: () => onUse(url),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
        ),
      ],
    );
  }
}
