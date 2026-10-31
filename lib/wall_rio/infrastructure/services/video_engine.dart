import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'thumbnail_engine.dart';

class VideoEngineException implements Exception {
  VideoEngineException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Live wallpaper processing with ffmpeg, matching wallrio_live/process_videos.py:
/// a 2 Mbps preview scaled to fit 1280×720 and a JPEG frame at 1 s fitting 960×540.
class VideoEngine {
  // GUI apps on macOS don't inherit the shell PATH, so look in the usual places.
  static const _searchDirs = ['/opt/homebrew/bin', '/usr/local/bin', '/usr/bin'];

  static String? _ffmpeg;
  static String? _ffprobe;

  static String _find(String tool) {
    final exe = Platform.isWindows ? '$tool.exe' : tool;
    final dirs = [
      ..._searchDirs,
      ...?Platform.environment['PATH']?.split(Platform.isWindows ? ';' : ':'),
    ];
    for (final dir in dirs) {
      final path = '$dir${Platform.pathSeparator}$exe';
      if (File(path).existsSync()) return path;
    }
    throw VideoEngineException(
      '$tool not found. Install ffmpeg (macOS: brew install ffmpeg) to upload live wallpapers.',
    );
  }

  static String get ffmpeg => _ffmpeg ??= _find('ffmpeg');
  static String get ffprobe => _ffprobe ??= _find('ffprobe');

  /// Display size of the first video stream (rotation applied), or null if
  /// the file has no readable video.
  static Future<ImageSize?> probe(String path) async {
    final result = await Process.run(ffprobe, [
      '-v', 'error',
      '-select_streams', 'v:0',
      '-show_entries', 'stream=width,height:stream_side_data=rotation:stream_tags=rotate',
      '-of', 'json',
      path,
    ]);
    if (result.exitCode != 0) return null;
    final streams = (jsonDecode('${result.stdout}') as Map)['streams'] as List?;
    if (streams == null || streams.isEmpty) return null;
    final stream = streams.first as Map;
    final width = stream['width'] as int?;
    final height = stream['height'] as int?;
    if (width == null || height == null) return null;

    // Phones record portrait video as landscape plus a rotation flag.
    var rotation = int.tryParse('${(stream['tags'] as Map?)?['rotate'] ?? 0}') ?? 0;
    for (final data in stream['side_data_list'] as List? ?? const []) {
      if (data is Map && data['rotation'] != null) {
        rotation = int.tryParse('${data['rotation']}') ?? rotation;
      }
    }
    final sideways = rotation.abs() % 180 == 90;
    return sideways ? ImageSize(height, width) : ImageSize(width, height);
  }

  static Future<Uint8List> preview(String inputPath) => _run('mp4', (out) => [
        '-i', inputPath,
        '-vf', 'scale=1280:720:force_original_aspect_ratio=decrease:force_divisible_by=2',
        '-b:v', '2000k',
        '-maxrate', '2000k',
        '-bufsize', '4000k',
        '-c:a', 'aac',
        '-b:a', '128k',
        // Lets players start before the whole file has arrived.
        '-movflags', '+faststart',
        '-y', out,
      ]);

  static Future<Uint8List> thumbnail(String inputPath) => _run('jpg', (out) => [
        '-ss', '1',
        '-i', inputPath,
        '-vf', 'scale=960:540:force_original_aspect_ratio=decrease:force_divisible_by=2:flags=lanczos',
        '-vframes', '1',
        '-q:v', '1',
        '-y', out,
      ]);

  /// Runs ffmpeg writing to a temp file and returns its bytes.
  static Future<Uint8List> _run(String extension, List<String> Function(String out) args) async {
    final dir = await Directory.systemTemp.createTemp('wallrio_video');
    final out = '${dir.path}${Platform.pathSeparator}out.$extension';
    try {
      final result = await Process.run(ffmpeg, args(out));
      final file = File(out);
      if (result.exitCode != 0 || !file.existsSync() || file.lengthSync() == 0) {
        final log = '${result.stderr}'.trim().split('\n');
        throw VideoEngineException(
          'ffmpeg failed: ${log.skip(log.length > 4 ? log.length - 4 : 0).join('\n')}',
        );
      }
      return await file.readAsBytes();
    } finally {
      await dir.delete(recursive: true);
    }
  }
}
