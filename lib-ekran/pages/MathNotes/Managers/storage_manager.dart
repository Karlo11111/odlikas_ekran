import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/whiteboard_state.dart';
import 'package:odlikas_ekran/pages/MathNotes/ImagesAdding/image_element.dart';
import 'package:odlikas_ekran/pages/MathNotes/Shapes/shape_shape.dart';
import 'package:odlikas_ekran/pages/MathNotes/TextAdding/text_model.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/debouncer.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/screenshot_manager.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/whiteboard_data.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/drawing_path.dart';

class StorageManager {
  final WhiteboardState state;
  final WhiteboardData whiteboardData;
  final Debouncer _saveDebounce = Debouncer(delay: const Duration(seconds: 1));
  final GlobalKey? whiteboardKey;

  StorageManager(this.state, this.whiteboardData, {this.whiteboardKey});

  void loadSavedState() {
    // Load paths
    state.paths = whiteboardData.paths
        .map((path) => DrawingPath.fromMap(_convertMap(path)))
        .toList();

    // Load transformation matrix
    state.transformationMatrix =
        Matrix4.fromList(whiteboardData.transformationMatrix);
    state.currentScale = whiteboardData.currentScale;

    // Load text elements
    state.textElements = whiteboardData.textElements
        .map((te) => TextElement.fromMap(_convertMap(te)))
        .toList();

    // Load shapes
    state.shapes = whiteboardData.shapes
        .map((shape) => ShapeShape.fromMap(_convertMap(shape)))
        .toList();

    // Load image elements
    state.imageElements = whiteboardData.imageElements
        .map((img) => ImageElement.fromMap(_convertMap(img)))
        .toList();
  }

  Future<void> autoSave({bool force = false}) async {
    if (force) {
      await _saveNow(); // Save immediately
    } else {
      _saveDebounce.run(() => _saveNow());
    }
  }

  Future<void> _saveNow() async {
    try {
      // Prepare data for saving
      whiteboardData.lastModified = DateTime.now();
      whiteboardData.paths =
          List<Map<String, dynamic>>.from(state.paths.map((p) => p.toMap()));
      whiteboardData.transformationMatrix =
          List<double>.from(state.transformationMatrix.storage);
      whiteboardData.currentScale = state.currentScale;
      whiteboardData.textElements = List<Map<String, dynamic>>.from(
          state.textElements.map((te) => te.toMap()));
      whiteboardData.shapes =
          List<Map<String, dynamic>>.from(state.shapes.map((s) => s.toMap()));
      whiteboardData.imageElements = List<Map<String, dynamic>>.from(
          state.imageElements.map((img) => img.toMap()));

      // Generate screenshot if the whiteboard key is provided
      if (whiteboardKey != null) {
        await _generateScreenshot();
      }

      // Save whiteboard data to Hive
      await whiteboardData.save();
      debugPrint('Whiteboard saved successfully with ID: ${whiteboardData.id}');
    } catch (saveError) {
      debugPrint('Error saving to Hive: $saveError');

      // Fallback to direct put
      try {
        final box = Hive.box<WhiteboardData>('whiteboards');
        if (whiteboardData.isInBox) {
          await box.put(whiteboardData.key, whiteboardData);
        }
      } catch (e) {
        debugPrint('All save attempts failed: $e');
      }
    }
  }

  Future<void> _generateScreenshot() async {
    try {
      final renderObject = whiteboardKey?.currentContext?.findRenderObject();
      if (renderObject == null) {
        debugPrint('No render object found for screenshot');
        return;
      }

      final Size canvasSize = renderObject.paintBounds.size;

      // Create a recorder and canvas
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Fill background with white
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
        Paint()..color = Colors.white,
      );

      // Apply transformations
      canvas.save();
      canvas.transform(state.transformationMatrix.storage);

      // Draw all shapes
      for (final shape in state.shapes) {
        shape.draw(canvas);
      }

      // Draw all paths
      for (final drawingPath in state.paths) {
        final path = drawingPath.toPath();
        final paint = Paint()
          ..color = drawingPath.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = drawingPath.strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawPath(path, paint);
      }

      // Draw text elements
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      for (final element in state.textElements) {
        textPainter.text = TextSpan(
          text: element.text,
          style: TextStyle(
            fontSize: element.fontSize,
            color: Colors.black,
          ),
        );

        textPainter.layout();
        textPainter.paint(canvas, element.position);
      }

      // Draw images
      // Handling images in screenshot is complex and would require loading each image
      // For this example, we'll skip image rendering in the screenshot

      // Restore canvas and create the image
      canvas.restore();
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(
        canvasSize.width.toInt(),
        canvasSize.height.toInt(),
      );

      // Convert to PNG bytes
      // Convert to PNG bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        await ScreenshotManager.saveScreenshot(whiteboardData.id, bytes);
        whiteboardData.screenshot = null; // Don't store in Hive to save space
        debugPrint('Screenshot captured and saved: ${bytes.length} bytes');
      }
    } catch (e, stack) {
      debugPrint('Screenshot error: $e\n$stack');

      // Create a fallback thumbnail
      _createFallbackThumbnail();
    }
  }

  Future<void> _createFallbackThumbnail() async {
    try {
      // Create a simple rectangular thumbnail with gradient
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Create a gradient background with the whiteboard's name
      final Rect rect = Rect.fromLTWH(0, 0, 400, 300);

      // Use a gradient that visually indicates this is a whiteboard
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blue.shade50, Colors.blue.shade100],
      );

      canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

      // Add a text label
      final textPainter = TextPainter(
        text: TextSpan(
          text: whiteboardData.name,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 24,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout(maxWidth: 350);
      textPainter.paint(
        canvas,
        Offset(
          (400 - textPainter.width) / 2,
          (300 - textPainter.height) / 2,
        ),
      );

      // Convert to image
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(400, 300);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        await ScreenshotManager.saveScreenshot(whiteboardData.id, bytes);
        whiteboardData.screenshot = null;
        debugPrint('Fallback thumbnail saved: ${bytes.length} bytes');
      }
    } catch (fallbackError) {
      debugPrint('Fallback thumbnail also failed: $fallbackError');
    }
  }

  // Helper method to convert dynamic maps to string maps
  Map<String, dynamic> _convertMap(Map<dynamic, dynamic> originalMap) {
    return Map<String, dynamic>.fromIterable(
      originalMap.entries,
      key: (entry) => entry.key.toString(),
      value: (entry) {
        if (entry.value is Map<dynamic, dynamic>) {
          return _convertMap(entry.value);
        } else if (entry.value is List) {
          return _convertList(entry.value);
        }
        return entry.value;
      },
    );
  }

  // Helper method to convert dynamic lists to typed lists
  List<dynamic> _convertList(List<dynamic> originalList) {
    return originalList.map((item) {
      if (item is Map<dynamic, dynamic>) {
        return _convertMap(item);
      } else if (item is List) {
        return _convertList(item);
      }
      return item;
    }).toList();
  }

  void cancelPendingSaves() {
    _saveDebounce.cancel();
  }

  Future<void> saveImmediately() async {
    await _saveNow();
  }
}
