import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/types.dart';
import 'package:odlikas_ekran/pages/MathNotes/ImagesAdding/image_element.dart';
import 'package:odlikas_ekran/pages/MathNotes/Shapes/shape_shape.dart';
import 'package:odlikas_ekran/pages/MathNotes/TextAdding/text_model.dart';
import 'package:odlikas_ekran/pages/MathNotes/undoable_operation.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/drawing_path.dart';
import 'package:vector_math/vector_math_64.dart' as vm;

class WhiteboardState extends ChangeNotifier {
  // Transformation and scaling
  Matrix4 _transformationMatrix = Matrix4.identity();
  Matrix4 _initialTransformationMatrix = Matrix4.identity();
  Offset _initialGestureFocalPoint = Offset.zero;
  double _currentScale = DEFAULT_SCALE;
  double _lastScale = DEFAULT_SCALE;
  Offset? _lastPanOffset;

  // Tool selection
  ToolMode _currentTool = ToolMode.hand;
  DrawingMode _drawingMode = DrawingMode.pen;

  // Element collections
  List<DrawingPath> _paths = [];
  List<ShapeShape> _shapes = [];
  List<TextElement> _textElements = [];
  List<ImageElement> _imageElements = [];

  // Current elements being edited
  Path? _currentPath;
  List<Map<String, dynamic>>? _currentCommands;
  ShapeShape? _currentShape;
  TextElement? _selectedTextElement;
  ImageElement? _selectedImageElement;

  // Tool properties
  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;
  ShapeType _currentShapeType = ShapeType.circle;

  // Tool settings
  final Map<DrawingMode, ToolSettings> _toolSettings = {
    DrawingMode.pen: ToolSettings(
      color: Colors.black,
      strokeWidth: 3.0,
    ),
    DrawingMode.marker: ToolSettings(
      color: Colors.blue.withOpacity(0.5),
      strokeWidth: 8.0,
    ),
    DrawingMode.eraser: ToolSettings(
      color: Colors.white,
      strokeWidth: 20.0,
    ),
  };

  // History for undo/redo
  List<UndoableAction> _undoStack = [];
  List<UndoableAction> _redoStack = [];

  // UI state
  bool _showPenOptions = false;
  bool _showColorOptions = false;
  bool _showShapeOptions = false;

  // AI selection
  bool _isSelectingArea = false;
  Offset? _selectionStart;
  Offset? _selectionEnd;

  // AI results
  Uint8List? _capturedImage;
  String? _latexResult;
  bool _isOpenAiLoading = false;
  List<Map<String, String>>? _openAiAnswer;

  // Getters
  Matrix4 get transformationMatrix => _transformationMatrix;
  Matrix4 get initialTransformationMatrix => _initialTransformationMatrix;
  Offset get initialGestureFocalPoint => _initialGestureFocalPoint;
  double get currentScale => _currentScale;
  double get lastScale => _lastScale;
  Offset? get lastPanOffset => _lastPanOffset;

  ToolMode get currentTool => _currentTool;
  DrawingMode get drawingMode => _drawingMode;

  List<DrawingPath> get paths => _paths;
  List<ShapeShape> get shapes => _shapes;
  List<TextElement> get textElements => _textElements;
  List<ImageElement> get imageElements => _imageElements;

  Path? get currentPath => _currentPath;
  List<Map<String, dynamic>>? get currentCommands => _currentCommands;
  ShapeShape? get currentShape => _currentShape;
  TextElement? get selectedTextElement => _selectedTextElement;
  ImageElement? get selectedImageElement => _selectedImageElement;

  Color get currentColor => _currentColor;
  double get strokeWidth => _strokeWidth;
  ShapeType get currentShapeType => _currentShapeType;
  Map<DrawingMode, ToolSettings> get toolSettings => _toolSettings;

  bool get showPenOptions => _showPenOptions;
  bool get showColorOptions => _showColorOptions;
  bool get showShapeOptions => _showShapeOptions;

  bool get isSelectingArea => _isSelectingArea;
  Offset? get selectionStart => _selectionStart;
  Offset? get selectionEnd => _selectionEnd;

