import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/types.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/whiteboard_state.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/tool.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/color_width_indicator.dart';

class PenOptionsWidget extends StatelessWidget {
  final WhiteboardState state;
  final Function(DrawingMode) onDrawingModeSelected;
  final VoidCallback onColorOptionsToggle;

  const PenOptionsWidget({
    Key? key,
    required this.state,
    required this.onDrawingModeSelected,
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
            ToolButton(
              isActive: state.drawingMode == DrawingMode.pen,
              onPressed: () {
                onDrawingModeSelected(DrawingMode.pen);
              },
              child: Image.asset(
                state.drawingMode == DrawingMode.pen
                    ? 'assets/icons/notes_pen_selected.png'
                    : 'assets/icons/notes_pen.png',
                width: 35,
                height: 35,
              ),
            ),
            ToolButton(
              isActive: state.drawingMode == DrawingMode.marker,
              onPressed: () {
                onDrawingModeSelected(DrawingMode.marker);
              },
              child: Image.asset(
                state.drawingMode == DrawingMode.marker
                    ? 'assets/icons/notes_marker_selected.png'
                    : 'assets/icons/notes_marker.png',
                width: 35,
                height: 35,
              ),
            ),
            ToolButton(
              isActive: state.drawingMode == DrawingMode.eraser,
              onPressed: () {
                onDrawingModeSelected(DrawingMode.eraser);
              },
              child: Image.asset(
                state.drawingMode == DrawingMode.eraser
                    ? 'assets/icons/notes_eraser_selected.png'
                    : 'assets/icons/notes_eraser.png',
                width: 35,
                height: 35,
              ),
            ),
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
