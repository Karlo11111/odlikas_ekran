import 'package:flutter/services.dart';
import 'package:hive_flutter/adapters.dart';

part 'whiteboard_data.g.dart';

// klasa za cuvanje podataka whiteboarda
@HiveType(typeId: 0)
class WhiteboardData extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime lastModified;

  @HiveField(3)
  List<Map<String, dynamic>> paths;

  @HiveField(4)
  List<double> transformationMatrix;

  @HiveField(5)
  double currentScale;

  @HiveField(6)
  Uint8List? screenshot;

  @HiveField(7, defaultValue: [])
  List<Map<String, dynamic>> textElements = [];

  @HiveField(8, defaultValue: [])
  List<Map<String, dynamic>> shapes = [];

  @HiveField(9, defaultValue: [])
  List<Map<String, dynamic>> imageElements = [];

  // konstruktor za kreiranje whiteboarda
  WhiteboardData({
    required this.id,
    required this.name,
    required this.lastModified,
    required this.paths,
    required this.transformationMatrix,
    required this.currentScale,
    Uint8List? screenshot,
    this.textElements = const [],
    this.shapes = const [],
    this.imageElements = const [],
  });

  // metoda za kopiranje whiteboarda
  WhiteboardData copyWith({
    String? id,
    String? name,
    DateTime? lastModified,
    List<Map<String, dynamic>>? paths,
    List<double>? transformationMatrix,
    double? currentScale,
    Uint8List? screenshot,
    List<Map<String, dynamic>>? textElements,
    List<Map<String, dynamic>>? shapes,
    List<Map<String, dynamic>>? imageElements,
  }) {
    return WhiteboardData(
      id: id ?? this.id,
      name: name ?? this.name,
      lastModified: lastModified ?? this.lastModified,
      paths: paths ?? this.paths,
      transformationMatrix: transformationMatrix ?? this.transformationMatrix,
      currentScale: currentScale ?? this.currentScale,
      screenshot: screenshot ?? this.screenshot,
      textElements: textElements ?? this.textElements,
      shapes: shapes ?? this.shapes,
      imageElements: imageElements ?? this.imageElements,
    );
  }
}