  Uint8List? get capturedImage => _capturedImage;
  String? get latexResult => _latexResult;
  bool get isOpenAiLoading => _isOpenAiLoading;
  List<Map<String, String>>? get openAiAnswer => _openAiAnswer;

  // Setters
  set currentTool(ToolMode mode) {
    _currentTool = mode;
    notifyListeners();
  }

  set drawingMode(DrawingMode mode) {
    _drawingMode = mode;
    notifyListeners();
  }

  set currentPath(Path? path) {
    _currentPath = path;
    notifyListeners();
  }

  set currentCommands(List<Map<String, dynamic>>? commands) {
    _currentCommands = commands;
  }

  set currentShape(ShapeShape? shape) {
    _currentShape = shape;
    notifyListeners();
  }

  set selectedTextElement(TextElement? element) {
    _selectedTextElement = element;
    notifyListeners();
  }

  set selectedImageElement(ImageElement? element) {
    _selectedImageElement = element;
    notifyListeners();
  }

  set transformationMatrix(Matrix4 matrix) {
    _transformationMatrix = matrix;
    notifyListeners();
  }

  set initialTransformationMatrix(Matrix4 matrix) {
    _initialTransformationMatrix = matrix;
  }

  set initialGestureFocalPoint(Offset point) {
    _initialGestureFocalPoint = point;
  }

  set currentScale(double scale) {
    _currentScale = scale;
    notifyListeners();
  }

  set lastScale(double scale) {
    _lastScale = scale;
  }

  set lastPanOffset(Offset? offset) {
    _lastPanOffset = offset;
  }

  set currentColor(Color color) {
    _currentColor = color;
    notifyListeners();
  }

  set strokeWidth(double width) {
    _strokeWidth = width;
    notifyListeners();
  }

  set currentShapeType(ShapeType type) {
    _currentShapeType = type;
    notifyListeners();
  }

  set showPenOptions(bool show) {
    _showPenOptions = show;
    notifyListeners();
  }

  set showColorOptions(bool show) {
    _showColorOptions = show;
    notifyListeners();
  }

  set showShapeOptions(bool show) {
    _showShapeOptions = show;
    notifyListeners();
  }

  set isSelectingArea(bool selecting) {
    _isSelectingArea = selecting;
    notifyListeners();
  }

  set selectionStart(Offset? offset) {
    _selectionStart = offset;
    notifyListeners();
  }

  set selectionEnd(Offset? offset) {
    _selectionEnd = offset;
    notifyListeners();
  }

  set capturedImage(Uint8List? image) {
    _capturedImage = image;
    notifyListeners();
  }

  set latexResult(String? result) {
    _latexResult = result;
    notifyListeners();
  }

  set isOpenAiLoading(bool loading) {
    _isOpenAiLoading = loading;
    notifyListeners();
  }

  set openAiAnswer(List<Map<String, String>>? answer) {
    _openAiAnswer = answer;
    notifyListeners();
  }

  // In Core/whiteboard_state.dart
  set paths(List<DrawingPath> value) {
    _paths = value;
    notifyListeners();
  }

  set textElements(List<TextElement> value) {
    _textElements = value;
    notifyListeners();
  }

  set shapes(List<ShapeShape> value) {
    _shapes = value;
    notifyListeners();
  }

  set imageElements(List<ImageElement> value) {
    _imageElements = value;
    notifyListeners();
  }

  // Methods for manipulating state
  void addPath(DrawingPath path) {
    _paths.add(path);
    _recordAction(UndoableAction(type: ActionType.addPath, item: path));
    notifyListeners();
  }

  void addShape(ShapeShape shape) {
    _shapes.add(shape);
    _recordAction(UndoableAction(type: ActionType.addShape, item: shape));
    notifyListeners();
  }

  void addTextElement(TextElement element) {
    _textElements.add(element);
    _recordAction(UndoableAction(type: ActionType.addText, item: element));
    notifyListeners();
  }

  void addImageElement(ImageElement element) {
    _imageElements.add(element);
    _recordAction(UndoableAction(type: ActionType.addImage, item: element));
    notifyListeners();
  }

  void removeTextElement(TextElement element) {
    final index = _textElements.indexOf(element);
    if (index != -1) {
      final removedElement = _textElements.removeAt(index);
      _recordAction(UndoableAction(
        type: ActionType.deleteText,
        item: removedElement,
        index: index,
      ));
      notifyListeners();
    }
  }

