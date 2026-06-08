enum TaskStatus { pending, processing, success, failed }

class ConversionTask {
  final String id;
  final String inputPath;
  final String outputPath;
  final TaskStatus status;
  final String? errorMessage;
  final int? fileSizeBefore;
  final int? fileSizeAfter;
  final Duration? duration;

  ConversionTask({
    required this.id,
    required this.inputPath,
    required this.outputPath,
    this.status = TaskStatus.pending,
    this.errorMessage,
    this.fileSizeBefore,
    this.fileSizeAfter,
    this.duration,
  });

  ConversionTask copyWith({
    TaskStatus? status,
    String? errorMessage,
    int? fileSizeBefore,
    int? fileSizeAfter,
    Duration? duration,
  }) {
    return ConversionTask(
      id: id,
      inputPath: inputPath,
      outputPath: outputPath,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      fileSizeBefore: fileSizeBefore ?? this.fileSizeBefore,
      fileSizeAfter: fileSizeAfter ?? this.fileSizeAfter,
      duration: duration ?? this.duration,
    );
  }
}