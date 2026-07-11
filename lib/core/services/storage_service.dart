import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

import '../exceptions/app_exceptions.dart';

/// Handles writing generated (encoded) images and reading/clearing local
/// app storage. All output stays on-device under the app's own sandboxed
/// directories — nothing is ever uploaded anywhere.
class StorageService {
  const StorageService();

  Future<Directory> _outputDir() async {
    Directory? base;
    if (Platform.isAndroid) {
      // Use the application documents directory for private storage
      base = await getApplicationDocumentsDirectory();
    } else {
      base = await getApplicationDocumentsDirectory();
    }
    
    final dir = Directory('${base.path}/SafeText_Vault');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Saves the image to the app's private storage.
  /// This is used for temporary storage and history.
  Future<File> saveEncodedImage(Uint8List bytes, {String? fileName}) async {
    try {
      final dir = await _outputDir();
      final name = fileName ?? 'safetext_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${dir.path}/$name');
      return await file.writeAsBytes(bytes, flush: true);
    } catch (_) {
      throw const StorageException('Unable to save the encoded image.');
    }
  }

  /// Saves the image to the device's public Gallery.
  Future<void> saveToGallery(Uint8List bytes, {String? fileName}) async {
    try {
      // For Gal, we need to write to a temp file first
      final tempDir = await getTemporaryDirectory();
      final name = fileName ?? 'safetext_${DateTime.now().millisecondsSinceEpoch}.png';
      final tempFile = File('${tempDir.path}/$name');
      await tempFile.writeAsBytes(bytes);

      // Save to Gallery
      await Gal.putImage(tempFile.path, album: 'SafeText');
      
      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      throw StorageException('Failed to save image to gallery: $e');
    }
  }

  /// Opens the device's gallery app.
  Future<void> openGallery() async {
    try {
      await Gal.open();
    } catch (_) {
      // Silently fail if gallery cannot be opened
    }
  }

  Future<int> cacheSizeBytes() async {
    try {
      final dir = await _outputDir();
      if (!await dir.exists()) return 0;
      int total = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) total += await entity.length();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  Future<void> clearGeneratedImages() async {
    try {
      final dir = await _outputDir();
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      throw const StorageException('Unable to clear generated images.');
    }
  }

  Future<void> clearCache() async {
    try {
      final cacheDir = await getTemporaryDirectory();
      if (await cacheDir.exists()) {
        await for (final entity in cacheDir.list()) {
          try {
            await entity.delete(recursive: true);
          } catch (_) {
            // Best-effort; skip files in use.
          }
        }
      }
    } catch (_) {
      throw const StorageException('Unable to clear cache.');
    }
  }
}
