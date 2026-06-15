import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../domain/models/upscale_options.dart';
import '../services/upscaler_service.dart';
import 'upscaler_settings_provider.dart';

class UpscalerState {
  final bool isBinaryInstalled;
  final bool isCheckingBinary;
  final String? inputPath;
  final String? outputPath;
  final String? batchFolderPath;
  final UpscalePreset preset;
  final UpscaleScale scale;
  final OutputFormat format;
  final List<UpscaleTask> queue;
  final bool isProcessing;
  final double progress;
  final List<String> logs;
  final String? error;

  UpscalerState({
    this.isBinaryInstalled = false,
    this.isCheckingBinary = true,
    this.inputPath,
    this.outputPath,
    this.batchFolderPath,
    this.preset = UpscalePreset.standard,
    this.scale = UpscaleScale.x4,
    this.format = OutputFormat.png,
    this.queue = const [],
    this.isProcessing = false,
    this.progress = 0.0,
    this.logs = const [],
    this.error,
  });

  UpscalerState copyWith({
    bool? isBinaryInstalled,
    bool? isCheckingBinary,
    String? inputPath,
    String? outputPath,
    String? batchFolderPath,
    UpscalePreset? preset,
    UpscaleScale? scale,
    OutputFormat? format,
    List<UpscaleTask>? queue,
    bool? isProcessing,
    double? progress,
    List<String>? logs,
    String? error,
  }) {
    return UpscalerState(
      isBinaryInstalled: isBinaryInstalled ?? this.isBinaryInstalled,
      isCheckingBinary: isCheckingBinary ?? this.isCheckingBinary,
      inputPath: inputPath ?? this.inputPath,
      outputPath: outputPath ?? this.outputPath,
      batchFolderPath: batchFolderPath ?? this.batchFolderPath,
      preset: preset ?? this.preset,
      scale: scale ?? this.scale,
      format: format ?? this.format,
      queue: queue ?? this.queue,
      isProcessing: isProcessing ?? this.isProcessing,
      progress: progress ?? this.progress,
      logs: logs ?? this.logs,
      error: error,
    );
  }

  int get totalTasks => queue.length;
  int get completedTasks => queue.where((t) => t.status == UpscaleTaskStatus.success || t.status == UpscaleTaskStatus.failed).length;
}

class UpscalerNotifier extends Notifier<UpscalerState> {
  @override
  UpscalerState build() {
    checkInstallation();
    return UpscalerState();
  }

  Future<void> checkInstallation() async {
    final settings = ref.read(upscalerSettingsProvider);
    final installed = await UpscalerService.isBinaryInstalled(
      customPath: settings.customBinaryPath,
      customModelsPath: settings.customModelsPath,
    );
    state = state.copyWith(isBinaryInstalled: installed, isCheckingBinary: false);
  }

  void setInputPath(String? path) {
    state = state.copyWith(
      inputPath: path, 
      outputPath: null, 
      batchFolderPath: null,
      logs: [], 
      progress: 0, 
      queue: []
    );
  }

  void setPreset(UpscalePreset preset) => state = state.copyWith(preset: preset);
  void setScale(UpscaleScale scale) => state = state.copyWith(scale: scale);
  void setFormat(OutputFormat format) => state = state.copyWith(format: format);

  void loadBatch(String folderPath) {
    if (state.isProcessing || !state.isBinaryInstalled) return;

    final dir = Directory(folderPath);
    if (!dir.existsSync()) return;

    final files = dir.listSync().whereType<File>().where((f) {
      final ext = p.extension(f.path).toLowerCase();
      return ['.png', '.jpg', '.jpeg', '.webp'].contains(ext);
    }).toList();

    if (files.isEmpty) {
      state = state.copyWith(
        error: 'No valid images found in folder',
        logs: ['Empty folder: $folderPath']
      );
      return;
    }

    final tasks = files.map((f) => UpscaleTask(
      id: f.path,
      inputPath: f.path,
      outputPath: '', // Set during processing
    )).toList();

    state = state.copyWith(
      inputPath: null,
      outputPath: null,
      batchFolderPath: folderPath,
      queue: tasks,
      logs: ['Batch folder loaded: $folderPath', '${tasks.length} files detected'],
      progress: 0,
      isProcessing: false,
      error: null,
    );
  }

  Future<void> startUpscale() async {
    if (state.isProcessing || !state.isBinaryInstalled) return;

    if (state.inputPath != null) {
      await _processSingleUpscale();
    } else if (state.queue.isNotEmpty && state.batchFolderPath != null) {
      await _processBatchUpscale();
    }
  }

