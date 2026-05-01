import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/whiteboard_state.dart';
import 'package:odlikas_ekran/pages/MathNotes/TextAdding/text_model.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/types.dart';

class TextManager {
  final WhiteboardState state;

  TextManager(this.state);

  void handleTextTap(Offset position) {
    if (state.currentTool != ToolMode.text) return;

    // First check if we tapped on an existing text element
    TextElement? tappedElement = _findTextElementAt(position);

    if (tappedElement != null) {
      // We tapped on an existing element, select it
      state.selectedTextElement = tappedElement;
    } else if (state.selectedTextElement == null) {
      // We tapped on empty space, create a new text element
      _createNewTextElement(position);
    } else {
      // We already had a selected element but tapped elsewhere
      // Deselect it and switch to hand tool
      state.selectedTextElement = null;
      state.currentTool = ToolMode.hand;
      // Dismiss keyboard
      FocusManager.instance.primaryFocus?.unfocus();
    }
  }

  TextElement? _findTextElementAt(Offset position) {
    // Check if the position overlaps with any existing text element
    for (final element in state.textElements) {
      final Offset elementPosition = element.position;
      final Size elementSize = element.size;

      final double scale = state.transformationMatrix.getMaxScaleOnAxis();
      final double dx = state.transformationMatrix.getTranslation().x;
      final double dy = state.transformationMatrix.getTranslation().y;

      final Offset transformedPosition = Offset(
          elementPosition.dx * scale + dx, elementPosition.dy * scale + dy);

      final Rect elementRect = Rect.fromLTWH(
          transformedPosition.dx,
          transformedPosition.dy,
          elementSize.width * scale,
          elementSize.height * scale);

      if (elementRect.contains(position)) {
        return element;
      }
    }

    return null;
  }

  void _createNewTextElement(Offset position) {
    // Get current scale (zoom level)
    final double scale = state.transformationMatrix.getMaxScaleOnAxis();

    // Base sizes for text
    const double baseWidth = 150.0;
    const double baseHeight = 50.0;
    const double baseFontSize = 24.0;

    // Calculate size and position based on current scale
    final double adjustedWidth = baseWidth / scale;
    final double adjustedHeight = baseHeight / scale;
    final double adjustedFontSize = baseFontSize / scale;

    // Create new text element
    final newElement = TextElement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      position: state.transformPoint(position),
      fontSize: adjustedFontSize,
      size: Size(adjustedWidth, adjustedHeight),
      isEditing: true,
    );

    // Add to state and select it
    state.addTextElement(newElement);
    state.selectedTextElement = newElement;
  }

  void moveTextElement(Offset delta) {
    if (state.selectedTextElement == null) return;

    // Convert delta to account for scale
    final double scale = state.transformationMatrix.getMaxScaleOnAxis();
    final Offset scaledDelta = delta / scale;

    // Update position
    state.selectedTextElement!.position += scaledDelta;
    state.notify();
  }

  void setTextEditing(bool isEditing) {
    if (state.selectedTextElement == null) return;

    state.selectedTextElement!.isEditing = isEditing;
    state.notify();
  }

  void updateTextContent(String text) {
    if (state.selectedTextElement == null) return;

    state.selectedTextElement!.text = text;
    state.notify();
  }

  void resizeTextElement(Offset delta) {
    if (state.selectedTextElement == null) return;

    final double scale = state.transformationMatrix.getMaxScaleOnAxis();

    // Apply scaling factor for consistent resize behavior
    double newWidth =
        state.selectedTextElement!.size.width + (delta.dx / scale) * 0.5;
    double newHeight =
        state.selectedTextElement!.size.height + (delta.dy / scale) * 0.5;

    // Ensure minimum size
    newWidth = newWidth.clamp(50.0, double.infinity);
    newHeight = newHeight.clamp(30.0, double.infinity);

    state.selectedTextElement!.size = Size(newWidth, newHeight);

    // Proportionally adjust font size
    state.selectedTextElement!.fontSize = newHeight * 0.5;

    state.notify();
  }

  void deleteSelectedText() {
    if (state.selectedTextElement == null) return;

    state.removeTextElement(state.selectedTextElement!);
    state.selectedTextElement = null;
    state.currentTool = ToolMode.hand;
  }
}