  void removeImageElement(ImageElement element) {
    final index = _imageElements.indexOf(element);
    if (index != -1) {
      final removedElement = _imageElements.removeAt(index);
      _recordAction(UndoableAction(
        type: ActionType.deleteImage,
        item: removedElement,
        index: index,
      ));
      notifyListeners();
    }
  }

  void setToolSettings(DrawingMode mode, {Color? color, double? strokeWidth}) {
    if (color != null) {
      _toolSettings[mode]!.color = color;
    }
    if (strokeWidth != null) {
      _toolSettings[mode]!.strokeWidth = strokeWidth;
    }
    notifyListeners();
  }

  void updateToolFromSettings() {
    final settings = _toolSettings[_drawingMode]!;
    _currentColor = settings.color;
    _strokeWidth = settings.strokeWidth;
    notifyListeners();
  }

  Offset transformPoint(Offset screenOffset) {
    final inverseMatrix = Matrix4.inverted(_transformationMatrix);
    final transformed = inverseMatrix
        .transform3(vm.Vector3(screenOffset.dx, screenOffset.dy, 0));
    return Offset(transformed.x, transformed.y);
  }

  void togglePenOptions() {
    _showPenOptions = !_showPenOptions;
    _showShapeOptions = false;
    _showColorOptions = false;
    notifyListeners();
  }

  void toggleShapeOptions() {
    _showShapeOptions = !_showShapeOptions;
    _showPenOptions = false;
    _showColorOptions = false;
    notifyListeners();
  }

  void toggleColorOptions() {
    _showColorOptions = !_showColorOptions;
    notifyListeners();
  }

  void changeTool(ToolMode mode) {
    _currentTool = mode;

    if (mode != ToolMode.text) {
      _selectedTextElement = null;
      _showPenOptions = false;
      _showColorOptions = false;
      // Hide keyboard if not in text mode
      FocusManager.instance.primaryFocus?.unfocus();
    }

    if (mode == ToolMode.hand) {
      _showPenOptions = false;
      _showColorOptions = false;
      _showShapeOptions = false;
    }

    // Set all text elements to non-editing mode
    for (var element in _textElements) {
      element.isEditing = false;
    }

    notifyListeners();
  }

  void _recordAction(UndoableAction action) {
    _undoStack.add(action);
    _redoStack.clear();
  }

  T _getTypedItem<T>(dynamic item) {
    if (item is T) {
      return item;
    }
    throw Exception(
        'Invalid item type: expected $T but got ${item.runtimeType}');
  }

