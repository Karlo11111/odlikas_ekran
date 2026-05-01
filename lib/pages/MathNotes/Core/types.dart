import 'package:flutter/material.dart';

// Tool modes
enum ToolMode { hand, pen, text, shape, ai, image }

// Drawing modes for the pen tool
enum DrawingMode { pen, marker, eraser }

// Shape types for the shape tool
enum ShapeType { circle, square, triangle, hexagon }

// Tool settings class to store properties for each drawing tool
class ToolSettings {
  Color color;
  double strokeWidth;

  ToolSettings({
    required this.color,
    required this.strokeWidth,
  });

  // Create a copy with updated values
  ToolSettings copyWith({Color? color, double? strokeWidth}) {
    return ToolSettings(
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }
}

// Color palette constants
final List<Map<String, Color>> colorPalette = [
  {'color': Colors.white, 'border': const Color(0xFFC7C7C7)},
  {'color': const Color(0xFFFFFF00), 'border': const Color(0xFFB5B500)},
  {'color': const Color(0xFFFFA500), 'border': const Color(0xFFC07C00)},
  {'color': const Color(0xFFFF2C2C), 'border': const Color(0xFFA51313)},
  {'color': const Color(0xFFEAEAEA), 'border': const Color(0xFFA6A6A6)},
  {'color': const Color(0xFF88E788), 'border': const Color(0xFF68AF68)},
  {'color': const Color(0xFF00A400), 'border': const Color(0xFF008000)},
  {'color': const Color(0xFFFD3DB5), 'border': const Color(0xFFA50067)},
  {'color': const Color(0xFF808080), 'border': const Color(0xFF575757)},
  {'color': const Color(0xFF00FFFF), 'border': const Color(0xFF00BABA)},
  {'color': const Color(0xFF006400), 'border': const Color(0xFF004200)},
  {'color': const Color(0xFF5F00BF), 'border': const Color(0xFF7F00FF)},
  {'color': Colors.black, 'border': Colors.black},
  {'color': const Color(0xFF1794D2), 'border': const Color(0xFF006698)},
  {'color': const Color(0xFF00008B), 'border': const Color(0xFF000051)},
  {'color': const Color(0xFFA020F0), 'border': const Color(0xFF6D00B1)},
];

// Transformation constants
const double MIN_SCALE = 0.1;
const double MAX_SCALE = 5.0;
const double DEFAULT_SCALE = 1.0;
