import 'dart:io';
import 'dart:typed_data';

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
      // On Android, use the external files directory so it's visible in File Manager
      base = await getExternalStorageDirectory();
    }
    base ??= await getApplicationDocumentsDirectory();
    
    final dir = Directory('${base.path}/SafeText_Vault');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

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