  void undo() {
    if (_undoStack.isEmpty) return;

    final action = _undoStack.removeLast();
    _redoStack.add(action);

    switch (action.type) {
      case ActionType.addPath:
        final lastIndex = _paths.length - 1;
        if (lastIndex >= 0) {
          final path = _paths.removeAt(lastIndex);
          _redoStack.last = UndoableAction(
            type: ActionType.deletePath,
            item: path,
            index: lastIndex,
            timestamp: action.timestamp,
          );
        }
        break;

      case ActionType.addShape:
        final lastIndex = _shapes.length - 1;
        if (lastIndex >= 0) {
          final shape = _shapes.removeAt(lastIndex);
          _redoStack.last = UndoableAction(
            type: ActionType.deleteShape,
            item: shape,
            index: lastIndex,
            timestamp: action.timestamp,
          );
        }
        break;

      case ActionType.addText:
        final lastIndex = _textElements.length - 1;
        if (lastIndex >= 0) {
          final text = _textElements.removeAt(lastIndex);
          _redoStack.last = UndoableAction(
            type: ActionType.deleteText,
            item: text,
            index: lastIndex,
            timestamp: action.timestamp,
          );
        }
        break;

      case ActionType.deletePath:
        try {
          final path = _getTypedItem<DrawingPath>(action.item);
          if (action.index >= 0 && action.index <= _paths.length) {
            _paths.insert(action.index, path);
          } else {
            _paths.add(path);
          }
        } catch (e) {
          print('Error during undo: $e');
        }
        break;

      case ActionType.deleteShape:
        try {
          final shape = _getTypedItem<ShapeShape>(action.item);
          if (action.index >= 0 && action.index <= _shapes.length) {
            _shapes.insert(action.index, shape);
          } else {
            _shapes.add(shape);
          }
        } catch (e) {
          print('Error during undo: $e');
        }
        break;

      case ActionType.deleteText:
        try {
          final text = _getTypedItem<TextElement>(action.item);
          if (action.index >= 0 && action.index <= _textElements.length) {
            _textElements.insert(action.index, text);
          } else {
            _textElements.add(text);
          }
        } catch (e) {
          print('Error during undo: $e');
        }
        break;

      case ActionType.addImage:
        final lastIndex = _imageElements.length - 1;
        if (lastIndex >= 0) {
          final image = _imageElements.removeAt(lastIndex);
          _redoStack.last = UndoableAction(
            type: ActionType.deleteImage,
            item: image,
            index: lastIndex,
            timestamp: action.timestamp,
          );
        }
        break;

      case ActionType.deleteImage:
        try {
          final image = _getTypedItem<ImageElement>(action.item);
          if (action.index >= 0 && action.index <= _imageElements.length) {
            _imageElements.insert(action.index, image);
          } else {
            _imageElements.add(image);
          }
        } catch (e) {
          print('Error during undo: $e');
        }
        break;
    }

    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;

    final action = _redoStack.removeLast();
    _undoStack.add(action);

    switch (action.type) {
      case ActionType.deletePath:
        try {
          final path = _getTypedItem<DrawingPath>(action.item);
          if (action.index >= 0 && action.index < _paths.length) {
            _paths.insert(action.index, path);
          } else {
            _paths.add(path);
          }
          _undoStack.last = UndoableAction(
            type: ActionType.addPath,
            item: path,
            timestamp: action.timestamp,
          );
        } catch (e) {
          print('Error during redo: $e');
        }
        break;

      case ActionType.deleteShape:
        try {
          final shape = _getTypedItem<ShapeShape>(action.item);
          if (action.index >= 0 && action.index < _shapes.length) {
            _shapes.insert(action.index, shape);
          } else {
            _shapes.add(shape);
          }
          _undoStack.last = UndoableAction(
            type: ActionType.addShape,
            item: shape,
            timestamp: action.timestamp,
          );
        } catch (e) {
          print('Error during redo: $e');
        }
        break;

      case ActionType.deleteText:
        try {
          final text = _getTypedItem<TextElement>(action.item);
          if (action.index >= 0 && action.index < _textElements.length) {
            _textElements.insert(action.index, text);
          } else {
            _textElements.add(text);
          }
          _undoStack.last = UndoableAction(
            type: ActionType.addText,
            item: text,
            timestamp: action.timestamp,
          );
        } catch (e) {
          print('Error during redo: $e');
        }
        break;

      case ActionType.addPath:
        final lastIndex = _paths.length - 1;
        if (lastIndex >= 0) {
          _paths.removeAt(lastIndex);
        }
        break;

      case ActionType.addShape:
        final lastIndex = _shapes.length - 1;
        if (lastIndex >= 0) {
          _shapes.removeAt(lastIndex);
        }
        break;

      case ActionType.addText:
        final lastIndex = _textElements.length - 1;
        if (lastIndex >= 0) {
          _textElements.removeAt(lastIndex);
        }
        break;

      case ActionType.addImage:
        final lastIndex = _imageElements.length - 1;
        if (lastIndex >= 0) {
          _imageElements.removeAt(lastIndex);
        }
        break;

      case ActionType.deleteImage:
        try {
          final image = _getTypedItem<ImageElement>(action.item);
          if (action.index >= 0 && action.index < _imageElements.length) {
            _imageElements.insert(action.index, image);
          } else {
            _imageElements.add(image);
          }
          _undoStack.last = UndoableAction(
            type: ActionType.addImage,
            item: image,
            timestamp: action.timestamp,
          );
        } catch (e) {
          print('Error during redo: $e');
        }
        break;
    }

    notifyListeners();
  }

  void resetSelections() {
    _selectedTextElement = null;
    _selectedImageElement = null;
    notifyListeners();
  }

  void clearAll() {
    _paths.clear();
    _shapes.clear();
    _textElements.clear();
    _imageElements.clear();
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
