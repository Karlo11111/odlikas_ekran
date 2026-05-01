import 'package:flutter/material.dart';

class SessionCircles extends StatelessWidget {
  final int todaySessions;
  final Color color;

  const SessionCircles({
    super.key,
    required this.todaySessions,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: List.generate(8, (index) {
          final filled = index < todaySessions;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: SizedBox(
              width: 52,
              height: 52,
              child: CustomPaint(
                painter: _SessionCirclePainter(filled: filled),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SessionCirclePainter extends CustomPainter {
  final bool filled;

  const _SessionCirclePainter({required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;
    final paint = Paint()
      ..color = Colors.white
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_SessionCirclePainter old) => old.filled != filled;
}
