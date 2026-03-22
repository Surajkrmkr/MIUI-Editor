import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Wrapper around the Upscayl Cloud REST API.
///
/// Workflow (as per https://docs.upscayl.org):
///   1. POST /start-upscaling-task  →  multipart/form-data, receives {taskId}
///   2. POST /get-task-status       →  JSON {taskId}, poll until complete
///   3. Download the output URL returned in the completed status response.
///
/// Authentication: X-API-Key header.
class UpscaylService {
  final String apiKey;

  static const String _baseUrl = 'https://api.upscayl.org';
  static const Duration _pollInterval = Duration(seconds: 3);
  static const Duration _timeout = Duration(minutes: 5);

  UpscaylService({required this.apiKey});

  bool get isConfigured => apiKey.isNotEmpty;

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Upscale [imageBytes] and return the upscaled image bytes.
  ///
  /// [model] one of: 'realesrgan-x4plus', 'realesrgan-x4plus-anime',
  ///                 'realesrnet-x4plus', 'esrgan-x4'
  /// [scale] upscale factor, typically 4.
  Future<Uint8List> upscale({
    required Uint8List imageBytes,
    String model = 'realesrgan-x4plus',
    int scale = 4,
    void Function(String)? onStatus,
  }) async {
    if (!isConfigured) throw Exception('Upscayl API key is not configured.');

    onStatus?.call('Submitting upscale task…');
    final taskId = await _startTask(
      imageBytes: imageBytes,
      model: model,
      scale: scale,
    );

    onStatus?.call('Upscaling in progress…');
    final outputUrl = await _pollUntilDone(taskId, onStatus: onStatus);

    onStatus?.call('Downloading upscaled image…');
    return _downloadImage(outputUrl);
  }

  // ─── Private helpers ─────────────────────────────────────────────────────

  /// POST /start-upscaling-task
  /// multipart/form-data: file, model, scale
  /// Returns taskId string.
  Future<String> _startTask({
    required Uint8List imageBytes,
    required String model,
    required int scale,
  }) async {
    final uri = Uri.parse('$_baseUrl/start-upscaling-task');

    final request = http.MultipartRequest('POST', uri)
      ..headers['X-API-Key'] = apiKey
      ..fields['model'] = model
      ..fields['scale'] = scale.toString()
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'input.jpg',
      ));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200 && streamed.statusCode != 201) {
      throw Exception(
          'Upscayl start-task error ${streamed.statusCode}: $body');
    }

    final data = jsonDecode(body) as Map<String, dynamic>;
    final taskId = data['taskId'] as String?;
    if (taskId == null || taskId.isEmpty) {
      throw Exception('Upscayl did not return a taskId. Response: $body');
    }
    return taskId;
  }

  /// POST /get-task-status with JSON body {taskId}.
  /// Polls until status == 'completed' or timeout.
  Future<String> _pollUntilDone(
    String taskId, {
    void Function(String)? onStatus,
  }) async {
    final uri = Uri.parse('$_baseUrl/get-task-status');
    final deadline = DateTime.now().add(_timeout);

    while (DateTime.now().isBefore(deadline)) {
      await Future.delayed(_pollInterval);

      final response = await http.post(
        uri,
        headers: {
          'X-API-Key': apiKey,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'taskId': taskId}),
      );

      if (response.statusCode != 200) {
        throw Exception(
            'Upscayl get-task-status error ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final status = (data['status'] ?? data['state'] ?? '') as String;
      final progress = data['progress'];

      if (progress != null) {
        onStatus?.call('Upscaling… $progress%');
      }

      switch (status.toLowerCase()) {
        case 'completed':
        case 'done':
        case 'success':
          final outputUrl =
              data['outputUrl'] ?? data['output_url'] ?? data['url'];
          if (outputUrl == null) {
            throw Exception('Task completed but no output URL found.');
          }
          return outputUrl as String;

        case 'failed':
        case 'error':
          throw Exception(
              'Upscayl task failed: ${data['error'] ?? 'unknown error'}');

        default:
          // still pending / processing — keep polling
          continue;
      }
    }

    throw Exception('Upscayl task timed out after ${_timeout.inMinutes} min.');
  }

  Future<Uint8List> _downloadImage(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw Exception('Failed to download upscaled image: ${response.statusCode}');
    }
    return response.bodyBytes;
  }
}
