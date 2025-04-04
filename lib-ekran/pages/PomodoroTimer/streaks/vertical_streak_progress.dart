import 'package:flutter/material.dart';
import 'dart:math';

import 'package:google_fonts/google_fonts.dart';

// krugovi za steak u pomodoro timeru
class VerticalProgressCircles extends StatelessWidget {
  final int daysLearning;
  final int hoursLearning;
  final int streakCount;
  final Color color;
  final VoidCallback? onTap;

  const VerticalProgressCircles({
    super.key,
    required this.daysLearning,
    required this.hoursLearning,
    required this.streakCount,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (daysLearning == 0 || hoursLearning == 0) return const SizedBox.shrink();

    final double sessionsPerDay = (hoursLearning * 60) / 30;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.all(Radius.circular(16)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(daysLearning, (index) {
            final double start = index * sessionsPerDay;
            final double end = (index + 1) * sessionsPerDay;
            double fill = 0.0;

            if (streakCount >= end) {
              fill = 1.0;
            } else if (streakCount > start) {
              fill = (streakCount - start) / sessionsPerDay;
              fill = fill.clamp(0.0, 1.0);
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                width: 60,
                height: 60,
                child: CustomPaint(
                  painter: CircleProgressPainter(
                    progress: fill,
                    backgroundColor: Colors.white,
                    fillColor: Colors.white,
                    numberColor: color,
                    number: fill == 1.0 ? index + 1 : null,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// klasa za crtanje krugova za streak u pomodoro timeru
class CircleProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color fillColor;
  final int? number;
  final Color numberColor;

  CircleProgressPainter(
      {required this.progress,
      this.backgroundColor = Colors.grey,
      required this.fillColor,
      this.number,
      required this.numberColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);

    // kreni od gore prema dole
    if (progress > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;

      // izracunaj visinu ispunjenog dijela
      final filledHeight = size.height * progress;

      canvas.save();
      canvas.clipRect(Rect.fromLTRB(
        0,
        0, // kreni od vrha
        size.width,
        filledHeight,
      ));

      // nacrtaj ispunjeni krug
      canvas.drawCircle(center, radius, fillPaint);
      canvas.restore();
    }

    // nacrtaj broj u sredini kruga ako je ispunjen
    if (number != null && progress == 1.0) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: number.toString(),
          style: GoogleFonts.inter(
            color: numberColor,
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // centriraj tekst
      final textOffset = Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      );
      textPainter.paint(canvas, textOffset);
    }

    // nacrtaj background border
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(center, radius, backgroundPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is CircleProgressPainter &&
        (oldDelegate.progress != progress ||
            oldDelegate.backgroundColor != backgroundColor ||
            oldDelegate.fillColor != fillColor);
  }
}
