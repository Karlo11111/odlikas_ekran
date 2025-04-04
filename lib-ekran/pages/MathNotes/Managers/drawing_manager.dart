import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/types.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/whiteboard_state.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/drawing_path.dart';

class DrawingManager {
  final WhiteboardState state;

  DrawingManager(this.state);

  void handleDrawingStart(ScaleStartDetails details) {
    if (state.currentTool != ToolMode.pen) return;

    final transformedPoint = state.transformPoint(details.focalPoint);
    state.currentCommands = [];
    state.currentPath = Path();
    state.currentPath!.moveTo(transformedPoint.dx, transformedPoint.dy);
    state.currentCommands!.add({
      'type': 'moveTo',
      'x': transformedPoint.dx,
      'y': transformedPoint.dy,
    });
  }

  void handleDrawingUpdate(ScaleUpdateDetails details) {
    if (state.currentTool != ToolMode.pen ||
        state.currentPath == null ||
        state.currentCommands == null) return;

    final transformedPoint = state.transformPoint(details.focalPoint);
    state.currentPath!.lineTo(transformedPoint.dx, transformedPoint.dy);
    state.currentCommands!.add({
      'type': 'lineTo',
      'x': transformedPoint.dx,
      'y': transformedPoint.dy,
    });

    // Trigger a redraw
    state.notifyListeners();
  }

  void handleDrawingEnd(ScaleEndDetails details) {
    if (state.currentTool != ToolMode.pen ||
        state.currentPath == null ||
        state.currentCommands == null) return;

    final path = DrawingPath(
      commands: state.currentCommands!,
      color: state.currentColor,
      strokeWidth: state.strokeWidth,
      drawingMode: state.drawingMode,
    );

    state.addPath(path);
    state.currentCommands = null;
    state.currentPath = null;
  }

  void setDrawingMode(DrawingMode mode) {
    state.drawingMode = mode;
    state.updateToolFromSettings();
  }

  void setColor(Color color) {
    state.setToolSettings(state.drawingMode, color: color);
    state.currentColor = color;
  }

  void setStrokeWidth(double width) {
    state.setToolSettings(state.drawingMode, strokeWidth: width);
    state.strokeWidth = width;
  }
}
