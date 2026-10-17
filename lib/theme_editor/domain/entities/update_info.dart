class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.notes,
    required this.pageUrl,
    required this.assetName,
    required this.assetUrl,
    required this.checksumUrl,
  });

  final String version;
  final String notes;
  final String pageUrl;
  final String assetName;
  final String assetUrl;
  final String checksumUrl;
}
