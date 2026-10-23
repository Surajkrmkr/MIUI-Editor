import 'dart:io';

import 'package:flutter/services.dart';

/// Adds a bundled CA list on Windows, where the system root store can lack
/// GitHub's chain (CERTIFICATE_VERIFY_FAILED).
class TrustedRoots {
  TrustedRoots._();

  static SecurityContext? _context;

  static Future<void> init() async {
    if (!Platform.isWindows) return;
    try {
      final pem = await rootBundle.load('assets/certs/cacert.pem');
      _context = SecurityContext(withTrustedRoots: true)
        ..setTrustedCertificatesBytes(
          pem.buffer.asUint8List(pem.offsetInBytes, pem.lengthInBytes),
        );
    } catch (_) {
      // Keep the system trust store only.
    }
  }

  static HttpClient newHttpClient() => HttpClient(context: _context);
}
