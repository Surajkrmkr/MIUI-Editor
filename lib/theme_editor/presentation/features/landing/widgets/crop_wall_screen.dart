import 'dart:io';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:miui_icon_generator/theme_editor/presentation/providers/usecase_providers.dart';
import '../../../../core/constants/path_constants.dart';
import '../../../providers/directory_provider.dart';
import '../../../providers/service_providers.dart';

class CropWallScreen extends ConsumerStatefulWidget {
  const CropWallScreen({
    super.key,
    required this.downloadUrl,
    required this.destName,
    required this.folderNum,
    required this.pageUrl,
    required this.weekNum,
  });
  final String downloadUrl, destName, folderNum, pageUrl, weekNum;

  @override
  ConsumerState<CropWallScreen> createState() => _CropWallScreenState();
}

class _CropWallScreenState extends ConsumerState<CropWallScreen> {
  final _cropCtrl = CropController();
  List<int>? _imageBytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _downloadImage();
  }

  Future<void> _downloadImage() async {
    final (path, failure) =
        await ref.read(downloadWallpaperUseCaseProvider).call(
              url: widget.downloadUrl,
              destPath: _tempDestPath(), // e.g. system temp/name.jpg
            );
    if (failure != null || path == null) {
      setState(() => _loading = false);
      return;
    }
    final bytes = await File(path).readAsBytes();
    setState(() {
      _imageBytes = bytes;
      _loading = false;
    });
  }

  String _tempDestPath() {
    // Use system temp dir during crop — final save happens after crop
    final tmpDir = Directory.systemTemp.path;
    return '$tmpDir${Platform.pathSeparator}${widget.destName}_tmp.jpg';
  }

  Future<void> _crop(CropResult result) async {
    if (result is! CropSuccess) return;
    final decoded = img.decodeImage(result.croppedImage)!;
    final resized = img.copyResize(decoded, width: 1080);
    final jpg = img.encodeJpg(resized);
    final destPath = PathConstants.p(
        '${PathConstants.wallBasePath}${widget.folderNum}/${widget.destName}.jpg');
    final fs = ref.read(fileServiceProvider);
    await fs.writeBytes(destPath, jpg);
    // Save copyright txt
    await _saveCopyright();
    ref.read(directoryProvider.notifier).loadPreviewWalls(widget.folderNum);
    if (mounted) {
      Navigator.of(context)
        ..pop()
        ..pop();
    }
  }

  Future<void> _saveCopyright() async {
    final copyrightDir = PathConstants.copyrightDirectory(widget.weekNum);
    final fs = ref.read(fileServiceProvider);
    await fs.createDir(copyrightDir);
    await fs.writeString(
        PathConstants.p('$copyrightDir${widget.destName}.txt'), widget.pageUrl);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Crop Wall'),
          actions: [
            IconButton(
              icon: const Icon(Icons.crop),
              onPressed: () => _cropCtrl.crop(),
            ),
            const SizedBox(width: 12),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Crop(
                aspectRatio: 6 / 13,
                image: Uint8List.fromList(_imageBytes!),
                controller: _cropCtrl,
                onCropped: _crop,
              ),
      );
}
