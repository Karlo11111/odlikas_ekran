import 'package:flutter/material.dart';

// klasa za crtanje putanje pomocu CustomPainter-a
class DrawingPath {
  final List<Map<String, dynamic>> commands;
  final Color color;
  final double strokeWidth;
  final DrawingMode drawingMode;

  DrawingPath({
    required this.commands,
    required this.color,
    required this.strokeWidth,
    required this.drawingMode,
  });

  // metoda za pretvorbu putanje u flutterovu klasu - Path
  Path toPath() {
    final path = Path();
    for (final cmd in commands) {
      final type = cmd['type'] as String;
      switch (type) {
        case 'moveTo':
          path.moveTo(
            (cmd['x'] as num).toDouble(),
            (cmd['y'] as num).toDouble(),
          );
          break;
        case 'lineTo':
          path.lineTo(
            (cmd['x'] as num).toDouble(),
            (cmd['y'] as num).toDouble(),
          );
          break;
        case 'cubicTo':
          path.cubicTo(
            (cmd['x1'] as num).toDouble(),
            (cmd['y1'] as num).toDouble(),
            (cmd['x2'] as num).toDouble(),
            (cmd['y2'] as num).toDouble(),
            (cmd['x3'] as num).toDouble(),
            (cmd['y3'] as num).toDouble(),
          );
          break;
        case 'close':
          path.close();
          break;
      }
    }
    return path;
  }

  // metoda za pretvorbu putanje u mapu
  Map<String, dynamic> toMap() {
    return {
      'color': color.value,
      'strokeWidth': strokeWidth,
      'drawingMode': drawingMode.index,
      'commands': commands,
    };
  }

  // metoda za kreiranje putanje iz mape
  factory DrawingPath.fromMap(Map<String, dynamic> map) {
    return DrawingPath(
      commands: List<Map<String, dynamic>>.from(map['commands'] as List),
      color: Color(map['color'] as int),
      strokeWidth: (map['strokeWidth'] as num).toDouble(),
      drawingMode: DrawingMode.values[map['drawingMode'] as int],
    );
  }
}

// enumeracija za nacin crtanja
enum DrawingMode { pen, marker, eraser }
