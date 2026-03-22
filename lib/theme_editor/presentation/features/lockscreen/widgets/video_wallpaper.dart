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
  late VideoPlayerController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        _ctrl.setLooping(true);
        _ctrl.play();
        _ctrl.setVolume(0);
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => _ctrl.value.isInitialized
      ? SizedBox(
          width: AppConstants.screenWidth,
          height: AppConstants.screenHeight,
          child: VideoPlayer(_ctrl),
        )
      : const SizedBox.shrink();
}
