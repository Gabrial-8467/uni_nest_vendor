import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:image_picker/image_picker.dart';
import '../utils/secure_logger.dart';

class ImageUploadResult {
  final bool success;
  final String? imageUrl;
  final String? error;
  final int? originalSize;
  final int? compressedSize;

  ImageUploadResult({
    required this.success,
    this.imageUrl,
    this.error,
    this.originalSize,
    this.compressedSize,
  });

  factory ImageUploadResult.success({
    required String imageUrl,
    int? originalSize,
    int? compressedSize,
  }) {
    return ImageUploadResult(
      success: true,
      imageUrl: imageUrl,
      originalSize: originalSize,
      compressedSize: compressedSize,
    );
  }

  factory ImageUploadResult.failure(String error) {
    return ImageUploadResult(success: false, error: error);
  }
}

class ImageUploadService {
  static const int _maxWidth = 800;
  static const int _maxHeight = 800;
  static const int _targetQuality = 70;
  static const int _maxFileSizeBytes = 100 * 1024; // 100KB

  /// Optimize and compress an image file
  static Future<File?> optimizeImage(File imageFile) async {
    try {
      final originalSize = await imageFile.length();
      SecureLogger.info('Original image size: ${originalSize ~/ 1024}KB');

      // Read the original image
      Uint8List? imageBytes = await imageFile.readAsBytes();

      // Compress the image
      final compressedResult = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: _maxWidth,
        minHeight: _maxHeight,
        quality: _targetQuality,
        format: CompressFormat.jpeg,
      );

      var compressedBytes = compressedResult;

      // If compressed size is still too large, try more aggressive compression
      if (compressedBytes.length > _maxFileSizeBytes) {
        compressedBytes = await _aggressiveCompress(imageBytes);
      }

      // Save compressed image to temp file
      final tempDir = imageFile.parent;
      final fileName =
          'compressed_${path.basenameWithoutExtension(imageFile.path)}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final compressedFile = File(path.join(tempDir.path, fileName));

      await compressedFile.writeAsBytes(compressedBytes);

      final compressedSize = compressedBytes.length;
      final compressionRatio =
          ((originalSize - compressedSize) / originalSize * 100)
              .toStringAsFixed(1);

      SecureLogger.info(
        'Image optimized: ${originalSize ~/ 1024}KB -> ${compressedSize ~/ 1024}KB '
        '($compressionRatio% reduction)',
      );

      return compressedFile;
    } catch (e) {
      SecureLogger.error('Failed to optimize image', error: e);
      return imageFile; // Return original if optimization fails
    }
  }

  /// More aggressive compression for oversized images
  static Future<Uint8List> _aggressiveCompress(Uint8List imageBytes) async {
    Uint8List? compressed = imageBytes;
    int quality = 70;

    while (compressed != null &&
        compressed.length > _maxFileSizeBytes &&
        quality > 30) {
      quality -= 10;
      compressed = await FlutterImageCompress.compressWithList(
        imageBytes,
        minWidth: 800,
        minHeight: 800,
        quality: quality,
        format: CompressFormat.jpeg,
      );
    }

    return compressed ?? imageBytes;
  }

  /// Upload multiple images to Cloudinary via backend (parallel)
  static Future<List<ImageUploadResult>> uploadImages(
    List<File> imageFiles, {
    required String authToken,
    required String baseUrl,
    String endpoint = '/api/upload/images',
  }) async {
    final uploads = imageFiles
        .map(
          (imageFile) => uploadSingleImage(
            imageFile,
            authToken: authToken,
            baseUrl: baseUrl,
            endpoint: endpoint,
          ),
        )
        .toList();

    return await Future.wait(uploads);
  }

  /// Upload a single optimized image
  static Future<ImageUploadResult> uploadSingleImage(
    File imageFile, {
    required String authToken,
    required String baseUrl,
    String endpoint = '/api/upload/images',
  }) async {
    try {
      // Optimize the image first
      final optimizedFile = await optimizeImage(imageFile);
      final originalSize = await imageFile.length();
      final compressedSize = optimizedFile != null
          ? await optimizedFile.length()
          : null;

      final uri = Uri.parse('$baseUrl$endpoint');
      final imageBytes = await optimizedFile!.readAsBytes();
      final fileName = path.basename(optimizedFile.path);
      SecureLogger.info('Uploading to URL: $uri');

      final response =
          await _sendMultipartUpload(
            uri: uri,
            authToken: authToken,
            imageBytes: imageBytes,
            fileName: fileName,
            fileFieldName: 'images',
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw TimeoutException('Image upload timed out after 30s'),
          );

      SecureLogger.info(
        'Upload response status (images): ${response.statusCode}',
      );

      // Clean up temp file if it was created
      if (optimizedFile.path != imageFile.path) {
        try {
          await optimizedFile.delete();
        } catch (e) {
          SecureLogger.warning('Failed to delete temp file: $e');
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = _decodeResponse(response.body);

        if (responseData['success'] == true) {
          final imageUrl = _extractImageUrl(responseData);

          if (imageUrl != null) {
            SecureLogger.info('Image uploaded successfully: $imageUrl');
            return ImageUploadResult.success(
              imageUrl: imageUrl,
              originalSize: originalSize,
              compressedSize: compressedSize,
            );
          } else {
            return ImageUploadResult.failure('No image URL in response');
          }
        } else {
          return ImageUploadResult.failure(
            responseData['message'] ?? 'Upload failed',
          );
        }
      } else {
        return ImageUploadResult.failure(
          'HTTP ${response.statusCode}: ${response.reasonPhrase ?? 'Upload failed'}',
        );
      }
    } catch (e) {
      SecureLogger.error('Image upload failed', error: e);
      return ImageUploadResult.failure('Upload error: $e');
    }
  }

  static Future<http.Response> _sendMultipartUpload({
    required Uri uri,
    required String authToken,
    required Uint8List imageBytes,
    required String fileName,
    required String fileFieldName,
  }) async {
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $authToken';
    request.files.add(
      http.MultipartFile.fromBytes(
        fileFieldName,
        imageBytes,
        filename: fileName,
      ),
    );

    SecureLogger.info('Request headers: ${request.headers}');
    SecureLogger.info('Request files count: ${request.files.length}');
    SecureLogger.info('Request file field: ${request.files.first.field}');
    SecureLogger.info('Request filename: ${request.files.first.filename}');

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode >= 300) {
      SecureLogger.error(
        'Upload failed with field "$fileFieldName": ${response.body}',
      );
    }
    return response;
  }

  /// Pick and optimize images from camera or gallery
  static Future<List<File>> pickAndOptimizeImages({
    required ImagePicker picker,
    int maxImages = 5,
    ImageSource source = ImageSource.gallery,
  }) async {
    final List<File> selectedFiles = [];

    try {
      if (source == ImageSource.camera) {
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          imageQuality: 90,
          maxWidth: 1200,
          maxHeight: 1200,
        );

        if (pickedFile != null) {
          final optimizedFile = await optimizeImage(File(pickedFile.path));
          if (optimizedFile != null) {
            selectedFiles.add(optimizedFile);
          }
        }
      } else {
        // For gallery, allow multiple selection
        final List<XFile> pickedFiles = await picker.pickMultiImage(
          imageQuality: 90,
          limit: maxImages,
        );

        for (final pickedFile in pickedFiles) {
          final optimizedFile = await optimizeImage(File(pickedFile.path));
          if (optimizedFile != null) {
            selectedFiles.add(optimizedFile);
          }
        }
      }
    } catch (e) {
      SecureLogger.error('Failed to pick images', error: e);
    }

    return selectedFiles;
  }

  /// Decode JSON response safely
  static Map<String, dynamic> _decodeResponse(String responseBody) {
    try {
      if (responseBody.isEmpty) return {};
      return Map<String, dynamic>.from(jsonDecode(responseBody));
    } catch (e) {
      SecureLogger.error('Failed to decode response', error: e);
      return {'message': responseBody};
    }
  }

  /// Extract a URL from heterogeneous upload response shapes.
  static String? _extractImageUrl(Map<String, dynamic> responseData) {
    String? read(dynamic value) {
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      return null;
    }

    final data = responseData['data'];

    // Common direct keys
    final directCandidates = [
      responseData['secure_url'],
      responseData['imageUrl'],
      responseData['url'],
      data is Map<String, dynamic> ? data['secure_url'] : null,
      data is Map<String, dynamic> ? data['imageUrl'] : null,
      data is Map<String, dynamic> ? data['url'] : null,
    ];
    for (final candidate in directCandidates) {
      final url = read(candidate);
      if (url != null) return url;
    }

    // Nested image objects/lists
    final images = data is Map<String, dynamic> ? data['images'] : null;
    if (images is List && images.isNotEmpty) {
      final first = images.first;
      if (first is String) {
        final url = read(first);
        if (url != null) return url;
      } else if (first is Map) {
        final mapFirst = Map<String, dynamic>.from(first);
        final url =
            read(mapFirst['secure_url']) ??
            read(mapFirst['imageUrl']) ??
            read(mapFirst['url']);
        if (url != null) return url;
      }
    }

    final image = data is Map<String, dynamic> ? data['image'] : null;
    if (image is Map) {
      final imageMap = Map<String, dynamic>.from(image);
      return read(imageMap['secure_url']) ??
          read(imageMap['imageUrl']) ??
          read(imageMap['url']);
    }

    return null;
  }

  /// Validate image file
  static bool isValidImageFile(File file) {
    final extension = path.extension(file.path).toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    return validExtensions.contains(extension);
  }

  /// Get image file size in KB
  static Future<int> getImageSizeKB(File file) async {
    try {
      final bytes = await file.length();
      return (bytes / 1024).round();
    } catch (e) {
      return 0;
    }
  }
}
