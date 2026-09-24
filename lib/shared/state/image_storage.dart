import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies a picked photo into the app's own storage, so it survives even if
/// the original is moved or deleted, and returns the saved path.
///
/// Photos live in a covers folder inside the app's private application
/// support directory, never anywhere shared or synced.
class ImageStorage {
  ImageStorage._();

  static final ImagePicker _picker = ImagePicker();

  /// Opens the system photo picker and saves the chosen image on this
  /// device. Returns null if the reader cancels or picking fails.
  static Future<String?> pickAndSave({required String prefix}) async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (picked == null) return null;
      return _saveCopy(picked, prefix: prefix);
    } catch (error) {
      debugPrint('ImageStorage: could not pick an image ($error)');
      return null;
    }
  }

  static Future<String> _saveCopy(
    XFile file, {
    required String prefix,
  }) async {
    final directory = await getApplicationSupportDirectory();
    final coversDir = Directory(p.join(directory.path, 'covers'));
    if (!await coversDir.exists()) {
      await coversDir.create(recursive: true);
    }
    final extension = p.extension(file.path).isEmpty
        ? '.jpg'
        : p.extension(file.path);
    final name =
        '$prefix-${DateTime.now().microsecondsSinceEpoch}$extension';
    final destination = p.join(coversDir.path, name);
    await File(file.path).copy(destination);
    return destination;
  }

  /// Deletes a saved photo, if it exists. Safe to call with an old path that
  /// is about to be replaced.
  static Future<void> deleteIfExists(String? path) async {
    if (path == null) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (error) {
      debugPrint('ImageStorage: could not delete a photo ($error)');
    }
  }
}
