import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/whiteboard_state.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/types.dart';

class TransformationManager {
  final WhiteboardState state;

  TransformationManager(this.state);

  void handleScaleStart(ScaleStartDetails details) {
    if (state.currentTool != ToolMode.hand) return;

    state.lastScale = state.currentScale;
    state.initialTransformationMatrix =
        Matrix4.copy(state.transformationMatrix);
    state.initialGestureFocalPoint = details.localFocalPoint;
    state.lastPanOffset = details.focalPoint;
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    if (state.currentTool != ToolMode.hand) return;

    if (details.scale != 1.0) {
      // Zoom scaling
      final newScale = state.lastScale * details.scale;
      final clampedScale = newScale.clamp(MIN_SCALE, MAX_SCALE);

      final inverseInitialMatrix =
          Matrix4.inverted(state.initialTransformationMatrix);
      final transformedFocal = MatrixUtils.transformPoint(
        inverseInitialMatrix,
        state.initialGestureFocalPoint,
      );

      final scaleDelta = clampedScale / state.lastScale;

      state.transformationMatrix =
          Matrix4.copy(state.initialTransformationMatrix)
            ..translate(transformedFocal.dx, transformedFocal.dy)
            ..scale(scaleDelta)
            ..translate(-transformedFocal.dx, -transformedFocal.dy);

      state.currentScale = clampedScale;
    } else {
      // Panning
      final delta = details.focalPointDelta;
      state.transformationMatrix.translate(
        delta.dx / state.currentScale,
        delta.dy / state.currentScale,
      );
    }
  }

  void handleScaleEnd(ScaleEndDetails details) {
    state.lastPanOffset = null;
  }

  void zoomIn(Offset? focalPoint) {
    final newScale = state.currentScale * 1.1;
    _updateScale(newScale, focalPoint: focalPoint);
  }

  void zoomOut(Offset? focalPoint) {
    final newScale = state.currentScale * 0.9;
    _updateScale(newScale, focalPoint: focalPoint);
  }

  void resetZoom() {
    _updateScale(DEFAULT_SCALE);
  }

  void _updateScale(double newScale, {Offset? focalPoint}) {
    final clampedScale = newScale.clamp(MIN_SCALE, MAX_SCALE);

    if (focalPoint != null) {
      final deltaScale = clampedScale / state.currentScale;

      state.transformationMatrix
        ..translate(focalPoint.dx, focalPoint.dy)
        ..scale(deltaScale)
        ..translate(-focalPoint.dx, -focalPoint.dy);
    } else {
      // Center zoom
      final oldMatrix = Matrix4.copy(state.transformationMatrix);
      final translation = oldMatrix.getTranslation();

      state.transformationMatrix = Matrix4.identity();
      state.transformationMatrix.scale(clampedScale);

      // Keep the center point invariant
      final ratio = clampedScale / state.currentScale;
      final adjustedTranslation = translation.scaled(ratio);
      state.transformationMatrix.setTranslation(adjustedTranslation);
    }

    state.currentScale = clampedScale;
  }
}
