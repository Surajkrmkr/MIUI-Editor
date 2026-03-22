class Wallpaper {
  final String id;
  final String source; // 'pexels', 'unsplash', 'pixabay', 'firefly'
  final String photographer;
  final String photographerUrl;
  final String originalUrl;
  final String largeUrl;
  final String mediumUrl;
  final String smallUrl;
  final int width;
  final int height;
  final String? description;
  final List<String>? tags;
  final bool isFavorite;
  final DateTime? downloadedAt;
  final String? localPath;

  const Wallpaper({
    required this.id,
    required this.source,
    required this.photographer,
    required this.photographerUrl,
    required this.originalUrl,
    required this.largeUrl,
    required this.mediumUrl,
    required this.smallUrl,
    required this.width,
    required this.height,
    this.description,
    this.tags,
    this.isFavorite = false,
    this.downloadedAt,
    this.localPath,
  });

  factory Wallpaper.fromJson(Map<String, dynamic> json) {
    return Wallpaper(
      id: json['id'] as String,
      source: json['source'] as String,
      photographer: json['photographer'] as String,
      photographerUrl: json['photographerUrl'] as String,
      originalUrl: json['originalUrl'] as String,
      largeUrl: json['largeUrl'] as String,
      mediumUrl: json['mediumUrl'] as String,
      smallUrl: json['smallUrl'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      description: json['description'] as String?,
      tags:
          json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      isFavorite: json['isFavorite'] as bool? ?? false,
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.parse(json['downloadedAt'] as String)
          : null,
      localPath: json['localPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source': source,
      'photographer': photographer,
      'photographerUrl': photographerUrl,
      'originalUrl': originalUrl,
      'largeUrl': largeUrl,
      'mediumUrl': mediumUrl,
      'smallUrl': smallUrl,
      'width': width,
      'height': height,
      'description': description,
      'tags': tags,
      'isFavorite': isFavorite,
      'downloadedAt': downloadedAt?.toIso8601String(),
      'localPath': localPath,
    };
  }

  @override
  String toString() =>
      'Wallpaper(id: $id, source: $source, photographer: $photographer, photographerUrl: $photographerUrl, originalUrl: $originalUrl, largeUrl: $largeUrl, mediumUrl: $mediumUrl, smallUrl: $smallUrl, width: $width, height: $height, description: $description, tags: $tags, isFavorite: $isFavorite, downloadedAt: $downloadedAt, localPath: $localPath)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallpaper &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          source == other.source &&
          photographer == other.photographer &&
          photographerUrl == other.photographerUrl &&
          originalUrl == other.originalUrl &&
          largeUrl == other.largeUrl &&
          mediumUrl == other.mediumUrl &&
          smallUrl == other.smallUrl &&
          width == other.width &&
          height == other.height &&
          description == other.description &&
          tags == other.tags &&
          isFavorite == other.isFavorite &&
          downloadedAt == other.downloadedAt &&
          localPath == other.localPath;

  @override
  int get hashCode =>
      id.hashCode ^
      source.hashCode ^
      photographer.hashCode ^
      photographerUrl.hashCode ^
      originalUrl.hashCode ^
      largeUrl.hashCode ^
      mediumUrl.hashCode ^
      smallUrl.hashCode ^
      width.hashCode ^
      height.hashCode ^
      description.hashCode ^
      tags.hashCode ^
      isFavorite.hashCode ^
      downloadedAt.hashCode ^
      localPath.hashCode;

  Wallpaper copyWith({
    String? id,
    String? source,
    String? photographer,
    String? photographerUrl,
    String? originalUrl,
    String? largeUrl,
    String? mediumUrl,
    String? smallUrl,
    int? width,
    int? height,
    String? description,
    List<String>? tags,
    bool? isFavorite,
    DateTime? downloadedAt,
    String? localPath,
  }) {
    return Wallpaper(
      id: id ?? this.id,
      source: source ?? this.source,
      photographer: photographer ?? this.photographer,
      photographerUrl: photographerUrl ?? this.photographerUrl,
      originalUrl: originalUrl ?? this.originalUrl,
      largeUrl: largeUrl ?? this.largeUrl,
      mediumUrl: mediumUrl ?? this.mediumUrl,
      smallUrl: smallUrl ?? this.smallUrl,
      width: width ?? this.width,
      height: height ?? this.height,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      localPath: localPath ?? this.localPath,
    );
  }
}
