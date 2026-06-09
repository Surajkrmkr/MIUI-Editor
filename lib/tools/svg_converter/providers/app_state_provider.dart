import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../models/conversion_task.dart';
import '../services/file_scanner.dart';
import '../services/vtracer_service.dart';
import 'settings_provider.dart';

final appStateProvider = NotifierProvider<AppStateNotifier, AppState>(AppStateNotifier.new);

class AppState {
  final bool isVTracerInstalled;
  final bool isCheckingVTracer;
  final String? selectedFolder;
  final List<ConversionTask> tasks;
  final bool isProcessing;
  final bool isCancelled;

  AppState({
    this.isVTracerInstalled = false,
    this.isCheckingVTracer = true,
    this.selectedFolder,
    this.tasks = const [],
    this.isProcessing = false,
    this.isCancelled = false,
  });

  AppState copyWith({
    bool? isVTracerInstalled,
    bool? isCheckingVTracer,
    String? selectedFolder,
    List<ConversionTask>? tasks,
    bool? isProcessing,
    bool? isCancelled,
  }) {
    return AppState(
      isVTracerInstalled: isVTracerInstalled ?? this.isVTracerInstalled,
      isCheckingVTracer: isCheckingVTracer ?? this.isCheckingVTracer,
      selectedFolder: selectedFolder ?? this.selectedFolder,
      tasks: tasks ?? this.tasks,
      isProcessing: isProcessing ?? this.isProcessing,
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  int get totalFiles => tasks.length;
  int get successCount => tasks.where((t) => t.status == TaskStatus.success).length;
  int get failedCount => tasks.where((t) => t.status == TaskStatus.failed).length;
  int get pendingCount => tasks.where((t) => t.status == TaskStatus.pending).length;
  int get processingCount => tasks.where((t) => t.status == TaskStatus.processing).length;
  double get progress => totalFiles == 0 ? 0 : (successCount + failedCount) / totalFiles;
}

class AppStateNotifier extends Notifier<AppState> {
  @override
  AppState build() {
    _checkVTracer();
    return AppState();
  }

  Future<void> _checkVTracer() async {
    final installed = await VTracerService.isVTracerInstalled();
    state = state.copyWith(isVTracerInstalled: installed, isCheckingVTracer: false);
  }

  Future<void> selectFolder(String path) async {
    if (state.isProcessing) return;

    ref.read(settingsProvider.notifier).updateSettings(lastUsedFolder: path);
    state = state.copyWith(selectedFolder: path, tasks: []);

    final files = await FileScanner.scanForImages(path);
    final tasks = files.map((file) {
      return ConversionTask(
        id: file.path,
        inputPath: file.path,
        outputPath: FileScanner.calculateOutputPath(path, file.path),
      );
    }).toList();

    state = state.copyWith(tasks: tasks);
  }

  void cancelProcessing() {
    state = state.copyWith(isCancelled: true);
  }

  Future<void> startProcessing() async {
    if (state.isProcessing || state.tasks.isEmpty || !state.isVTracerInstalled) return;

    state = state.copyWith(isProcessing: true, isCancelled: false);
    
    // Reset all tasks to pending
    final resetTasks = state.tasks.map((t) => t.copyWith(status: TaskStatus.pending, errorMessage: null)).toList();
    state = state.copyWith(tasks: resetTasks);

    final settings = ref.read(settingsProvider);
    const maxConcurrent = 4;
    int currentTaskIndex = 0;

    Future<void> worker() async {
      while (!state.isCancelled) {
        int index = -1;
        // Find next pending task
        for (int i = currentTaskIndex; i < state.tasks.length; i++) {
          if (state.tasks[i].status == TaskStatus.pending) {
            index = i;
            currentTaskIndex = i + 1; // Update global index for optimization
            break;
          }
        }

        if (index == -1) break; // No more pending tasks

        // Mark as processing
        _updateTaskStatus(index, TaskStatus.processing);

        final task = state.tasks[index];
        final stopwatch = Stopwatch()..start();
        
        try {
          // Ensure output directory exists
          final outDir = Directory(p.dirname(task.outputPath));
          if (!await outDir.exists()) {
            await outDir.create(recursive: true);
          }

          final inputFile = File(task.inputPath);
          final sizeBefore = await inputFile.length();

          await VTracerService.convert(
            input: task.inputPath,
            output: task.outputPath,
            mode: settings.mode,
            colorPrecision: settings.colorPrecision,
            filterSpeckle: settings.filterSpeckle,
          );

          final outputFile = File(task.outputPath);
          final sizeAfter = await outputFile.exists() ? await outputFile.length() : 0;

          stopwatch.stop();
          _updateTask(index, task.copyWith(
            status: TaskStatus.success,
            fileSizeBefore: sizeBefore,
            fileSizeAfter: sizeAfter,
            duration: stopwatch.elapsed,
          ));
        } catch (e) {
          stopwatch.stop();
          _updateTask(index, task.copyWith(
            status: TaskStatus.failed,
            errorMessage: e.toString(),
            duration: stopwatch.elapsed,
          ));
        }
      }
    }

    // Spawn 4 workers
    final workers = List.generate(maxConcurrent, (_) => worker());
    await Future.wait(workers);

    state = state.copyWith(isProcessing: false, isCancelled: false);
  }

  void _updateTaskStatus(int index, TaskStatus status) {
    final newTasks = List<ConversionTask>.from(state.tasks);
    newTasks[index] = newTasks[index].copyWith(status: status);
    state = state.copyWith(tasks: newTasks);
  }

  void _updateTask(int index, ConversionTask task) {
    final newTasks = List<ConversionTask>.from(state.tasks);
    newTasks[index] = task;
    state = state.copyWith(tasks: newTasks);
  }
}