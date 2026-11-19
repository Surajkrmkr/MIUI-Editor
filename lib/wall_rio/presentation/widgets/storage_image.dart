import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:miui_icon_generator/core/theme/theme_extensions.dart';

/// Shows a catalog image URL. Catalog images are public on Cloudflare, so they
/// are fetched directly; anything that fails to load shows the error tile.
class StorageImage extends ConsumerStatefulWidget {
  const StorageImage(this.url, {super.key, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  ConsumerState<StorageImage> createState() => _StorageImageState();
}

class _StorageImageState extends ConsumerState<StorageImage> {
  // Thumbnails are small; keep the most recent ones so scrolling back is instant.
  static final _cache = <String, Future<Uint8List?>>{};
  static const _maxCached = 300;

  late Future<Uint8List?> _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _load();
  }

  @override
  void didUpdateWidget(StorageImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _bytes = _load();
  }

  Future<Uint8List?> _load() {
    final cached = _cache.remove(widget.url);
    if (cached != null) return _cache[widget.url] = cached;
    final future = () async {
      final uri = Uri.tryParse(widget.url);
      if (uri == null || !uri.hasScheme) return null;
      final res = await http.get(uri);
      return res.statusCode == 200 ? res.bodyBytes : null;
    }();
    _cache[widget.url] = future;
    // Failed loads are retried next time instead of being cached.
    future.catchError((_) => null).then((bytes) {
      if (bytes == null) _cache.remove(widget.url);
    });
    while (_cache.length > _maxCached) {
      _cache.remove(_cache.keys.first);
    }
    return future;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        if (bytes != null) {
          return Image.memory(bytes, fit: widget.fit, width: double.infinity, gaplessPlayback: true);
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return ColoredBox(color: colors.bgSubtle);
        }
        return ColoredBox(
          color: colors.bgSubtle,
          child: Center(child: Icon(Icons.broken_image_outlined, color: colors.textDisabled)),
        );
      },
    );
  }
}
