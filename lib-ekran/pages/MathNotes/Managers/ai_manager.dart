import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/whiteboard_state.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/types.dart';
import 'package:odlikas_ekran/database/api/deepseek_service.dart';
import 'package:odlikas_ekran/database/api/matpix_ai_solving.dart';
import 'package:image/image.dart' as imglib;
import 'package:odlikas_ekran/pages/MathNotes/widgets/select_rectangle_mathpix.dart';

class AiManager {
  final WhiteboardState state;
  final GlobalKey whiteboardKey;
  final MathpixAiSolving _mathpixAiSolving = MathpixAiSolving();
  final DeepseekService _deepseekService = DeepseekService();

  AiManager(this.state, this.whiteboardKey);

  void enterAiSelectionMode() {
    state.isSelectingArea = true;
    state.currentTool = ToolMode.ai;
    state.showPenOptions = false;
    state.showShapeOptions = false;
    state.showColorOptions = false;
  }

  void handleSelectionStart(Offset position) {
    state.selectionStart = position;
    state.selectionEnd = position;
  }

  void handleSelectionUpdate(Offset position) {
    state.selectionEnd = position;
  }

  Future<void> handleSelectionEnd() async {
    if (state.selectionStart != null && state.selectionEnd != null) {
      try {
        final image = await _captureSelectedArea();
        if (image != null) {
          state.capturedImage = image;

          // Send image to mathpix
          final result = await _mathpixAiSolving.sendImageToMathpix(image);
          if (result != null) {
            // Process result for display
            String sanitized =
                result.replaceAll(r"\(", r"$$").replaceAll(r"\)", r"$$");

            state.latexResult = sanitized;

            // Start loading the AI solution
            state.isOpenAiLoading = true;
            state.openAiAnswer = null;

            try {
              final openAiResult =
                  await _deepseekService.solveMathExpression(sanitized);
              state.openAiAnswer = openAiResult;
            } finally {
              state.isOpenAiLoading = false;
            }
          }
        }
      } finally {
        // Reset selection state
        state.isSelectingArea = false;
        state.selectionStart = null;
        state.selectionEnd = null;
      }
    }
  }

  Future<Uint8List?> _captureSelectedArea() async {
    final renderObject = whiteboardKey.currentContext?.findRenderObject();
    if (renderObject == null ||
        state.selectionStart == null ||
        state.selectionEnd == null) {
      return null;
    }

    try {
      final whiteboardSize = renderObject.paintBounds.size;

      // Validate coordinates
      final start = Offset(
        state.selectionStart!.dx.clamp(0, whiteboardSize.width),
        state.selectionStart!.dy.clamp(0, whiteboardSize.height),
      );
      final end = Offset(
        state.selectionEnd!.dx.clamp(0, whiteboardSize.width),
        state.selectionEnd!.dy.clamp(0, whiteboardSize.height),
      );

      // Ensure selection isn't too small
      if ((end.dx - start.dx).abs() < 5 || (end.dy - start.dy).abs() < 5) {
        print(
            'Selection too small: ${(end.dx - start.dx).abs()}x${(end.dy - start.dy).abs()}');
        return null;
      }

      // Capture image
      final image = await (renderObject as RenderRepaintBoundary)
          .toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      // Validate byte data
      if (byteData == null || byteData.lengthInBytes < 100) {
        print('Invalid image data: ${byteData?.lengthInBytes ?? "null"} bytes');
        return null;
      }

      // Save raw image for debugging
      final rawImage = byteData.buffer.asUint8List();
      print('Raw image header: ${rawImage.sublist(0, 8)}');

      // Decode and process image
      final img = imglib.decodeImage(rawImage);
      if (img == null) {
        print('Failed to decode RAW image');
        return null;
      }

      final scaledRect = Rect.fromLTRB(
        (start.dx * 2).clamp(0, img.width.toDouble()).toDouble(),
        (start.dy * 2).clamp(0, img.height.toDouble()).toDouble(),
        (end.dx * 2).clamp(0, img.width.toDouble()).toDouble(),
        (end.dy * 2).clamp(0, img.height.toDouble()).toDouble(),
      );

      // Ensure rectangle coordinates are properly ordered
      final clampedRect = Rect.fromLTRB(
        scaledRect.left < scaledRect.right ? scaledRect.left : scaledRect.right,
        scaledRect.top < scaledRect.bottom ? scaledRect.top : scaledRect.bottom,
        scaledRect.left < scaledRect.right ? scaledRect.right : scaledRect.left,
        scaledRect.top < scaledRect.bottom ? scaledRect.bottom : scaledRect.top,
      );

      // Validate dimensions
      if (clampedRect.width < 1 || clampedRect.height < 1) {
        print(
            'Invalid crop dimensions: ${clampedRect.width}x${clampedRect.height}');
        return null;
      }

      final cropped = imglib.copyCrop(
        img,
        x: clampedRect.left.toInt(),
        y: clampedRect.top.toInt(),
        width: clampedRect.width.toInt(),
        height: clampedRect.height.toInt(),
      );

      return Uint8List.fromList(imglib.encodePng(cropped));
    } catch (e) {
      print('Capture error: $e');
      return null;
    }
  }

  Widget buildSelectionOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          handleSelectionStart(details.localPosition);
        },
        onPanUpdate: (details) {
          handleSelectionUpdate(details.localPosition);
        },
        onPanEnd: (_) async {
          await handleSelectionEnd();
        },
        child: CustomPaint(
          painter: SelectionRectanglePainter(
            start: state.selectionStart,
            end: state.selectionEnd,
          ),
        ),
      ),
    );
  }
}
