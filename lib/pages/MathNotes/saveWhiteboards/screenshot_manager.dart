// lib/pages/MathNotes/saveWhiteboards/screenshot_manager.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ScreenshotManager {
  static Future<String?> saveScreenshot(
      String whiteboardId, Uint8List imageData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final screenshotsDir = Directory('${directory.path}/screenshots');

      // Create directory if it doesn't exist
      if (!await screenshotsDir.exists()) {
        await screenshotsDir.create(recursive: true);
      }

      final file = File('${screenshotsDir.path}/$whiteboardId.png');
      await file.writeAsBytes(imageData);

      debugPrint('Screenshot saved to file: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Error saving screenshot to file: $e');
      return null;
    }
  }

  static Future<Uint8List?> loadScreenshot(String whiteboardId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/screenshots/$whiteboardId.png');

      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        debugPrint(
            'Screenshot loaded from file: ${file.path} (${bytes.length} bytes)');
        return bytes;
      }
      debugPrint('Screenshot file not found for whiteboard: $whiteboardId');
      return null;
    } catch (e) {
      debugPrint('Error loading screenshot from file: $e');
      return null;
    }
  }

  static Future<void> deleteScreenshot(String whiteboardId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/screenshots/$whiteboardId.png');

      if (await file.exists()) {
        await file.delete();
        debugPrint('Screenshot deleted: $whiteboardId');
      }
    } catch (e) {
      debugPrint('Error deleting screenshot: $e');
    }
  }
}
