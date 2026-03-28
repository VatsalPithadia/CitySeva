import 'dart:io';
import 'dart:math';

/// Image Verification Service
/// Checks if uploaded complaint images are real photos (not AI-generated)
/// Uses heuristic analysis for hackathon purposes
/// Can be upgraded to a real AI detection API in production
class ImageVerificationService {

  /// Verify a list of images
  /// Returns a list of results for each image
  static Future<List<ImageVerificationResult>> verifyImages(List<File> images) async {
    final results = <ImageVerificationResult>[];
    for (final image in images) {
      final result = await _analyzeImage(image);
      results.add(result);
    }
    return results;
  }

  /// Analyze a single image for authenticity
  static Future<ImageVerificationResult> _analyzeImage(File image) async {
    try {
      final bytes = await image.readAsBytes();
      final fileSize = bytes.length;
      final path = image.path.toLowerCase();

      // --- Heuristic checks ---

      // 1. File size check — AI images tend to be very uniform in size
      // Real photos from cameras are usually > 100KB
      if (fileSize < 10000) {
        return ImageVerificationResult(
          isReal: false,
          confidence: 15,
          reason: 'Image file size is too small. Please upload a real photo.',
          warning: true,
        );
      }

      // 2. File extension check
      final validExtensions = ['.jpg', '.jpeg', '.png', '.heic', '.heif', '.webp'];
      final hasValidExt = validExtensions.any((ext) => path.endsWith(ext));
      if (!hasValidExt) {
        return ImageVerificationResult(
          isReal: false,
          confidence: 10,
          reason: 'Invalid image format. Please upload JPG, PNG or HEIC.',
          warning: true,
        );
      }

      // 3. Check if image came from camera (path contains dcim or camera)
      final isCameraPhoto = path.contains('dcim') ||
          path.contains('camera') ||
          path.contains('img_') ||
          path.contains('dsc') ||
          path.contains('photo');

      // 4. Analyze byte entropy — AI images often have different entropy patterns
      final entropy = _calculateEntropy(bytes.take(5000).toList());

      // 5. Check JPEG header for camera metadata indicators
      bool hasExifData = false;
      if (bytes.length > 4) {
        // JPEG files start with FFD8FF
        hasExifData = bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF;
      }

      // --- Scoring ---
      int score = 50; // Base score

      if (fileSize > 500000) score += 20; // Large file = likely real photo
      if (fileSize > 1000000) score += 10; // Very large = almost certainly real
      if (isCameraPhoto) score += 20; // Camera path = real photo
      if (hasExifData) score += 15; // Has JPEG header = real camera photo
      if (entropy > 7.0) score += 10; // High entropy = complex real image
      if (entropy < 5.0) score -= 20; // Low entropy = possibly AI/generated

      score = score.clamp(0, 100);

      if (score >= 60) {
        return ImageVerificationResult(
          isReal: true,
          confidence: score,
          reason: 'Image appears to be a real photo.',
          warning: false,
        );
      } else if (score >= 35) {
        return ImageVerificationResult(
          isReal: true,
          confidence: score,
          reason: 'Image could not be fully verified. Proceeding with caution.',
          warning: true,
        );
      } else {
        return ImageVerificationResult(
          isReal: false,
          confidence: score,
          reason: 'Image may be AI-generated or not a real photo. Please use your camera.',
          warning: true,
        );
      }
    } catch (_) {
      // If analysis fails, allow with warning
      return ImageVerificationResult(
        isReal: true,
        confidence: 50,
        reason: 'Could not verify image. Proceeding.',
        warning: true,
      );
    }
  }

  /// Calculate Shannon entropy of byte data
  /// Real photos have higher entropy due to complex pixel data
  static double _calculateEntropy(List<int> bytes) {
    if (bytes.isEmpty) return 0;
    final freq = <int, int>{};
    for (final b in bytes) {
      freq[b] = (freq[b] ?? 0) + 1;
    }
    double entropy = 0;
    for (final count in freq.values) {
      final p = count / bytes.length;
      entropy -= p * (log(p) / log(2));
    }
    return entropy;
  }

  /// Check if all images passed verification
  static bool allImagesVerified(List<ImageVerificationResult> results) {
    return results.every((r) => r.isReal);
  }

  /// Get overall verification summary
  static String getSummary(List<ImageVerificationResult> results) {
    final failed = results.where((r) => !r.isReal).length;
    final warned = results.where((r) => r.warning && r.isReal).length;
    if (failed > 0) return '$failed image(s) failed verification';
    if (warned > 0) return '$warned image(s) could not be fully verified';
    return 'All images verified as real photos';
  }
}

class ImageVerificationResult {
  final bool isReal;
  final int confidence; // 0-100
  final String reason;
  final bool warning;

  ImageVerificationResult({
    required this.isReal,
    required this.confidence,
    required this.reason,
    required this.warning,
  });
}
