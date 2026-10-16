import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Hasil kompresi gambar yang mencakup file, bytes, dan perbandingan ukuran
class CompressedImageResult {
  final Uint8List bytes;
  final int originalSizeBytes;
  final int compressedSizeBytes;
  final String fileName;

  const CompressedImageResult({
    required this.bytes,
    required this.originalSizeBytes,
    required this.compressedSizeBytes,
    required this.fileName,
  });

  String get originalSizeFormatted => _formatBytes(originalSizeBytes);
  String get compressedSizeFormatted => _formatBytes(compressedSizeBytes);
  double get compressionRatioPercent =>
      ((originalSizeBytes - compressedSizeBytes) / originalSizeBytes) * 100;

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}

/// Utility kompresi gambar tanpa mengurangi kualitas visual (visually lossless)
class ImageCompressUtil {
  ImageCompressUtil._();

  /// Mengompresi file gambar dari galeri atau kamera:
  /// - Membatasi dimensi maksimum avatar ke 1024px (tetap sangat tajam pada layar Retina)
  /// - Menggunakan interpolasi cubic untuk kejernihan gambar maksimal
  /// - Mengompresi dengan kualitas optimal (default 85%) yang secara visual identik dengan aslinya
  ///   namun memangkas ukuran file hingga 80-90% (misal dari 5MB menjadi ~200KB).
  static Future<CompressedImageResult> compressImageFile(
    File file, {
    int maxDimension = 1024,
    int quality = 85,
  }) async {
    final rawBytes = await file.readAsBytes();
    return compressImageBytes(
      rawBytes,
      fileName: file.path.split('/').last,
      maxDimension: maxDimension,
      quality: quality,
    );
  }

  /// Kompresi dari raw bytes dalam background isolate (compute) agar UI tidak stutter
  static Future<CompressedImageResult> compressImageBytes(
    Uint8List rawBytes, {
    String fileName = 'avatar.jpg',
    int maxDimension = 1024,
    int quality = 85,
  }) async {
    final originalSize = rawBytes.lengthInBytes;

    // Jalankan decode, resize & encode di isolate agar thread UI tetap 60fps
    final compressedBytes = await compute(
      _runCompression,
      _CompressionParams(
        rawBytes: rawBytes,
        maxDimension: maxDimension,
        quality: quality,
      ),
    );

    return CompressedImageResult(
      bytes: compressedBytes,
      originalSizeBytes: originalSize,
      compressedSizeBytes: compressedBytes.lengthInBytes,
      fileName: fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')
          ? fileName
          : '$fileName.jpg',
    );
  }

  static Uint8List _runCompression(_CompressionParams params) {
    // 1. Decode gambar
    final original = img.decodeImage(params.rawBytes);
    if (original == null) {
      return params.rawBytes;
    }

    // Koreksi orientasi EXIF jika ada (dari kamera HP)
    final oriented = img.bakeOrientation(original);

    // 2. Resize jika dimensi melebihi batas maksimum
    img.Image processed = oriented;
    if (oriented.width > params.maxDimension || oriented.height > params.maxDimension) {
      if (oriented.width >= oriented.height) {
        processed = img.copyResize(
          oriented,
          width: params.maxDimension,
          interpolation: img.Interpolation.cubic,
        );
      } else {
        processed = img.copyResize(
          oriented,
          height: params.maxDimension,
          interpolation: img.Interpolation.cubic,
        );
      }
    }

    // 3. Encode ke format JPEG dengan kualitas tinggi tanpa artefak visual
    final encodedJpg = img.encodeJpg(processed, quality: params.quality);
    return Uint8List.fromList(encodedJpg);
  }
}

class _CompressionParams {
  final Uint8List rawBytes;
  final int maxDimension;
  final int quality;

  const _CompressionParams({
    required this.rawBytes,
    required this.maxDimension,
    required this.quality,
  });
}
