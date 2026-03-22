class TagCategory {
  const TagCategory({required this.name, required this.subTags});
  final String name;
  final List<String> subTags;

  factory TagCategory.fromJson(Map<String, dynamic> j) => TagCategory(
    name: j['name'] as String,
    subTags: List<String>.from(j['subTags'] as List<dynamic>),
  );
}

class TagsData {
  const TagsData({required this.categories});
  final List<TagCategory> categories;

  List<String> get flat => categories.expand((c) => c.subTags).toList();

  factory TagsData.fromJson(Map<String, dynamic> j) => TagsData(
    categories: (j['data'] as List<dynamic>)
        .map((e) => TagCategory.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
