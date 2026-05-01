// lib/pages/MathNotes/saveWhiteboards/screenshot_manager.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

class ScreenshotManager {
  static Future<String?> saveScreenshot(
      String whiteboardId, Uint8List imageData) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/screenshot_$whiteboardId.png';

      // Use the most direct file writing approach
      final file = File(filePath);
      await file.writeAsBytes(imageData, flush: true);

      // Verify file exists and has content
      if (await file.exists() && await file.length() > 0) {
        debugPrint(
            'Screenshot saved to: $filePath (${await file.length()} bytes)');
        return filePath;
      } else {
        debugPrint('Failed to save screenshot or file is empty');
        return null;
      }
    } catch (e) {
      debugPrint('Screenshot save error: $e');
      return null;
    }
  }

  static Future<Uint8List?> loadScreenshot(String whiteboardId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/screenshot_$whiteboardId.png';
      final file = File(filePath);

      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        if (bytes.isNotEmpty) {
          debugPrint('Screenshot loaded: $filePath (${bytes.length} bytes)');
          return bytes;
        }
      }

      // Try the old path format as fallback (for backward compatibility)
      final oldFilePath = '${directory.path}/screenshots/$whiteboardId.png';
      final oldFile = File(oldFilePath);

      if (await oldFile.exists()) {
        final bytes = await oldFile.readAsBytes();
        if (bytes.isNotEmpty) {
          debugPrint(
              'Screenshot loaded from old path: $oldFilePath (${bytes.length} bytes)');
          return bytes;
        }
      }

      debugPrint('No screenshot found for whiteboard: $whiteboardId');
      return null;
    } catch (e) {
      debugPrint('Screenshot load error: $e');
      return null;
    }
  }

  static Future<bool> checkScreenCaptureCapability() async {
    // Create a simple widget to test capture
    final testKey = GlobalKey();
    final testWidget = RepaintBoundary(
      key: testKey,
      child: Container(
        width: 100,
        height: 100,
        color: Colors.red,
      ),
    );

    // Attach to the widget tree
    final testElement = testWidget.createElement();

    try {
      // Try to render it
      await Future.delayed(const Duration(milliseconds: 100));
      final boundary =
          testKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary != null) {
        final image = await boundary.toImage();
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        final result = byteData != null && byteData.lengthInBytes > 0;
        debugPrint(
            'Screenshot capability test result: $result (${byteData?.lengthInBytes ?? 0} bytes)');
        return result;
      }

      debugPrint('Screenshot capability test: boundary is null');
      return false;
    } catch (e) {
      debugPrint('Screenshot capability test error: $e');
      return false;
    } finally {
      // Clean up
      testElement.unmount();
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
