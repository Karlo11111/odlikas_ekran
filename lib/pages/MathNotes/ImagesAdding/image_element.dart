import 'package:flutter/material.dart';

// Model class for images on whiteboard
class ImageElement {
  final String id;
  final String imageUrl;
  Offset position;
  Size size;
  double opacity;
  double rotation;

  ImageElement({
    required this.id,
    required this.imageUrl,
    required this.position,
    required this.size,
    this.opacity = 1.0,
    this.rotation = 0.0,
  });

  // Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'posX': position.dx,
      'posY': position.dy,
      'width': size.width,
      'height': size.height,
      'opacity': opacity,
      'rotation': rotation,
    };
  }

  // Create from map
  static ImageElement fromMap(Map<String, dynamic> map) {
    return ImageElement(
      id: map['id'],
      imageUrl: map['imageUrl'],
      position: Offset(map['posX'], map['posY']),
      size: Size(map['width'], map['height']),
      opacity: map['opacity'],
      rotation: map['rotation'],
    );
  }
}
