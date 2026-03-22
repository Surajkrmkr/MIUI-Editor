enum PixabayImageType { all, photo, vector, illustration }

class PixabayHit {
  const PixabayHit({
    required this.id, required this.previewUrl,
    required this.webformatUrl, required this.largeImageUrl,
    required this.pageUrl, required this.tags,
  });

  final int id;
  final String previewUrl, webformatUrl, largeImageUrl, pageUrl, tags;

  factory PixabayHit.fromJson(Map<String, dynamic> j) => PixabayHit(
    id:            j['id']           as int,
    previewUrl:    j['previewURL']   as String? ?? '',
    webformatUrl:  j['webformatURL'] as String? ?? '',
    largeImageUrl: j['largeImageURL']as String? ?? '',
    pageUrl:       j['pageURL']      as String? ?? '',
    tags:          j['tags']         as String? ?? '',
  );
}

class PixabayResult {
  const PixabayResult({required this.hits});
  final List<PixabayHit> hits;

  factory PixabayResult.fromJson(Map<String, dynamic> j) => PixabayResult(
    hits: (j['hits'] as List<dynamic>?)
            ?.map((e) => PixabayHit.fromJson(e as Map<String, dynamic>))
            .toList() ?? [],
  );
}
