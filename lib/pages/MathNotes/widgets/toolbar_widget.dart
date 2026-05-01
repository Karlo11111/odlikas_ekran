import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/types.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/whiteboard_state.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/tool.dart';

class ToolbarWidget extends StatelessWidget {
  final WhiteboardState state;
  final Function(ToolMode) onToolSelected;

  ToolbarWidget({
    super.key,
    required this.state,
    required this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 20,
      top: MediaQuery.of(context).size.height / 2 - 190,
      child: Column(
        children: [
          // Main toolbar panel
          Container(
            decoration: _panelDecoration,
            child: Column(
              children: [
                ToolButton(
                  isActive: state.currentTool == ToolMode.hand,
                  onPressed: () => onToolSelected(ToolMode.hand),
                  child: Icon(Icons.pan_tool,
                      color: state.currentTool == ToolMode.hand
                          ? const Color.fromRGBO(23, 148, 210, 1)
                          : Colors.black),
                ),
                ToolButton(
                  isActive: state.currentTool == ToolMode.pen,
                  onPressed: () => onToolSelected(ToolMode.pen),
                  child: Image.asset(
                    state.currentTool == ToolMode.pen
                        ? 'assets/icons/notes_pen_selected.png'
                        : 'assets/icons/notes_pen.png',
                    width: 35,
                    height: 35,
                  ),
                ),
                ToolButton(
                  isActive: state.currentTool == ToolMode.text,
                  onPressed: () => onToolSelected(ToolMode.text),
                  child: Image.asset(
                    state.currentTool == ToolMode.text
                        ? 'assets/icons/notes_text.png'
                        : 'assets/icons/notes_text.png',
                    width: 35,
                    height: 35,
                  ),
                ),
                ToolButton(
                  isActive: state.currentTool == ToolMode.shape,
                  onPressed: () => onToolSelected(ToolMode.shape),
                  child: Image.asset(
                    state.currentTool == ToolMode.shape
                        ? 'assets/icons/notes_shapes_selected.png'
                        : 'assets/icons/notes_shapes.png',
                    width: 35,
                    height: 35,
                  ),
                ),
                ToolButton(
                  isActive: state.currentTool == ToolMode.ai,
                  onPressed: () => onToolSelected(ToolMode.ai),
                  child: SvgPicture.asset(
                    state.currentTool == ToolMode.ai
                        ? 'assets/icons/screen_sidebar_ai_selected.svg'
                        : 'assets/icons/screen_sidebar_ai.svg',
                    width: 35,
                    height: 35,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Undo/Redo panel
          Container(
            decoration: _panelDecoration,
            child: Column(
              children: [
                ToolButton(
                  onPressed: state.undo,
                  child: Image.asset(
                    'assets/icons/notes_undo.png',
                    width: 35,
                    height: 35,
                  ),
                ),
                ToolButton(
                  onPressed: state.redo,
                  child: Image.asset(
                    'assets/icons/notes_redo.png',
                    width: 35,
                    height: 35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  final BoxDecoration _panelDecoration = BoxDecoration(
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
  );
}
