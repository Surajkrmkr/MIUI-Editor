class BuffyWallpaper {
  final int id;
  final String name;
  final String designer;
  final String category;
  final String imageUrl;
  final String compressUrl;
  final bool isHot;
  final bool isPremium;
  final List<String> colors;
  final List<String> tags;

  const BuffyWallpaper({
    required this.id,
    required this.name,
    this.designer = 'Buffy',
    required this.category,
    required this.imageUrl,
    required this.compressUrl,
    this.isHot = false,
    this.isPremium = false,
    this.colors = const [],
    this.tags = const [],
  });

  factory BuffyWallpaper.fromJson(Map<String, dynamic> json) {
    return BuffyWallpaper(
      id: json['id'] as int,
      name: json['name'] as String,
      designer: json['designer'] as String? ?? 'Buffy',
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String,
      compressUrl: json['compressUrl'] as String,
      isHot: json['isHot'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      colors: (json['colors'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'designer': designer,
      'category': category,
      'imageUrl': imageUrl,
      'compressUrl': compressUrl,
      'isHot': isHot,
      'isPremium': isPremium,
      'colors': colors,
      'tags': tags,
    };
  }
}