import 'package:hive/hive.dart';

// Plain Dart models — no code-gen. Manual Hive TypeAdapters below.

class SavedFilePath {
  const SavedFilePath({
    required this.path,
    required this.lastOpened,
    required this.label,
  });

  final String path;
  final DateTime lastOpened;
  final String label;

  SavedFilePath copyWith({
    String? path,
    DateTime? lastOpened,
    String? label,
  }) =>
      SavedFilePath(
        path: path ?? this.path,
        lastOpened: lastOpened ?? this.lastOpened,
        label: label ?? this.label,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedFilePath &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          lastOpened == other.lastOpened &&
          label == other.label;

  @override
  int get hashCode => Object.hash(path, lastOpened, label);
}

class LocalVersion {
  const LocalVersion({
    required this.id,
    required this.filePath,
    required this.timestamp,
    required this.commitMessage,
    required this.jsonData,
  });

  final String id;
  final String filePath;
  final DateTime timestamp;
  final String commitMessage;
  final String jsonData;

  LocalVersion copyWith({
    String? id,
    String? filePath,
    DateTime? timestamp,
    String? commitMessage,
    String? jsonData,
  }) =>
      LocalVersion(
        id: id ?? this.id,
        filePath: filePath ?? this.filePath,
        timestamp: timestamp ?? this.timestamp,
        commitMessage: commitMessage ?? this.commitMessage,
        jsonData: jsonData ?? this.jsonData,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalVersion &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          filePath == other.filePath &&
          timestamp == other.timestamp &&
          commitMessage == other.commitMessage &&
          jsonData == other.jsonData;

  @override
  int get hashCode =>
      Object.hash(id, filePath, timestamp, commitMessage, jsonData);
}

// ── Hive TypeAdapters ─────────────────────────────────────────────────────────

class SavedFilePathImplAdapter extends TypeAdapter<SavedFilePath> {
  @override
  final int typeId = 0;

  @override
  SavedFilePath read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedFilePath(
      path: fields[0] as String,
      lastOpened: fields[1] as DateTime,
      label: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, SavedFilePath obj) {
    writer.writeByte(3);
    writer.writeByte(0);
    writer.write(obj.path);
    writer.writeByte(1);
    writer.write(obj.lastOpened);
    writer.writeByte(2);
    writer.write(obj.label);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedFilePathImplAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalVersionImplAdapter extends TypeAdapter<LocalVersion> {
  @override
  final int typeId = 1;

  @override
  LocalVersion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalVersion(
      id: fields[0] as String,
      filePath: fields[1] as String,
      timestamp: fields[2] as DateTime,
      commitMessage: fields[3] as String,
      jsonData: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, LocalVersion obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.filePath);
    writer.writeByte(2);
    writer.write(obj.timestamp);
    writer.writeByte(3);
    writer.write(obj.commitMessage);
    writer.writeByte(4);
    writer.write(obj.jsonData);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalVersionImplAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
