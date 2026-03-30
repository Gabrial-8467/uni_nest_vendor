import '../config/vendor_config.dart';

class ProductImageHelper {
  static bool isLocalFilePath(String path) {
    final normalized = path.trim().toLowerCase();
    return normalized.startsWith('/data/') ||
        normalized.startsWith('/storage/') ||
        normalized.startsWith('file://') ||
        RegExp(r'^[a-z]:\\').hasMatch(normalized);
  }

  static String normalizeImagePath(String rawPath) {
    return rawPath
        .trim()
        .replaceAll('\\', '/')
        .replaceAll('"', '')
        .replaceAll("'", '');
  }

  static String imageServerBaseUrl([String? apiBaseUrl]) {
    final effectiveApiBaseUrl = apiBaseUrl ?? VendorConfig.apiBaseUrl;
    final baseUri = Uri.parse(effectiveApiBaseUrl);
    return baseUri.origin;
  }

  static bool _isLoopbackHost(String host) {
    final normalized = host.trim().toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1';
  }

  static bool _isVersionedCloudinaryUrl(Uri uri) {
    return uri.host.toLowerCase().contains('cloudinary.com') &&
        RegExp(r'/upload/v\\d+/').hasMatch(uri.path);
  }

  static String resolveImageUrl(
    String rawPath, {
    String? apiBaseUrl,
  }) {
    final effectiveApiBaseUrl = apiBaseUrl ?? VendorConfig.apiBaseUrl;
    final path = normalizeImagePath(rawPath);
    if (path.isEmpty) {
      return '';
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.tryParse(path);
      if (uri != null && _isLoopbackHost(uri.host)) {
        final reachableBaseUri = Uri.parse(effectiveApiBaseUrl);
        return uri
            .replace(
              scheme: reachableBaseUri.scheme,
              host: reachableBaseUri.host,
              port: reachableBaseUri.hasPort ? reachableBaseUri.port : null,
            )
            .toString();
      }
      return path;
    }

    final baseUrl = imageServerBaseUrl(effectiveApiBaseUrl);
    if (path.startsWith('//')) {
      return '${Uri.parse(baseUrl).scheme}:$path';
    }

    if (path.startsWith('/')) {
      return '$baseUrl$path';
    }

    return '$baseUrl/$path';
  }

  static String? safeRenderUrl(
    String? rawPath, {
    String? apiBaseUrl,
    String? cacheBustKey,
  }) {
    final effectiveApiBaseUrl = apiBaseUrl ?? VendorConfig.apiBaseUrl;
    if (rawPath == null) {
      return null;
    }

    final normalized = normalizeImagePath(rawPath);
    if (normalized.isEmpty) {
      return null;
    }

    if (isLocalFilePath(normalized)) {
      return normalized;
    }

    final resolved = resolveImageUrl(
      normalized,
      apiBaseUrl: effectiveApiBaseUrl,
    );
    if (resolved.isEmpty) {
      return null;
    }

    if (cacheBustKey == null || cacheBustKey.trim().isEmpty) {
      return resolved;
    }

    final uri = Uri.tryParse(resolved);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return resolved;
    }

    if (_isVersionedCloudinaryUrl(uri) && !uri.queryParameters.containsKey('v')) {
      return resolved;
    }

    final updatedQuery = Map<String, String>.from(uri.queryParameters);
    updatedQuery['v'] = cacheBustKey.trim();
    return uri.replace(queryParameters: updatedQuery).toString();
  }
}
