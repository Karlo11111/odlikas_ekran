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

    if (details.pointerCount > 1) {
      // Pinch-to-zoom with simultaneous pan support
      final newScale = state.lastScale * details.scale;
      final clampedScale = newScale.clamp(MIN_SCALE, MAX_SCALE);

      final inverseInitialMatrix =
          Matrix4.inverted(state.initialTransformationMatrix);
      final transformedFocal = MatrixUtils.transformPoint(
        inverseInitialMatrix,
        state.initialGestureFocalPoint,
      );

      final scaleDelta = clampedScale / state.lastScale;

      final newMatrix = Matrix4.copy(state.initialTransformationMatrix)
        ..translate(transformedFocal.dx, transformedFocal.dy)
        ..scale(scaleDelta)
        ..translate(-transformedFocal.dx, -transformedFocal.dy);

      // Account for focal point movement (panning while pinching)
      final focalDelta =
          details.localFocalPoint - state.initialGestureFocalPoint;
      newMatrix.translate(
          focalDelta.dx / clampedScale, focalDelta.dy / clampedScale);

      state.transformationMatrix = newMatrix;
      state.currentScale = clampedScale;
    } else {
      // Single-finger pan — mutate then reassign through setter to trigger notifyListeners
      final delta = details.focalPointDelta;
      final m = state.transformationMatrix;
      m.translate(delta.dx / state.currentScale, delta.dy / state.currentScale);
      state.transformationMatrix = m;
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
      final newMatrix = Matrix4.copy(state.transformationMatrix)
        ..translate(focalPoint.dx, focalPoint.dy)
        ..scale(deltaScale)
        ..translate(-focalPoint.dx, -focalPoint.dy);
      state.transformationMatrix = newMatrix;
    } else {
      // Center zoom — preserve translation proportionally
      final ratio = clampedScale / state.currentScale;
      final translation =
          Matrix4.copy(state.transformationMatrix).getTranslation();
      final newMatrix = Matrix4.identity()..scale(clampedScale);
      newMatrix.setTranslation(translation.scaled(ratio));
      state.transformationMatrix = newMatrix;
    }

    state.currentScale = clampedScale;
  }
}