  Future<void> _processSingleUpscale() async {
    final settings = ref.read(upscalerSettingsProvider);

    state = state.copyWith(
      isProcessing: true,
      progress: 0,
      logs: ['Starting upscale process...'],
      error: null,
    );

    try {
      final baseDir = p.dirname(state.inputPath!);
      final fileName = p.basenameWithoutExtension(state.inputPath!);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = p.join(
        baseDir, 
        '${fileName}_upscaled_$timestamp.${state.format.label.toLowerCase()}'
      );

      final stream = UpscalerService.upscale(
        input: state.inputPath!,
        output: outPath,
        preset: state.preset,
        scale: state.scale,
        format: state.format,
        modelsDir: settings.customModelsPath,
        onLog: (log) {
          state = state.copyWith(logs: [...state.logs, log]);
        },
      );

      await for (final progress in stream) {
        state = state.copyWith(progress: progress);
      }

      state = state.copyWith(
        isProcessing: false,
        progress: 1.0,
        outputPath: outPath,
        logs: [...state.logs, 'Upscale complete: $outPath'],
      );
    } catch (e) {
      _handleError(e);
    }
  }

  Future<void> _processBatchUpscale() async {
    final settings = ref.read(upscalerSettingsProvider);
    final folderPath = state.batchFolderPath!;

    final outDir = Directory(p.join(folderPath, 'upscaled_${DateTime.now().millisecondsSinceEpoch}'));
    await outDir.create(recursive: true);

    // Re-initialize tasks with correct output paths
    final tasks = state.queue.map((t) => UpscaleTask(
      id: t.id,
      inputPath: t.inputPath,
      outputPath: p.join(outDir.path, p.basename(t.inputPath)),
    )).toList();

    state = state.copyWith(
      isProcessing: true,
      progress: 0,
      queue: tasks,
      logs: ['Starting batch upscale for ${tasks.length} files...', 'Destination: ${outDir.path}'],
      error: null,
    );

    for (int i = 0; i < tasks.length; i++) {
      final task = tasks[i];
      _updateTaskStatus(i, UpscaleTaskStatus.processing);
      
      try {
        final stream = UpscalerService.upscale(
          input: task.inputPath,
          output: task.outputPath,
          preset: state.preset,
          scale: state.scale,
          format: state.format,
          modelsDir: settings.customModelsPath,
          onLog: (log) {
             _updateTaskLogs(i, log);
          }
        );

        await for (final p in stream) {
          final totalProgress = (i + p) / tasks.length;
          state = state.copyWith(progress: totalProgress);
        }
        
        _updateTaskStatus(i, UpscaleTaskStatus.success);
      } catch (e) {
        _updateTaskError(i, e.toString());
      }
    }

    state = state.copyWith(
      isProcessing: false,
      progress: 1.0,
      logs: [...state.logs, 'Batch upscale complete. Saved to: ${outDir.path}'],
    );
  }

  void _handleError(dynamic e) {
    String errorMessage = e.toString();
    if (e is ProcessException) {
      errorMessage = '''Failed to launch upscaler: ${e.message}
Executable: ${e.executable}''';
    }
    state = state.copyWith(
      isProcessing: false,
      error: errorMessage,
      logs: [...state.logs, 'Error: $errorMessage'],
    );
  }

  void _updateTaskStatus(int index, UpscaleTaskStatus status) {
    final newQueue = List<UpscaleTask>.from(state.queue);
    newQueue[index] = newQueue[index].copyWith(status: status);
    state = state.copyWith(queue: newQueue);
  }

  void _updateTaskLogs(int index, String log) {
    final newQueue = List<UpscaleTask>.from(state.queue);
    newQueue[index] = newQueue[index].copyWith(logs: [...newQueue[index].logs, log]);
    state = state.copyWith(queue: newQueue, logs: [...state.logs, log]);
  }

  void _updateTaskError(int index, String error) {
    final newQueue = List<UpscaleTask>.from(state.queue);
    newQueue[index] = newQueue[index].copyWith(status: UpscaleTaskStatus.failed, errorMessage: error);
    state = state.copyWith(queue: newQueue, logs: [...state.logs, 'Task Failed: $error']);
  }

  void clear() {
    state = UpscalerState(
      isBinaryInstalled: state.isBinaryInstalled,
      isCheckingBinary: false,
      inputPath: null,
      outputPath: null,
      batchFolderPath: null,
      queue: [],
      logs: [],
      progress: 0,
      error: null,
    );
  }
}

final upscalerProvider = NotifierProvider<UpscalerNotifier, UpscalerState>(() {
  return UpscalerNotifier();
});
