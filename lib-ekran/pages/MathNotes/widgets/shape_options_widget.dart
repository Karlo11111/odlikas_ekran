import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/whiteboard_state.dart';
import 'package:odlikas_ekran/pages/MathNotes/core/types.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/tool.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/color_width_indicator.dart';
import 'package:odlikas_ekran/pages/MathNotes/Shapes/shape_painters.dart';

class ShapeOptionsWidget extends StatelessWidget {
  final WhiteboardState state;
  final Function(ShapeType) onShapeTypeSelected;
  final VoidCallback onColorOptionsToggle;

  const ShapeOptionsWidget({
    Key? key,
    required this.state,
    required this.onShapeTypeSelected,
    required this.onColorOptionsToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 100,
      top: MediaQuery.of(context).size.height / 2 - 150,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Circle shape
            ToolButton(
              isActive: state.currentShapeType == ShapeType.circle,
              onPressed: () => onShapeTypeSelected(ShapeType.circle),
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: state.currentShapeType == ShapeType.circle
                        ? Colors.blue
                        : Colors.grey,
                    width: 2,
                  ),
                ),
              ),
            ),

            // Square shape
            ToolButton(
              isActive: state.currentShapeType == ShapeType.square,
              onPressed: () => onShapeTypeSelected(ShapeType.square),
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: state.currentShapeType == ShapeType.square
                        ? Colors.blue
                        : Colors.grey,
                    width: 2,
                  ),
                ),
              ),
            ),

            // Triangle shape
            ToolButton(
              isActive: state.currentShapeType == ShapeType.triangle,
              onPressed: () => onShapeTypeSelected(ShapeType.triangle),
              child: CustomPaint(
                size: const Size(35, 35),
                painter: TrianglePainter(
                  color: state.currentShapeType == ShapeType.triangle
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),
            ),

            // Hexagon shape
            ToolButton(
              isActive: state.currentShapeType == ShapeType.hexagon,
              onPressed: () => onShapeTypeSelected(ShapeType.hexagon),
              child: CustomPaint(
                size: const Size(35, 35),
                painter: HexagonPainter(
                  color: state.currentShapeType == ShapeType.hexagon
                      ? Colors.blue
                      : Colors.grey,
                ),
              ),
            ),

            // Color/width indicator
            ToolButton(
              child: ColorWidthIndicator(
                color: state.currentColor,
                strokeWidth: state.strokeWidth,
              ),
              onPressed: onColorOptionsToggle,
            ),
          ],
        ),
      ),
    );
  }
}
