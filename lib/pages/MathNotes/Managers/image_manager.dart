import 'dart:io';
import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/whiteboard_state.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/types.dart';
import 'package:odlikas_ekran/pages/MathNotes/ImagesAdding/image_element.dart';

class ImageManager {
  final WhiteboardState state;

  ImageManager(this.state);

  void addImageToWhiteboard(String imageUrl, {Size? screenSize}) {
    if (screenSize == null) {
      screenSize = const Size(800, 600); // Default size if not provided
    }

    final center = Offset(
      screenSize.width / 2,
      screenSize.height / 2,
    );

    final transformedCenter = state.transformPoint(center);

    // Make images take up a good amount of screen space
    final newImage = ImageElement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imageUrl: imageUrl,
      position: transformedCenter,
      size: Size(screenSize.width * 0.6, screenSize.height * 0.6),
    );

    state.addImageElement(newImage);
    state.selectedImageElement = newImage;
    state.currentTool = ToolMode.image;
  }

  ImageElement? findImageElementAt(Offset position) {
    // Check if the position overlaps with any existing image element
    for (final element in state.imageElements) {
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

  void handleImageTap(Offset position) {
    final tappedImage = findImageElementAt(position);

    if (tappedImage != null) {
      // Deselect any selected text
      if (state.selectedTextElement != null) {
        if (state.selectedTextElement!.isEditing) {
          state.selectedTextElement!.isEditing = false;
        }
        state.selectedTextElement = null;
      }

      // Select/deselect this image
      if (state.selectedImageElement == tappedImage) {
        state.selectedImageElement = null;
        state.currentTool = ToolMode.hand;
      } else {
        state.selectedImageElement = tappedImage;
        state.currentTool = ToolMode.image;
      }
    }
  }

  void moveImageElement(Offset delta) {
    if (state.selectedImageElement == null) return;

    // Convert delta to account for scale
    final double scale = state.transformationMatrix.getMaxScaleOnAxis();
    final Offset scaledDelta = delta / scale;

    // Update position
    state.selectedImageElement!.position += scaledDelta;
    state.notify();
  }

  void resizeImageElement(Offset delta) {
    if (state.selectedImageElement == null) return;

    final double scale = state.transformationMatrix.getMaxScaleOnAxis();

    double newWidth =
        state.selectedImageElement!.size.width + (delta.dx / scale);
    double newHeight =
        state.selectedImageElement!.size.height + (delta.dy / scale);

    // Ensure minimum size
    newWidth = newWidth.clamp(50.0, double.infinity);
    newHeight = newHeight.clamp(50.0, double.infinity);

    state.selectedImageElement!.size = Size(newWidth, newHeight);
    state.notify();
  }

  void deleteSelectedImage() {
    if (state.selectedImageElement == null) return;

    state.removeImageElement(state.selectedImageElement!);
    state.selectedImageElement = null;
    state.currentTool = ToolMode.hand;
  }

  void setImageOpacity(double opacity) {
    if (state.selectedImageElement == null) return;

    state.selectedImageElement!.opacity = opacity.clamp(0.1, 1.0);
    state.notify();
  }

  void rotateImage(double angleInRadians) {
    if (state.selectedImageElement == null) return;

    state.selectedImageElement!.rotation = angleInRadians;
    state.notify();
  }

  Widget buildImageWidget(String imageUrl, Size size) {
    if (imageUrl.startsWith('file://')) {
      // Local file (likely from PDF conversion)
      final filePath = imageUrl.replaceFirst('file://', '');
      return Image.file(
        File(filePath),
        width: size.width,
        height: size.height,
        fit: BoxFit.contain, // Use contain to preserve aspect ratio
        errorBuilder: (context, error, stackTrace) {
          print('Error displaying local image: $error');
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 40,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    } else {
      // Network image
      return Image.network(
        imageUrl,
        width: size.width,
        height: size.height,
        fit: BoxFit.contain, // Use contain to preserve aspect ratio
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[200],
            child: const Center(
              child: Icon(
                Icons.broken_image,
                size: 40,
                color: Colors.grey,
              ),
            ),
          );
        },
      );
    }
  }
}
