/// Where a font used by a lockscreen element comes from.
enum FontSource { system, google, remote }

/// An element's `font` string, split into its parts.
///
/// The editor stores fonts as one string: `gf:Family` (Google Fonts),
/// `rf:Family|https://…ttf` (downloaded from a catalog) or a plain family name
/// (a font from the font API, or one installed on the machine).
class FontRef {
  const FontRef._(this.ref, this.source, this.family, this.url);

  factory FontRef.parse(String ref) {
    if (ref.startsWith('gf:') && ref.length > 3) {
      return FontRef._(ref, FontSource.google, ref.substring(3), null);
    }
    if (ref.startsWith('rf:')) {
      final body = ref.substring(3);
      final split = body.indexOf('|');
      if (split > 0 && split < body.length - 1) {
        return FontRef._(
          ref,
          FontSource.remote,
          body.substring(0, split),
          body.substring(split + 1),
        );
      }
    }
    return FontRef._(ref, FontSource.system, ref, null);
  }

  final String ref;
  final FontSource source;
  final String family;
  final String? url;

  /// Families the renderer carries itself; any other font needs a file, since
  /// a headless render can't see the fonts installed on the machine.
  static const builtIn = {'Roboto', 'RobotoCondensed'};

  /// Whether the build needs a font file for this font to draw real glyphs.
  bool get needsFile =>
      source != FontSource.system ||
      !(family.isEmpty || builtIn.contains(family));
}
