/// Where BuffyWalls keeps its data: a Cloudflare R2 bucket served at
/// [kBuffyPublicHost].
const kBuffyPublicHost = 'buffywalls.teamshadow.tech';
const kBuffyMediaRoot = 'buffy_wall_data';
const kBuffyExternalRoot = 'buffy_external';
const kBuffyCatalogObject = 'buffyjson/buffy.json';
const kBuffyCatalogHistoryPrefix = 'buffyjson/history/';

/// Media files never change once uploaded; a replaced image needs a new name.
const kBuffyMediaCacheControl = 'public, max-age=31536000, immutable';
const kBuffyCatalogCacheControl = 'public, max-age=300';

const _downloadBase = 'https://$kBuffyPublicHost/';

/// Hosts the catalog must no longer point at.
const kBuffyRetiredMediaHosts = {
  'gitlab.com',
  'github.com',
  'raw.githubusercontent.com',
  'dropbox.com',
  'www.dropbox.com',
  'dl.dropboxusercontent.com',
  'firebasestorage.googleapis.com',
};

String buffyImageObject(String category, String fileName) =>
    '$kBuffyMediaRoot/$category/$fileName';

String buffyThumbObject(String category, String name) =>
    '$kBuffyMediaRoot/$category/Thumbnails/$name-small.jpg';

/// Folders for images uploaded from the CMS outside the wallpaper flow.
const kBuffyBannersFolder = 'Banners';
const kBuffyPushFolder = 'PushBanners';

/// A new object in [folder] for [fileName]. The timestamp keeps names unique,
/// since media is cached forever and can't be replaced.
String buffyUploadObject(String folder, String fileName, DateTime now) {
  final dot = fileName.lastIndexOf('.');
  final ext = dot == -1 ? '' : fileName.substring(dot).toLowerCase();
  final base = (dot == -1 ? fileName : fileName.substring(0, dot)).replaceAll(
    RegExp(r'[^A-Za-z0-9_-]+'),
    '_',
  );
  final stamp = now
      .toUtc()
      .toIso8601String()
      .replaceAll(RegExp(r'[^0-9]'), '')
      .substring(0, 14);
  return '$kBuffyMediaRoot/$folder/$base-$stamp$ext';
}

/// Each path segment is percent-encoded except unreserved characters, matching
/// the links already in the catalog (spaces as %20, brackets as %28/%29).
String buffyDownloadUrl(String objectPath) =>
    '$_downloadBase${objectPath.split('/').map(_encodeSegment).join('/')}';

String _encodeSegment(String segment) => Uri.encodeComponent(segment)
    .replaceAllMapped(
      RegExp(r"[!'()*]"),
      (m) => '%${m[0]!.codeUnitAt(0).toRadixString(16).toUpperCase()}',
    );

/// The object a download URL points at, or null if it isn't one of ours.
String? buffyObjectFromUrl(String url) {
  if (!url.startsWith(_downloadBase)) return null;
  final encoded = url.substring(_downloadBase.length).split('?').first;
  try {
    return Uri.decodeComponent(encoded);
  } on ArgumentError {
    return null;
  }
}

String buffyContentType(String fileName) {
  final dot = fileName.lastIndexOf('.');
  final ext = dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
  return switch (ext) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'gif' => 'image/gif',
    _ => 'application/octet-stream',
  };
}
