import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/whiteboard_state.dart';

import 'package:odlikas_ekran/pages/MathNotes/Shapes/shape_shape.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/types.dart';

class ShapeManager {
  final WhiteboardState state;

  ShapeManager(this.state);

  void handleShapeStart(ScaleStartDetails details) {
    if (state.currentTool != ToolMode.shape) return;

    final transformedPoint = state.transformPoint(details.focalPoint);
    state.currentShape = ShapeShape(
      type: state.currentShapeType,
      startPoint: transformedPoint,
      endPoint: transformedPoint, // Initially same point
      color: state.currentColor,
      strokeWidth: state.strokeWidth,
    );
  }

  void handleShapeUpdate(ScaleUpdateDetails details) {
    if (state.currentTool != ToolMode.shape || state.currentShape == null)
      return;

    final transformedPoint = state.transformPoint(details.focalPoint);
    state.currentShape!.endPoint = transformedPoint;

    // Trigger a redraw
    state.notifyListeners();
  }

  void handleShapeEnd(ScaleEndDetails details) {
    if (state.currentTool != ToolMode.shape || state.currentShape == null)
      return;

    state.addShape(state.currentShape!);
    state.currentShape = null;
  }

  void setShapeType(ShapeType type) {
    state.currentShapeType = type;
  }

  void setShapeColor(Color color) {
    state.currentColor = color;
  }

  void setShapeFill(double fillLevel) {
    // The strokeWidth is used to calculate fill opacity in the draw method
    state.strokeWidth = fillLevel;
  }
}
