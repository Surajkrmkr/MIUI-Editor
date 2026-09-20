import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/constants/app_constants.dart';

class VideoWallpaperWidget extends StatefulWidget {
  const VideoWallpaperWidget({super.key, required this.path});
  final String path;

  @override
  State<VideoWallpaperWidget> createState() => _VideoWallpaperWidgetState();
}

class _VideoWallpaperWidgetState extends State<VideoWallpaperWidget> {
  VideoPlayerController? _ctrl;
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    _initController(widget.path);
  }

  @override
  void didUpdateWidget(covariant VideoWallpaperWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _initController(widget.path);
    }
  }

  Future<void> _initController(String path) async {
    if (_isInitializing) return;
    _isInitializing = true;

    final oldCtrl = _ctrl;
    _ctrl = null;
    if (mounted) setState(() {});

    if (oldCtrl != null) {
      try {
        await oldCtrl.dispose();
      } catch (_) {}
    }

    final file = File(path);
    if (!file.existsSync()) {
      _isInitializing = false;
      return;
    }

    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setLooping(true);
      await controller.setVolume(0);
      await controller.play();
      _ctrl = controller;
    } catch (e) {
      debugPrint('VideoWallpaper initialization error: $e');
      try {
        await controller.dispose();
      } catch (_) {}
    } finally {
      _isInitializing = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _ctrl = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    if (ctrl != null && ctrl.value.isInitialized) {
      return SizedBox(
        width: AppConstants.screenWidth,
        height: AppConstants.screenHeight,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ctrl.value.size.width > 0 ? ctrl.value.size.width : AppConstants.screenWidth,
            height: ctrl.value.size.height > 0 ? ctrl.value.size.height : AppConstants.screenHeight,
            child: VideoPlayer(ctrl),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
