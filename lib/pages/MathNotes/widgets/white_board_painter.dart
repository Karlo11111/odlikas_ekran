import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/MathNotes/Shapes/shape_shape.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/drawing_path.dart';

class WhiteboardPainter extends CustomPainter {
  final List<DrawingPath> paths;
  final Matrix4 transformationMatrix;
  final Path? currentPath;
  final Color currentColor;
  final double strokeWidth;
  final List<ShapeShape> shapes;
  final ShapeShape? currentShape;

  const WhiteboardPainter({
    required this.paths,
    required this.transformationMatrix,
    this.currentPath,
    required this.currentColor,
    required this.strokeWidth,
    required this.shapes,
    required this.currentShape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.transform(transformationMatrix.storage);

    // Draw stored shapes
    for (final shape in shapes) {
      shape.draw(canvas);
    }

    // Draw current in-progress shape
    if (currentShape != null) {
      currentShape!.draw(canvas);
    }

    // crtaj trenutne putanje
    for (final drawingPath in paths) {
      final path = drawingPath.toPath();
      final paint = Paint()
        ..color = drawingPath.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = drawingPath.strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, paint);
    }

    // crtaj trenutne temporary putanje
    if (currentPath != null) {
      final paint = Paint()
        ..color = currentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(currentPath!, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(WhiteboardPainter oldDelegate) => true;
}
