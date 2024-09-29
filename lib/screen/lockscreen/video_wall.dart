import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../constants.dart';

class VideoWallpaper extends StatefulWidget {
  const VideoWallpaper({super.key, required this.videoFile});
  final File videoFile;

  @override
  State<VideoWallpaper> createState() => _VideoWallpaperState();
}

class _VideoWallpaperState extends State<VideoWallpaper> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.file(widget.videoFile)
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized, even before the play button has been pressed.
        _controller.setLooping(true);
        _controller.play();
        _controller.setVolume(0.0);
        print(_controller.value.aspectRatio -
            (MIUIConstants.screenWidth / MIUIConstants.screenHeight));
      });
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
            width: MIUIConstants.screenWidth,
            height: MIUIConstants.screenHeight,
            child: VideoPlayer(_controller)));

    // return _controller.value.isInitialized
    //     ? SizedBox(
    //         height: MIUIConstants.screenHeight,
    //         width: MIUIConstants.screenWidth,
    //         child: Transform.scale(
    //           scale: 1.12 +
    //               (_controller.value.aspectRatio -
    //                   (MIUIConstants.screenWidth / MIUIConstants.screenHeight)),
    //           child: ClipRRect(
    //             borderRadius: BorderRadius.circular(20),
    //             child: AspectRatio(
    //                 aspectRatio: 0.56, child: VideoPlayer(_controller)),
    //           ),
    //         ),
    //       )
    //     : Container();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
