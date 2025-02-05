import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class SelectionRectanglePainter extends CustomPainter {
  final Offset? start;
  final Offset? end;

  SelectionRectanglePainter({this.start, this.end});

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || end == null) return;

    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final rect = Rect.fromPoints(start!, end!);

    // iscrtaj pravokutnik za selectanje
    canvas.drawRect(rect, paint);

    // dashed border
    final path = Path()
      ..moveTo(rect.left, rect.top)
      ..lineTo(rect.right, rect.top)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..close();

    canvas.drawPath(
      dashPath(
        path,
        dashArray: CircularIntervalList<double>(<double>[5, 5]),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Path dashPath(Path path, {required CircularIntervalList<double> dashArray}) {
  final dashPath = Path();
  for (final metric in path.computeMetrics()) {
    var distance = 0.0;
    while (distance < metric.length) {
      final length = dashArray.next;
      dashPath.addPath(
        metric.extractPath(distance, distance + length),
        Offset.zero,
      );
      distance += length;
      if (distance < metric.length) distance += dashArray.next;
    }
  }
  return dashPath;
}
