import 'package:flutter/material.dart';

// klasa modela teksta za whiteboard
class TextElement {
  final String id;
  String text;
  double fontSize;
  Offset position;
  Size size;
  bool isEditing;

  TextElement({
    required this.id,
    this.text = '',
    this.fontSize = 24,
    required this.position,
    this.size = const Size(150, 50),
    this.isEditing = false,
  });

  // funkcija za pretvorbu teksta u mapu
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'fontSize': fontSize,
      'posX': position.dx,
      'posY': position.dy,
      'width': size.width,
      'height': size.height,
      'isEditing': isEditing,
    };
  }

  // funkcija za kreiranje teksta iz mape
  static TextElement fromMap(Map<String, dynamic> map) {
    return TextElement(
      id: map['id'],
      text: map['text'],
      fontSize: map['fontSize'],
      position: Offset(map['posX'], map['posY']),
      size: Size(map['width'], map['height']),
      isEditing: map['isEditing'],
    );
  }
}
