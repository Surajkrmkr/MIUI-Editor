class SearchParams {
  final String key;
  final int page;
  final int perPage;
  final String? orientation; // 'landscape', 'portrait', 'square'
  final String? color;
  final String? locale;

  const SearchParams({
    this.key = "",
    this.page = 1,
    this.perPage = 20,
    this.orientation,
    this.color,
    this.locale,
  });

  factory SearchParams.fromJson(Map<String, dynamic> json) {
    return SearchParams(
      key: json['key'] as String? ?? "",
      page: json['page'] as int? ?? 1,
      perPage: json['perPage'] as int? ?? 20,
      orientation: json['orientation'] as String?,
      color: json['color'] as String?,
      locale: json['locale'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'page': page,
      'perPage': perPage,
      'orientation': orientation,
      'color': color,
      'locale': locale,
    };
  }

  @override
  String toString() =>
      'SearchParams(page: $page, perPage: $perPage, orientation: $orientation, color: $color, locale: $locale)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchParams &&
          runtimeType == other.runtimeType &&
          key == other.key &&
          page == other.page &&
          perPage == other.perPage &&
          orientation == other.orientation &&
          color == other.color &&
          locale == other.locale;

  @override
  int get hashCode =>
      key.hashCode ^
      page.hashCode ^
      perPage.hashCode ^
      orientation.hashCode ^
      color.hashCode ^
      locale.hashCode;

  SearchParams copyWith({
    String? key,
    int? page,
    int? perPage,
    String? orientation,
    String? color,
    String? locale,
  }) {
    return SearchParams(
      key: key ?? this.key,
      page: page ?? this.page,
      perPage: perPage ?? this.perPage,
      orientation: orientation ?? this.orientation,
      color: color ?? this.color,
      locale: locale ?? this.locale,
    );
  }
}
