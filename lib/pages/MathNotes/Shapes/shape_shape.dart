import 'dart:math';

import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/MathNotes/math_notes.dart';

class ShapeShape {
  final ShapeType type;
  final Offset startPoint;
  Offset endPoint;
  final Color color;
  final double strokeWidth;

  ShapeShape({
    required this.type,
    required this.startPoint,
    required this.endPoint,
    required this.color,
    required this.strokeWidth,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.index,
      'startPointX': startPoint.dx,
      'startPointY': startPoint.dy,
      'endPointX': endPoint.dx,
      'endPointY': endPoint.dy,
      'color': color.value,
      'strokeWidth': strokeWidth,
    };
  }

  factory ShapeShape.fromMap(Map<String, dynamic> map) {
    return ShapeShape(
      type: ShapeType.values[map['type'] as int],
      startPoint: Offset(
        (map['startPointX'] as num).toDouble(),
        (map['startPointY'] as num).toDouble(),
      ),
      endPoint: Offset(
        (map['endPointX'] as num).toDouble(),
        (map['endPointY'] as num).toDouble(),
      ),
      color: Color(map['color'] as int),
      strokeWidth: (map['strokeWidth'] as num).toDouble(),
    );
  }

  // Method to draw the shape
  // In your ShapeShape class, modify the draw method:
  void draw(Canvas canvas) {
    final fillOpacity = (strokeWidth - 1) / 29; // Convert 1-30 range to 0.0-1.0
    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2; // Fixed outline thickness

    final fillPaint = Paint()
      ..color = color.withOpacity(fillOpacity)
      ..style = PaintingStyle.fill;

    // Calculate dimensions
    final width = (endPoint.dx - startPoint.dx).abs();
    final height = (endPoint.dy - startPoint.dy).abs();
    final topLeft = Offset(
      min(startPoint.dx, endPoint.dx),
      min(startPoint.dy, endPoint.dy),
    );
    final center = Offset(
      (startPoint.dx + endPoint.dx) / 2,
      (startPoint.dy + endPoint.dy) / 2,
    );

    switch (type) {
      case ShapeType.circle:
        final radius = max(width, height) / 2;
        canvas.drawCircle(center, radius, fillPaint);
        canvas.drawCircle(center, radius, outlinePaint);
        break;

      case ShapeType.square:
        final size = max(width, height);
        final rect = Rect.fromCenter(center: center, width: size, height: size);
        canvas.drawRect(rect, fillPaint);
        canvas.drawRect(rect, outlinePaint);
        break;

      case ShapeType.triangle:
        final path = Path();
        path.moveTo(center.dx, topLeft.dy);
        path.lineTo(topLeft.dx + width, topLeft.dy + height);
        path.lineTo(topLeft.dx, topLeft.dy + height);
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, outlinePaint);
        break;

      case ShapeType.hexagon:
        final path = Path();
        final radius = max(width, height) / 2;
        for (int i = 0; i < 6; i++) {
          final angle = (i * 60) * pi / 180;
          final x = center.dx + radius * cos(angle);
          final y = center.dy + radius * sin(angle);
          if (i == 0)
            path.moveTo(x, y);
          else
            path.lineTo(x, y);
        }
        path.close();
        canvas.drawPath(path, fillPaint);
        canvas.drawPath(path, outlinePaint);
        break;
    }
  }
}
