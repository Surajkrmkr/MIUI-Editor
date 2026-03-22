import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/models/pixabay_model.dart';
import '../../../providers/pick_wall_provider.dart';
import '../../../providers/directory_provider.dart';
import '../../../providers/wallpaper_provider.dart';
import '../../../providers/tag_provider.dart';
import '../../tags/tags_panel.dart';
import 'crop_wall_screen.dart';

class PickWallsScreen extends ConsumerStatefulWidget {
  const PickWallsScreen({super.key, required this.folderNum, required this.weekNum});
  final String folderNum;
  final String weekNum;

  @override
  ConsumerState<PickWallsScreen> createState() => _PickWallsScreenState();
}

class _PickWallsScreenState extends ConsumerState<PickWallsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wallpaperProvider.notifier)
          .loadFolder(widget.folderNum, widget.weekNum);
      ref.read(pickWallProvider.notifier).fetch();
    });
  }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final pwState = ref.watch(pickWallProvider);
    final dirState = ref.watch(directoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(pwState.search.isEmpty ? 'Pixabay' : pwState.search),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: ref.read(pickWallProvider.notifier).prevPage,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: ref.read(pickWallProvider.notifier).nextPage,
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 250,
            height: 45,
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (s) => ref.read(pickWallProvider.notifier).setSearch(s),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search...',
                border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30))),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () =>
                      ref.read(pickWallProvider.notifier).setSearch(_searchCtrl.text),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          PopupMenuButton<PixabayImageType>(
            icon: Row(children: [
              Text(pwState.imageType.name),
              const Icon(Icons.arrow_drop_down),
            ]),
            itemBuilder: (_) => PixabayImageType.values
                .map((t) => PopupMenuItem(value: t, child: Text(t.name)))
                .toList(),
            onSelected: ref.read(pickWallProvider.notifier).setType,
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Row(
        children: [
          // ── Pixabay grid ──────────────────────────────────────────────────
          Expanded(
            child: pwState.isLoading
                ? Shimmer.fromColors(
                    baseColor: const Color(0xFFD27685),
                    highlightColor: Colors.white,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4, crossAxisSpacing: 16, mainAxisSpacing: 16),
                      itemBuilder: (_, __) => Container(
                          decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(20))),
                    ),
                  )
                : pwState.hits.isEmpty
                    ? const Center(child: Text('No results from Pixabay'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16),
                        itemCount: pwState.hits.length,
                        itemBuilder: (_, i) => _PixabayTile(
                          hit: pwState.hits[i],
                          folderNum: widget.folderNum,
                          weekNum: widget.weekNum,
                        ),
                      ),
          ),
          // ── Downloaded panel ──────────────────────────────────────────────
          SizedBox(
            width: 280,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Text('Downloaded',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () => ref
                            .read(directoryProvider.notifier)
                            .loadPreviewWalls(widget.folderNum),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.5),
                    itemCount: dirState.previewWallPaths.length,
                    itemBuilder: (_, i) {
                      final path = dirState.previewWallPaths[i];
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: FileImage(File(path)),
                          ),
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          path.split(Platform.pathSeparator).last,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PixabayTile extends ConsumerStatefulWidget {
  const _PixabayTile({
    required this.hit,
    required this.folderNum,
    required this.weekNum,
  });
  final PixabayHit hit;
  final String folderNum;
  final String weekNum;

  @override
  ConsumerState<_PixabayTile> createState() => _PixabayTileState();
}

class _PixabayTileState extends ConsumerState<_PixabayTile> {
  bool _hovering = false;

  void _download() => showDialog(
        context: context,
        builder: (_) => _RenameDialog(
          hit: widget.hit,
          folderNum: widget.folderNum,
          weekNum: widget.weekNum,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit:  (_) => setState(() => _hovering = false),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            fit: BoxFit.cover,
            image: CachedNetworkImageProvider(widget.hit.webformatUrl),
          ),
        ),
        child: _hovering
            ? Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton.filled(
                    icon: const Icon(Icons.download),
                    onPressed: _download,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _RenameDialog extends ConsumerStatefulWidget {
  const _RenameDialog({
    required this.hit,
    required this.folderNum,
    required this.weekNum,
  });
  final PixabayHit hit;
  final String folderNum;
  final String weekNum;

  @override
  ConsumerState<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends ConsumerState<_RenameDialog> {
  final _nameCtrl = TextEditingController();
  int _step = 0;
  bool _downloading = false;

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _proceed() async {
    if (_step == 0 && _nameCtrl.text.trim().isNotEmpty) {
      await ref.read(directoryProvider.notifier).saveTagFile(
        widget.weekNum,
        _nameCtrl.text.trim(),
        ref.read(tagProvider).appliedTags,
      );
      setState(() => _step = 1);
    } else if (_step == 1) {
      setState(() => _downloading = true);
      // Download via WallpaperNotifier
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CropWallScreen(
            downloadUrl: widget.hit.largeImageUrl,
            destName: _nameCtrl.text.trim(),
            folderNum: widget.folderNum,
            pageUrl: widget.hit.pageUrl,
            weekNum: widget.weekNum,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(children: [
        const Text('Download Wall'),
        const Spacer(),
        const CloseButton(),
      ]),
      content: SizedBox(
        width: 400,
        height: 420,
        child: _step == 0
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Give this wall a name:'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Wall Name',
                    ),
                    onSubmitted: (_) => _proceed(),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Tags (max 6):'),
                  const SizedBox(height: 8),
                  const Expanded(child: TagsPanel(themeName: null)),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _downloading ? null : _proceed,
          child: Text(_step == 0 ? 'Next' : 'Download'),
        ),
      ],
    );
  }
}
