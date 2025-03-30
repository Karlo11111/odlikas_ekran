// ignore_for_file: prefer_final_fields, unused_field, depend_on_referenced_packages, library_private_types_in_public_api, deprecated_member_use, avoid_print, unused_local_variable

import 'dart:ui';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:latext/latext.dart';
import 'package:odlikas_ekran/database/api/deepseek_service.dart';
import 'package:odlikas_ekran/database/api/matpix_ai_solving.dart';
import 'package:odlikas_ekran/pages/MathNotes/ImagesAdding/image_element.dart';
import 'package:odlikas_ekran/pages/MathNotes/Shapes/shape_shape.dart';
import 'package:odlikas_ekran/pages/MathNotes/Shapes/shape_painters.dart';
import 'package:odlikas_ekran/pages/MathNotes/TextAdding/text_model.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/debouncer.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/screenshot_manager.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/whiteboard_data.dart';
import 'package:odlikas_ekran/pages/MathNotes/undoable_operation.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/color_width_indicator.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/drawing_path.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/select_rectangle_mathpix.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/tool.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/white_board_painter.dart';
import 'package:odlikas_ekran/pages/SolutionStepsPage/solution_steps_page.dart';
import 'package:odlikas_ekran/pages/UploadFiles/uploaded_files.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as imglib;
import 'dart:ui' as ui;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class MathNotes extends StatefulWidget {
  final WhiteboardData? whiteboardData;
  const MathNotes({super.key, this.whiteboardData});

  @override
  _MathNotesState createState() => _MathNotesState();
}

class _MathNotesState extends State<MathNotes> {
  GlobalKey _whiteboardKey = GlobalKey();
  // color paleta za biranje boja
  final List<Map<String, Color>> _colorPalette = [
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

  // postavke za alate (boje, debljine linija)
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

  // matrica transformacije za skaliranje i micanje whiteboarda
  Matrix4 _transformationMatrix = Matrix4.identity();

  Matrix4 _initialTransformationMatrix = Matrix4.identity();
  Offset _initialGestureFocalPoint = Offset.zero;

  final double _minScale = 0.1;
  final double _maxScale = 5.0;

  double _currentScale = 1.0;
  double _lastScale = 1.0;

  ToolMode _currentTool = ToolMode.hand;
  DrawingMode _drawingMode = DrawingMode.pen;

  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;

  Offset? _lastPanOffset;

  List<UndoableAction> _undoStack = [];
  List<UndoableAction> _redoStack = [];

  bool _showPenOptions = false;
  bool _showColorOptions = false;

  // AI image selector varijable
  bool _isSelectingArea = false;
  Offset? _selectionStart;
  Offset? _selectionEnd;

  //text creating
  List<TextElement> _textElements = [];
  TextElement? _selectedTextElement;

  //shapes drawing
  bool _showShapeOptions = false;
  ShapeType _currentShapeType = ShapeType.circle;
  ShapeShape? _currentShape; // koji shape je crtan
  // Add a list to store shapes
  List<ShapeShape> _shapes = [];

  // adding images to the board
  List<ImageElement> _imageElements = [];
  ImageElement? _selectedImageElement;

  // ovo je za ai mathpix image
  Uint8List? _capturedImage;
  String? _latexResult;
  bool _isOpenAiLoading = false;
  List<Map<String, String>>? _openAiAnswer;

  // spremanje whiteboarda u hive
  late final Box<WhiteboardData> _whiteboardsBox;
  late WhiteboardData _whiteboardData;
  final _saveDebounce = Debouncer(delay: const Duration(seconds: 1));
  List<DrawingPath> _paths = [];
  List<Map<String, dynamic>>? _currentCommands;
  Path? _currentPath;

  @override
  void initState() {
    super.initState();
    _whiteboardsBox = Hive.box<WhiteboardData>('whiteboards');
    _whiteboardData = widget.whiteboardData!;
    _loadSavedState();

    _imageElements = _whiteboardData.imageElements
        .map((img) => ImageElement.fromMap(_convertMap(img)))
        .toList();

    // delay prvi autosave dok se rendera app
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _autoSave(force: true);
      }
    });
  }

  @override
  void dispose() {
    _saveDebounce.cancel(); // zaustavi debounce
    _saveNow(); // spremi sve promjene
    super.dispose();
  }

  void _loadSavedState() {
    _paths = _whiteboardData.paths
        .map((path) => DrawingPath.fromMap(_convertMap(path)))
        .toList();

    _transformationMatrix =
        Matrix4.fromList(_whiteboardData.transformationMatrix);
    _currentScale = _whiteboardData.currentScale;

    _textElements = _whiteboardData.textElements
        .map((te) => TextElement.fromMap(_convertMap(te)))
        .toList();
    _shapes = _whiteboardData.shapes
        .map((shape) => ShapeShape.fromMap(_convertMap(shape)))
        .toList();
  }

  // funkcija za pretvaranje mape u mapu stringova
  Map<String, dynamic> _convertMap(Map<dynamic, dynamic> originalMap) {
    return Map<String, dynamic>.fromIterable(
      originalMap.entries,
      key: (entry) => entry.key.toString(),
      value: (entry) {
        if (entry.value is Map<dynamic, dynamic>) {
          return _convertMap(entry.value);
        } else if (entry.value is List) {
          return _convertList(entry.value);
        }
        return entry.value;
      },
    );
  }

  // funkcija za pretvaranje liste u listu stringova
  List<dynamic> _convertList(List<dynamic> originalList) {
    return originalList.map((item) {
      if (item is Map<dynamic, dynamic>) {
        return _convertMap(item);
      } else if (item is List) {
        return _convertList(item);
      }
      return item;
    }).toList();
  }

  // funkcija za sejvanje whiteboarda
  Future<void> _autoSave({bool force = false}) async {
    if (force) {
      await _saveNow(); // spremi odma bez debounca
    } else {
      _saveDebounce.run(() => _saveNow());
    }
  }

  // funkcija za dodavanje slike na whiteboard
  void _addImageToWhiteboard(String imageUrl) {
    final center = Offset(
      MediaQuery.of(context).size.width / 2,
      MediaQuery.of(context).size.height / 2,
    );

    final transformedCenter = _transformPoint(center);

    // Make images take up more screen space
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final newImage = ImageElement(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      imageUrl: imageUrl,
      position: transformedCenter,
      size: Size(screenWidth * 3.6, screenHeight * 3.6),
    );

    setState(() {
      _imageElements.add(newImage);
      _recordAction(UndoableAction(
        type: ActionType.addImage,
        item: newImage,
      ));
      _selectedImageElement = newImage;
      _currentTool = ToolMode.image;
    });

    _autoSave();
  }

  Widget imageWidget(String imageUrl, Size size) {
    if (imageUrl.startsWith('file://')) {
      // Local file (likely from PDF conversion)
      final filePath = imageUrl.replaceFirst('file://', '');
      return Image.file(
        File(filePath),
        width: size.width,
        height: size.height,
        fit: BoxFit.contain, // Use contain to preserve aspect ratio
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error displaying local image: $error');
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

  // sejvaj objekt u hive bazu
  Future<void> _saveNow() async {
    try {
      // Prepare data for saving
      _whiteboardData.lastModified = DateTime.now();
      _whiteboardData.paths =
          List<Map<String, dynamic>>.from(_paths.map((p) => p.toMap()));
      _whiteboardData.transformationMatrix =
          List<double>.from(_transformationMatrix.storage);
      _whiteboardData.currentScale = _currentScale;
      _whiteboardData.textElements = List<Map<String, dynamic>>.from(
          _textElements.map((te) => te.toMap()));
      _whiteboardData.shapes =
          List<Map<String, dynamic>>.from(_shapes.map((s) => s.toMap()));
      _whiteboardData.imageElements = List<Map<String, dynamic>>.from(
          _imageElements.map((img) => img.toMap()));

      // Get the overall size of the whiteboard
      final Size canvasSize =
          _whiteboardKey.currentContext?.size ?? const Size(800, 700);

      // Create a recorder and canvas
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);

      // Fill the background with white
      canvas.drawRect(
        Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
        Paint()..color = Colors.white,
      );

      // Apply transformations
      canvas.save();
      canvas.transform(_transformationMatrix.storage);

      // Draw all shapes
      for (final shape in _shapes) {
        shape.draw(canvas);
      }

      // Draw all paths
      for (final drawingPath in _paths) {
        final path = drawingPath.toPath();
        final paint = Paint()
          ..color = drawingPath.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = drawingPath.strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawPath(path, paint);
      }

      // Draw text elements
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
      );

      for (final element in _textElements) {
        textPainter.text = TextSpan(
          text: element.text,
          style: TextStyle(
            fontSize: element.fontSize,
            color: Colors.black,
          ),
        );

        textPainter.layout();
        textPainter.paint(canvas, element.position);
      }

      // Preload images before drawing
      if (_imageElements.isNotEmpty) {
        try {
          // Cache manager to load network images
          final cacheManager = DefaultCacheManager();

          // Load all images in parallel
          final futures = <Future<ui.Image>>[];
          final imageMap = <String, ui.Image>{};

          for (final imageElement in _imageElements) {
            final url = imageElement.imageUrl;

            // Handle local file path images (from PDF)
            if (url.startsWith('file://')) {
              final filePath = url.replaceFirst('file://', '');
              final file = File(filePath);
              if (await file.exists()) {
                final bytes = await file.readAsBytes();
                final codec = await ui.instantiateImageCodec(bytes);
                final frame = await codec.getNextFrame();
                imageMap[url] = frame.image;
                futures.add(Future.value(frame.image));
              } else {
                debugPrint('Local file does not exist: $filePath');
                // Add a placeholder image
                final placeholderFuture = _createPlaceholderImage();
                futures.add(placeholderFuture);
                placeholderFuture.then((image) => imageMap[url] = image);
              }
            }
            // Handle network images
            else {
              final future = cacheManager.getSingleFile(url).then((file) async {
                final bytes = await file.readAsBytes();
                final codec = await ui.instantiateImageCodec(bytes);
                final frame = await codec.getNextFrame();
                imageMap[url] = frame.image;
                return frame.image;
              }).catchError((e) {
                debugPrint('Error loading image: $e');
                return _createPlaceholderImage();
              });

              futures.add(future);
            }
          }

          // Wait for all images to load (or fail)
          await Future.wait(futures);

          // Draw all images
          for (final imageElement in _imageElements) {
            final image = imageMap[imageElement.imageUrl];
            if (image != null) {
              // Calculate the image rect based on position and size
              final destRect = Rect.fromLTWH(
                imageElement.position.dx,
                imageElement.position.dy,
                imageElement.size.width,
                imageElement.size.height,
              );

              // Create paint with opacity
              final paint = Paint()
                ..filterQuality = FilterQuality.medium
                ..isAntiAlias = true
                ..color = Colors.white.withOpacity(imageElement.opacity);

              // Handle rotation if needed
              if (imageElement.rotation != 0.0) {
                canvas.save();

                // Translate to center, rotate, translate back
                final center = Offset(
                  destRect.left + destRect.width / 2,
                  destRect.top + destRect.height / 2,
                );

                canvas.translate(center.dx, center.dy);
                canvas.rotate(imageElement.rotation);
                canvas.translate(-center.dx, -center.dy);

                canvas.drawImageRect(
                  image,
                  Rect.fromLTWH(
                      0, 0, image.width.toDouble(), image.height.toDouble()),
                  destRect,
                  paint,
                );

                canvas.restore();
              } else {
                // Draw without rotation
                canvas.drawImageRect(
                  image,
                  Rect.fromLTWH(
                      0, 0, image.width.toDouble(), image.height.toDouble()),
                  destRect,
                  paint,
                );
              }
            }
          }
        } catch (e) {
          debugPrint('Error processing images: $e');
        }
      }

      // Restore canvas and create the image
      canvas.restore();
      final ui.Picture picture = recorder.endRecording();
      final ui.Image image = await picture.toImage(
        canvasSize.width.toInt(),
        canvasSize.height.toInt(),
      );

      // Convert to PNG bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final bytes = byteData.buffer.asUint8List();
        await ScreenshotManager.saveScreenshot(_whiteboardData.id, bytes);
        _whiteboardData.screenshot = null;
        debugPrint(
            'Manual screenshot captured and saved: ${bytes.length} bytes');
      }
    } catch (e, stack) {
      debugPrint('Screenshot error: $e\n$stack');

      // Create a fallback thumbnail
      try {
        // Draw a simple rectangle with a gradient as a fallback
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        final Canvas canvas = Canvas(recorder);

        // Create a gradient background with the whiteboard's name
        final Rect rect = Rect.fromLTWH(0, 0, 400, 300);

        // Use a gradient that visually indicates this is a whiteboard
        final gradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade50, Colors.blue.shade100],
        );

        canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

        // Add a text label
        final textPainter = TextPainter(
          text: TextSpan(
            text: _whiteboardData.name,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 24,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout(maxWidth: 350);
        textPainter.paint(
          canvas,
          Offset(
            (400 - textPainter.width) / 2,
            (300 - textPainter.height) / 2,
          ),
        );

        // Convert to image
        final ui.Picture picture = recorder.endRecording();
        final ui.Image image = await picture.toImage(400, 300);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          final bytes = byteData.buffer.asUint8List();
          await ScreenshotManager.saveScreenshot(_whiteboardData.id, bytes);
          _whiteboardData.screenshot = null;
          debugPrint('Fallback thumbnail saved: ${bytes.length} bytes');
        }
      } catch (fallbackError) {
        debugPrint('Fallback thumbnail also failed: $fallbackError');
      }
    }

    // Save whiteboard data to Hive (without screenshot)
    try {
      await _whiteboardData.save();
      debugPrint(
          'Whiteboard saved successfully with ID: ${_whiteboardData.id}');
    } catch (saveError) {
      debugPrint('Error saving to Hive: $saveError');

      // Fallback to put
      if (_whiteboardData.isInBox) {
        try {
          await _whiteboardsBox.put(_whiteboardData.key, _whiteboardData);
        } catch (e) {
          debugPrint('All save attempts failed: $e');
        }
      }
    }
  }

  Future<ui.Image> _createPlaceholderImage() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()..color = Colors.grey,
    );
    final picture = recorder.endRecording();
    return await picture.toImage(100, 100);
  }
  // ----------------------------------------------------------
  //     SELECTANJE SLIKE ZA MATHPIX AI
  // ----------------------------------------------------------

  Widget _buildSelectionOverlay() {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (details) {
          setState(() {
            _selectionStart = details.localPosition;
            _selectionEnd = details.localPosition;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _selectionEnd = details.localPosition;
          });
        },
        onPanEnd: (_) async {
          if (_selectionStart != null && _selectionEnd != null) {
            try {
              final image = await _captureSelectedArea();
              if (image != null) {
                setState(() => _capturedImage = image);

                // posalji sliku na mathpix
                final MathpixAiSolving mathpixAiSolving = MathpixAiSolving();
                final result = await mathpixAiSolving.sendImageToMathpix(image);
                if (result != null) {
                  // uredi rezultat za prikaz
                  String sanitized =
                      result.replaceAll(r"\(", r"$$").replaceAll(r"\)", r"$$");

                  setState(() {
                    _latexResult = sanitized;
                  });

                  // OpenAI servis za rjesavanje matematickih izraza
                  setState(() {
                    _isOpenAiLoading = true;
                    _openAiAnswer = null;
                  });

                  final deepSeekService = DeepseekService();
                  final openAiResult =
                      await deepSeekService.solveMathExpression(sanitized);

                  setState(() {
                    _isOpenAiLoading = false;
                  });

                  // idi na stranicu sa objasnjen rjesenjem
                  if (openAiResult != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SolutionStepsPage(
                          steps: openAiResult,
                          originalTask: sanitized,
                        ),
                      ),
                    );
                  }
                }
              }
            } finally {
              setState(() {
                _isSelectingArea = false;
                _selectionStart = null;
                _selectionEnd = null;
              });
            }
          }
        },
        child: CustomPaint(
          painter: SelectionRectanglePainter(
            start: _selectionStart,
            end: _selectionEnd,
          ),
        ),
      ),
    );
  }

  // funkcija za slikanje selektiranog dijela whiteboarda za AI
  Future<Uint8List?> _captureSelectedArea() async {
    final renderObject = _whiteboardKey.currentContext?.findRenderObject();
    if (renderObject == null ||
        _selectionStart == null ||
        _selectionEnd == null) {
      return null;
    }

    try {
      final whiteboardSize = renderObject.paintBounds.size;

      // validiranje koordinata
      final start = Offset(
        _selectionStart!.dx.clamp(0, whiteboardSize.width),
        _selectionStart!.dy.clamp(0, whiteboardSize.height),
      );
      final end = Offset(
        _selectionEnd!.dx.clamp(0, whiteboardSize.width),
        _selectionEnd!.dy.clamp(0, whiteboardSize.height),
      );

      // nesmije bit premal selection
      if ((end.dx - start.dx).abs() < 5 || (end.dy - start.dy).abs() < 5) {
        print('Selection too small: '
            '${(end.dx - start.dx).abs()}x${(end.dy - start.dy).abs()}');
        return null;
      }

      // slikaj
      final image = await (renderObject as RenderRepaintBoundary)
          .toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);

      // dodaj byte validaciju
      if (byteData == null || byteData.lengthInBytes < 100) {
        print('Invalid image data: ${byteData?.lengthInBytes ?? "null"} bytes');
        return null;
      }

      // spremamo raw sliku za debugging
      final rawImage = byteData.buffer.asUint8List();
      debugPrint('Raw image header: ${rawImage.sublist(0, 8)}');

      // dekodiraj sliku i procesiraj
      final img = imglib.decodeImage(rawImage);
      if (img == null) {
        print('Failed to decode RAW image');
        return null;
      }

      final scaledRect = Rect.fromLTRB(
        (start.dx * 2).clamp(0, img.width.toDouble()).toDouble(),
        (start.dy * 2).clamp(0, img.height.toDouble()).toDouble(),
        (end.dx * 2).clamp(0, img.width.toDouble()).toDouble(),
        (end.dy * 2).clamp(0, img.height.toDouble()).toDouble(),
      );

      // provjeri jesu li pravokutne koordinate ispravno poredane
      final clampedRect = Rect.fromLTRB(
        scaledRect.left < scaledRect.right ? scaledRect.left : scaledRect.right,
        scaledRect.top < scaledRect.bottom ? scaledRect.top : scaledRect.bottom,
        scaledRect.left < scaledRect.right ? scaledRect.right : scaledRect.left,
        scaledRect.top < scaledRect.bottom ? scaledRect.bottom : scaledRect.top,
      );

      // update validaciju
      if (clampedRect.width < 1 || clampedRect.height < 1) {
        print(
            'Invalid crop dimensions: ${clampedRect.width}x${clampedRect.height}');
        return null;
      }

      final cropped = imglib.copyCrop(
        img,
        x: clampedRect.left.toInt(),
        y: clampedRect.top.toInt(),
        width: clampedRect.width.toInt(),
        height: clampedRect.height.toInt(),
      );

      return Uint8List.fromList(imglib.encodePng(cropped));
    } catch (e) {
      print('Capture error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ----------------------------------------------------------
          //     WHITEBOARD MAIN GESTURE DETECTOR
          RepaintBoundary(
            key: _whiteboardKey,
            child: Stack(
              children: [
                // Drawing canvas - bottom layer
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  onScaleEnd: _handleScaleEnd,
                  // Modify your canvas GestureDetector's onTapDown handler:

                  onTapDown: (details) {
                    // This only handles whiteboard/canvas related gestures
                    if (_currentTool == ToolMode.text) {
                      // Only create a new text element if we're in text mode
                      // First check if we clicked on an existing element
                      bool clickedOnExistingText = false;
                      bool clickedOnExistingImage = false;

                      // Check if clicked on existing text
                      for (final element in _textElements) {
                        final Offset elementPosition = element.position;
                        final Size elementSize = element.size;

                        final double scale =
                            _transformationMatrix.getMaxScaleOnAxis();
                        final double dx =
                            _transformationMatrix.getTranslation().x;
                        final double dy =
                            _transformationMatrix.getTranslation().y;

                        final Offset transformedPosition = Offset(
                            elementPosition.dx * scale + dx,
                            elementPosition.dy * scale + dy);

                        final Rect elementRect = Rect.fromLTWH(
                            transformedPosition.dx,
                            transformedPosition.dy,
                            elementSize.width * scale,
                            elementSize.height * scale);

                        if (elementRect.contains(details.localPosition)) {
                          clickedOnExistingText = true;
                          setState(() {
                            _selectedTextElement = element;
                          });
                          break;
                        }
                      }

                      // Check if clicked on existing image
                      for (final element in _imageElements) {
                        final Offset elementPosition = element.position;
                        final Size elementSize = element.size;

                        final double scale =
                            _transformationMatrix.getMaxScaleOnAxis();
                        final double dx =
                            _transformationMatrix.getTranslation().x;
                        final double dy =
                            _transformationMatrix.getTranslation().y;

                        final Offset transformedPosition = Offset(
                            elementPosition.dx * scale + dx,
                            elementPosition.dy * scale + dy);

                        final Rect elementRect = Rect.fromLTWH(
                            transformedPosition.dx,
                            transformedPosition.dy,
                            elementSize.width * scale,
                            elementSize.height * scale);

                        if (elementRect.contains(details.localPosition)) {
                          clickedOnExistingImage = true;
                          break;
                        }
                      }

                      if (!clickedOnExistingText && !clickedOnExistingImage) {
                        // If we already have a selected text element but clicked elsewhere,
                        // deselect it and switch to hand tool instead of creating a new one
                        if (_selectedTextElement != null) {
                          setState(() {
                            if (_selectedTextElement!.isEditing) {
                              _selectedTextElement!.isEditing = false;
                            }
                            _selectedTextElement = null;
                            _currentTool = ToolMode.hand; // Switch to hand tool
                            // Dismiss keyboard
                            FocusManager.instance.primaryFocus?.unfocus();
                          });
                        } else {
                          // Only create new text if there wasn't already a text selected
                          // Get current scale (zoom in/out)
                          final double scale =
                              _transformationMatrix.getMaxScaleOnAxis();

                          // Base sizes for text
                          const double baseWidth = 150.0;
                          const double baseHeight = 50.0;
                          const double baseFontSize = 24.0;

                          // Calculate size and position based on current scale
                          final double adjustedWidth = baseWidth / scale;
                          final double adjustedHeight = baseHeight / scale;
                          final double adjustedFontSize = baseFontSize / scale;

                          // Create new text element with scale-determined positions and sizes
                          final newElement = TextElement(
                            id: DateTime.now()
                                .microsecondsSinceEpoch
                                .toString(),
                            position: _transformPoint(details.localPosition),
                            fontSize: adjustedFontSize,
                            size: Size(adjustedWidth, adjustedHeight),
                            isEditing: true,
                          );

                          setState(() {
                            // Deselect any selected image when adding text
                            if (_selectedImageElement != null) {
                              _selectedImageElement = null;
                            }

                            _textElements.add(newElement);
                            _recordAction(UndoableAction(
                              type: ActionType.addText,
                              item: newElement,
                            ));
                            _selectedTextElement = newElement;
                          });
                        }
                      }
                    } else {
                      // For all other tools, check if we're clicking on any elements
                      bool clickedOnExistingText = false;
                      bool clickedOnExistingImage = false;

                      // Check if clicked on existing text
                      for (final element in _textElements) {
                        final Offset elementPosition = element.position;
                        final Size elementSize = element.size;

                        final double scale =
                            _transformationMatrix.getMaxScaleOnAxis();
                        final double dx =
                            _transformationMatrix.getTranslation().x;
                        final double dy =
                            _transformationMatrix.getTranslation().y;

                        final Offset transformedPosition = Offset(
                            elementPosition.dx * scale + dx,
                            elementPosition.dy * scale + dy);

                        final Rect elementRect = Rect.fromLTWH(
                            transformedPosition.dx,
                            transformedPosition.dy,
                            elementSize.width * scale,
                            elementSize.height * scale);

                        if (elementRect.contains(details.localPosition)) {
                          clickedOnExistingText = true;
                          break;
                        }
                      }

                      // Check if clicked on existing image
                      for (final element in _imageElements) {
                        final Offset elementPosition = element.position;
                        final Size elementSize = element.size;

                        final double scale =
                            _transformationMatrix.getMaxScaleOnAxis();
                        final double dx =
                            _transformationMatrix.getTranslation().x;
                        final double dy =
                            _transformationMatrix.getTranslation().y;

                        final Offset transformedPosition = Offset(
                            elementPosition.dx * scale + dx,
                            elementPosition.dy * scale + dy);

                        final Rect elementRect = Rect.fromLTWH(
                            transformedPosition.dx,
                            transformedPosition.dy,
                            elementSize.width * scale,
                            elementSize.height * scale);

                        if (elementRect.contains(details.localPosition)) {
                          clickedOnExistingImage = true;
                          setState(() {
                            // Deselect any selected text
                            if (_selectedTextElement != null) {
                              if (_selectedTextElement!.isEditing) {
                                _selectedTextElement!.isEditing = false;
                              }
                              _selectedTextElement = null;
                            }

                            // Select this image
                            _selectedImageElement = element;
                            _currentTool = ToolMode.image;
                          });
                          break;
                        }
                      }

                      // If we didn't click on any element, deselect and switch to hand tool
                      if (!clickedOnExistingText && !clickedOnExistingImage) {
                        bool selectionChanged = false;

                        if (_selectedTextElement != null) {
                          selectionChanged = true;
                          setState(() {
                            // Check if element is in edit mode
                            if (_selectedTextElement!.isEditing) {
                              _selectedTextElement!.isEditing = false;
                            }
                            _selectedTextElement = null;
                          });
                        }

                        if (_selectedImageElement != null) {
                          selectionChanged = true;
                          setState(() {
                            _selectedImageElement = null;
                            // Set to hand tool when deselecting
                            _currentTool = ToolMode.hand;
                          });
                        }

                        // If the tool isn't specifically a tool that should stay active
                        if (_currentTool == ToolMode.image ||
                            _currentTool == ToolMode.text) {
                          setState(() {
                            _currentTool = ToolMode.hand;
                          });
                        }

                        // Dismiss keyboard
                        FocusManager.instance.primaryFocus?.unfocus();
                      }
                    }
                  },
                  child: CustomPaint(
                    painter: WhiteboardPainter(
                      paths: _paths,
                      transformationMatrix: _transformationMatrix,
                      currentColor: _currentColor,
                      currentPath: _currentPath,
                      strokeWidth: _strokeWidth,
                      shapes: _shapes,
                      currentShape: _currentShape,
                    ),
                    size: Size.infinite,
                  ),
                ),

                // Images layer - middle layer
                ...(_imageElements.map((element) {
                  // Apply transformation matrix
                  final double scale =
                      _transformationMatrix.getMaxScaleOnAxis();
                  final double dx = _transformationMatrix.getTranslation().x;
                  final double dy = _transformationMatrix.getTranslation().y;

                  // Transform the position
                  final Offset transformedPosition = Offset(
                    element.position.dx * scale + dx,
                    element.position.dy * scale + dy,
                  );

                  // Calculate scaled size
                  final Size scaledSize = Size(
                    element.size.width * scale,
                    element.size.height * scale,
                  );

                  return Positioned(
                    left: transformedPosition.dx,
                    top: transformedPosition.dy,
                    child: GestureDetector(
                      behavior:
                          HitTestBehavior.opaque, // Important: Change to opaque
                      onTap: () {
                        // Only select/deselect on tap
                        setState(() {
                          // Deselect any selected text
                          if (_selectedTextElement != null) {
                            if (_selectedTextElement!.isEditing) {
                              _selectedTextElement!.isEditing = false;
                            }
                            _selectedTextElement = null;
                          }

                          // Select/deselect this image
                          if (_selectedImageElement == element) {
                            _selectedImageElement = null;
                            _currentTool = ToolMode.hand;
                          } else {
                            _selectedImageElement = element;
                            _currentTool = ToolMode.image;
                          }
                        });
                      },
                      onLongPress: () {
                        // Set as selected on long press
                        setState(() {
                          // Deselect any selected text
                          if (_selectedTextElement != null) {
                            if (_selectedTextElement!.isEditing) {
                              _selectedTextElement!.isEditing = false;
                            }
                            _selectedTextElement = null;
                          }

                          _selectedImageElement = element;
                          _currentTool = ToolMode.image;
                        });
                      },
                      onPanStart: (details) {
                        if (_selectedImageElement == element) {
                          _lastPanOffset = details.localPosition;
                        }
                      },
                      onPanUpdate: (details) {
                        if (_selectedImageElement == element &&
                            _lastPanOffset != null) {
                          setState(() {
                            // Convert delta to account for scale
                            final Offset delta = details.delta / scale;
                            element.position += delta;
                            _lastPanOffset = details.localPosition;
                          });
                        }
                      },
                      onPanEnd: (details) {
                        _lastPanOffset = null;
                      },
                      child: Stack(
                        clipBehavior:
                            Clip.none, // Important: Allow children to overflow
                        children: [
                          // Main image container with border if selected
                          Container(
                            width: scaledSize.width,
                            height: scaledSize.height,
                            decoration: BoxDecoration(
                              border: (_selectedImageElement == element)
                                  ? Border.all(color: Colors.blue, width: 2)
                                  : null,
                            ),
                            child: Opacity(
                              opacity: element.opacity,
                              child: imageWidget(element.imageUrl, scaledSize),
                            ),
                          ),

                          // Only show these controls when the image is selected
                          if (_selectedImageElement == element) ...[
                            // Resize handle (bottom right)
                            Positioned(
                              right: -15,
                              bottom: -15,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanUpdate: (details) {
                                  setState(() {
                                    double newWidth = element.size.width +
                                        (details.delta.dx / scale);
                                    double newHeight = element.size.height +
                                        (details.delta.dy / scale);

                                    // Limit minimum size
                                    newWidth =
                                        newWidth.clamp(50.0, double.infinity);
                                    newHeight =
                                        newHeight.clamp(50.0, double.infinity);

                                    element.size = Size(newWidth, newHeight);
                                  });
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.open_with,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),

                            // Delete button (top right)
                            Positioned(
                              right: -15,
                              top: -15,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () {
                                  setState(() {
                                    final index =
                                        _imageElements.indexOf(element);
                                    if (index != -1) {
                                      final removedImage =
                                          _imageElements.removeAt(index);
                                      _recordAction(UndoableAction(
                                        type: ActionType.deleteImage,
                                        item: removedImage,
                                        index: index,
                                      ));
                                      _selectedImageElement = null;
                                    }
                                  });
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                })),
                // dodavanje pravog texta ne rukopis
                ..._textElements.map((element) {
                  // spremi originalnu poziciju i velicinu
                  final Offset originalPosition = element.position;
                  final Size originalSize = element.size;

                  // primjeni transformaciju na poziciju i velicinu
                  final double scale =
                      _transformationMatrix.getMaxScaleOnAxis();

                  // izracunaj translaciju iz matrice (znaci koliko smo se micali po ekranu)
                  // prvo dobij trenutni scale i translaciju
                  final double dx = _transformationMatrix.getTranslation().x;
                  final double dy = _transformationMatrix.getTranslation().y;

                  // pravilna promjena transformacije - skaliranje polozaja i dodavanje prijevoda
                  final Offset transformedPosition = Offset(
                      originalPosition.dx * scale + dx,
                      originalPosition.dy * scale + dy);

                  // izracunaj velicinu i font size
                  final double scaledFontSize = element.fontSize * scale;
                  final Size scaledSize = Size(
                      originalSize.width * scale, originalSize.height * scale);

                  return Positioned(
                    left: transformedPosition.dx,
                    top: transformedPosition.dy,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        setState(() {
                          _selectedTextElement = element;
                          _currentTool = ToolMode.text;
                        });
                      },
                      onLongPress: () {
                        setState(() {
                          _selectedTextElement = element;
                          _currentTool = ToolMode.text;
                        });
                      },
                      onPanStart: (details) {
                        // dozvoli pomicanje samo ako je text element selektiran
                        if (_selectedTextElement == element) {
                          _lastPanOffset = details.localPosition;
                        }
                      },
                      onPanUpdate: (details) {
                        // dozvoli pomicanje samo ako je text element selektiran i ako znamo zadnji offset
                        if (_selectedTextElement == element &&
                            _lastPanOffset != null) {
                          setState(() {
                            // pretvori delta u odnosu na scale faktor
                            final Offset delta = details.delta / scale;

                            // azuriraj poziciju elementa
                            element.position += delta;

                            // azuriraj zadnji pan offset
                            _lastPanOffset = details.localPosition;
                          });
                        }
                      },
                      onPanEnd: (details) {
                        // resetiraj zadnji pan offset
                        _lastPanOffset = null;
                      },
                      child: Container(
                        width: scaledSize.width,
                        height: scaledSize.height,
                        decoration: BoxDecoration(
                          border: (_selectedTextElement == element)
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // editanje texta
                            if (element.isEditing)
                              TextField(
                                autofocus: true,
                                style: TextStyle(
                                  fontSize: scaledFontSize,
                                  color: Colors.black,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                                onChanged: (value) => element.text = value,
                                onSubmitted: (value) {
                                  setState(() {
                                    element.isEditing = false;
                                    // makni tipkovnicu
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                  });
                                },
                              )
                            else
                              Text(
                                element.text,
                                style: TextStyle(
                                  fontSize: scaledFontSize,
                                  color: Colors.black,
                                ),
                              ),

                            if (_selectedTextElement == element)
                              Positioned(
                                right: -10,
                                top: -10,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    setState(() {
                                      final index =
                                          _textElements.indexOf(element);
                                      if (index != -1) {
                                        final removedText =
                                            _textElements.removeAt(index);
                                        _recordAction(UndoableAction(
                                          type: ActionType.deleteText,
                                          item: removedText,
                                          index: index,
                                        ));
                                        _selectedTextElement = null;
                                        _currentTool = ToolMode.hand;
                                      }
                                    });
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),

                            // rucka za resizanje
                            if (_selectedTextElement == element)
                              Positioned(
                                right: -10,
                                bottom: -10,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanUpdate: (details) {
                                    setState(() {
                                      // primjena faktora razmjera za promjenu veličine delte
                                      double newWidth = element.size.width +
                                          (details.delta.dx / scale) * 0.5;
                                      double newHeight = element.size.height +
                                          (details.delta.dy / scale) * 0.5;

                                      // ograniči veličinu da nije premala i ode u minus
                                      newWidth = max(50, newWidth);
                                      newHeight = max(30, newHeight);

                                      element.size = Size(newWidth, newHeight);
                                      // proporcionalno promijeni font size
                                      element.fontSize = newHeight * 0.5;
                                    });
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.open_with,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          // return gumb
          Positioned(
            top: 25,
            left: 35,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              iconSize: 50,
              color: const Color.fromRGBO(236, 145, 32, 1),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // prikazivanje color chooinsg widget
          if (_showColorOptions)
            Positioned(
              right: 166,
              top: MediaQuery.of(context).size.height / 2 - 30,
              child: Container(
                margin: const EdgeInsets.only(right: 25),
                decoration: _panelDecoration,
                padding:
                    const EdgeInsets.symmetric(horizontal: 2, vertical: 16),
                child: Column(
                  children: [
                    // slider za debljinu linije
                    SizedBox(
                      width: 190,
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                              activeTrackColor: const Color(0xFF717171),
                              inactiveTrackColor: const Color(0xFFEAEAEA),
                              thumbColor: const Color(0xFF717171),
                            ),
                            child: Slider(
                              value: _strokeWidth,
                              min: 1,
                              max: 30,
                              onChanged: (value) => setState(() {
                                _toolSettings[_drawingMode]!.strokeWidth =
                                    value;
                                _strokeWidth = value;
                              }),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Padding(
                            padding: const EdgeInsets.only(left: 22),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _showShapeOptions ? 'Ispunjenost' : 'Debljina',
                                style: GoogleFonts.inter(
                                  color: Colors.grey[700],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Color Grid
                    if (_drawingMode != DrawingMode.eraser)
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                          itemCount: _colorPalette.length,
                          itemBuilder: (context, index) {
                            final colorData = _colorPalette[index];
                            return GestureDetector(
                              onTap: () => setState(() {
                                if (_drawingMode == DrawingMode.marker) {
                                  // transparentno za marker mode
                                  _toolSettings[_drawingMode]!.color =
                                      colorData['color']!.withOpacity(0.5);
                                  _currentColor =
                                      colorData['color']!.withOpacity(0.5);
                                } else {
                                  _toolSettings[_drawingMode]!.color =
                                      colorData['color']!;
                                  _currentColor = colorData['color']!;
                                }
                              }),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: colorData['color'],
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorData['border']!,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  if (_currentColor == colorData['color'])
                                    SvgPicture.string(
                                      '<svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg"><path fill-rule="evenodd" clip-rule="evenodd" d="M11.4669 3.72684C11.7558 3.91574 11.8369 4.30308 11.648 4.59198L7.39799 11.092C7.29783 11.2452 7.13556 11.3467 6.95402 11.3699C6.77247 11.3931 6.58989 11.3355 6.45446 11.2124L3.70446 8.71241C3.44905 8.48022 3.43023 8.08494 3.66242 7.82953C3.89461 7.57412 4.28989 7.55529 4.5453 7.78749L6.75292 9.79441L10.6018 3.90792C10.7907 3.61902 11.178 3.53795 11.4669 3.72684Z" fill="white"/></svg>',
                                      width: 30,
                                      height: 30,
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

          //prikazivanje widgeta za biranje vrstu oblika (krug, kvadrat, trokut, heksagon)
          if (_showShapeOptions)
            Positioned(
              right: 100,
              top: MediaQuery.of(context).size.height / 2 - 150,
              child: Container(
                decoration: _panelDecoration,
                child: Column(
                  children: [
                    // Circle oblik
                    ToolButton(
                      isActive: _currentShapeType == ShapeType.circle,
                      onPressed: () {
                        setState(() {
                          _currentShapeType = ShapeType.circle;
                        });
                      },
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _currentShapeType == ShapeType.circle
                                ? Colors.blue
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // Square oblik
                    ToolButton(
                      isActive: _currentShapeType == ShapeType.square,
                      onPressed: () {
                        setState(() {
                          _currentShapeType = ShapeType.square;
                        });
                      },
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _currentShapeType == ShapeType.square
                                ? Colors.blue
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    // Triangle oblik
                    ToolButton(
                      isActive: _currentShapeType == ShapeType.triangle,
                      onPressed: () {
                        setState(() {
                          _currentShapeType = ShapeType.triangle;
                        });
                      },
                      child: CustomPaint(
                        size: const Size(35, 35),
                        painter: TrianglePainter(
                          color: _currentShapeType == ShapeType.triangle
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ),
                    // Hexagon oblik
                    ToolButton(
                      isActive: _currentShapeType == ShapeType.hexagon,
                      onPressed: () {
                        setState(() {
                          _currentShapeType = ShapeType.hexagon;
                        });
                      },
                      child: CustomPaint(
                        size: const Size(35, 35),
                        painter: HexagonPainter(
                          color: _currentShapeType == ShapeType.hexagon
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ),
                    // Color/width indikator
                    ToolButton(
                      child: ColorWidthIndicator(
                          color: _currentColor, strokeWidth: _strokeWidth),
                      onPressed: () => setState(
                          () => _showColorOptions = !_showColorOptions),
                    ),
                  ],
                ),
              ),
            ),

          // prikazivanje widgeta za biranje vrstu olovke (marker, gumica, normalna olovka)
          if (_showPenOptions)
            Positioned(
              right: 100,
              top: MediaQuery.of(context).size.height / 2 - 150,
              child: Container(
                decoration: _panelDecoration,
                child: Column(
                  children: [
                    ToolButton(
                      isActive: _drawingMode == DrawingMode.pen,
                      onPressed: () {
                        setState(() {
                          _drawingMode = DrawingMode.pen;
                          _currentColor = _toolSettings[_drawingMode]!.color;
                          _strokeWidth =
                              _toolSettings[_drawingMode]!.strokeWidth;
                          _showColorOptions = false;
                        });
                      },
                      child: Image.asset(
                        _drawingMode == DrawingMode.pen
                            ? 'assets/icons/notes_pen_selected.png'
                            : 'assets/icons/notes_pen.png',
                        width: 35,
                        height: 35,
                      ),
                    ),
                    ToolButton(
                      isActive: _drawingMode == DrawingMode.marker,
                      onPressed: () {
                        setState(() {
                          _drawingMode = DrawingMode.marker;
                          _currentColor = _toolSettings[_drawingMode]!
                              .color
                              .withOpacity(0.5); // transparentno za marker
                          _strokeWidth =
                              _toolSettings[_drawingMode]!.strokeWidth;
                          _showColorOptions = false;
                        });
                      },
                      child: Image.asset(
                        _drawingMode == DrawingMode.marker
                            ? 'assets/icons/notes_marker_selected.png'
                            : 'assets/icons/notes_marker.png',
                        width: 35,
                        height: 35,
                      ),
                    ),
                    ToolButton(
                      isActive: _drawingMode == DrawingMode.eraser,
                      onPressed: () {
                        setState(() {
                          _drawingMode = DrawingMode.eraser;
                          _currentColor = _toolSettings[_drawingMode]!.color;
                          _strokeWidth =
                              _toolSettings[_drawingMode]!.strokeWidth;
                          _showColorOptions = false;
                        });
                      },
                      child: Image.asset(
                        _drawingMode == DrawingMode.eraser
                            ? 'assets/icons/notes_eraser_selected.png'
                            : 'assets/icons/notes_eraser.png',
                        width: 35,
                        height: 35,
                      ),
                    ),
                    ToolButton(
                      child: ColorWidthIndicator(
                          color: _currentColor, strokeWidth: _strokeWidth),
                      onPressed: () => setState(
                          () => _showColorOptions = !_showColorOptions),
                    ),
                  ],
                ),
              ),
            ),

          // upload gumb
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height / 2 - 260,
            child: Container(
              decoration: _panelDecoration,
              child: ToolButton(
                onPressed: () {
                  _changeTool(ToolMode.hand);
                  setState(() {
                    _showPenOptions = false;
                    _showColorOptions = false;
                  });
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UploadFilesPages(
                        onImageSelected: _addImageToWhiteboard,
                      ),
                    ),
                  );
                },
                child: Image.asset(
                  'assets/icons/notes_upload.png',
                  width: 35,
                  height: 35,
                ),
              ),
            ),
          ),

          // glavni panel za biranje alata
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height / 2 - 190,
            child: Column(
              children: [
                Container(
                  decoration: _panelDecoration,
                  child: Column(
                    children: [
                      ToolButton(
                        isActive: _currentTool == ToolMode.hand,
                        onPressed: () {
                          _changeTool(ToolMode.hand);
                          setState(() {
                            _showPenOptions = false;
                            _showShapeOptions = false;
                            _showColorOptions = false;
                          });
                        },
                        child: Icon(Icons.pan_tool,
                            color: _currentTool == ToolMode.hand
                                ? const Color.fromRGBO(23, 148, 210, 1)
                                : Colors.black),
                      ),
                      ToolButton(
                        isActive: _currentTool == ToolMode.pen,
                        onPressed: () {
                          _changeTool(ToolMode.pen);
                          setState(() {
                            _showPenOptions = !_showPenOptions;
                            _showShapeOptions = false;
                            _showColorOptions = false;
                          });
                        },
                        child: Image.asset(
                          _currentTool == ToolMode.pen
                              ? 'assets/icons/notes_pen_selected.png'
                              : 'assets/icons/notes_pen.png',
                          width: 35,
                          height: 35,
                        ),
                      ),
                      ToolButton(
                        isActive: _currentTool == ToolMode.text,
                        onPressed: () {
                          _changeTool(ToolMode.text);
                          setState(() {
                            _showPenOptions = false;
                            _showColorOptions = false;
                            _showShapeOptions = false;
                          });
                        },
                        child: Image.asset(
                          _currentTool == ToolMode.text
                              ? 'assets/icons/notes_text.png'
                              : 'assets/icons/notes_text.png',
                          width: 35,
                          height: 35,
                        ),
                      ),
                      ToolButton(
                        isActive: _currentTool == ToolMode.shape,
                        child: Image.asset(
                          _currentTool == ToolMode.shape
                              ? 'assets/icons/notes_shapes_selected.png'
                              : 'assets/icons/notes_shapes.png',
                          width: 35,
                          height: 35,
                        ),
                        onPressed: () {
                          setState(() {
                            _currentTool = ToolMode.shape;
                            _showPenOptions = false;
                            _showShapeOptions = !_showShapeOptions;
                            _showColorOptions = false;
                          });
                        },
                      ),
                      ToolButton(
                        isActive: _currentTool == ToolMode.ai,
                        child: SvgPicture.asset(
                          _currentTool == ToolMode.ai
                              ? 'assets/icons/screen_sidebar_ai_selected.svg'
                              : 'assets/icons/screen_sidebar_ai.svg',
                          width: 35,
                          height: 35,
                        ),
                        onPressed: () {
                          _changeTool(ToolMode.ai);
                          setState(() {
                            _isSelectingArea = true;
                            // zatvori sve ostale panele
                            _showShapeOptions = false;
                            _currentTool = ToolMode.ai;
                            _showPenOptions = false;
                            _showColorOptions = false;
                          });
                        },
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Undo/Redo gumbi
                Container(
                  decoration: _panelDecoration,
                  child: Column(
                    children: [
                      ToolButton(
                        onPressed: _undo,
                        child: Image.asset(
                          'assets/icons/notes_undo.png',
                          width: 35,
                          height: 35,
                        ),
                      ),
                      ToolButton(
                          onPressed: _redo,
                          child: Image.asset(
                            'assets/icons/notes_redo.png',
                            width: 35,
                            height: 35,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // AI selekcija i panel za prikazivanje uputa
          if (_isSelectingArea) _buildSelectionOverlay(),
          if (_isSelectingArea)
            Positioned(
              top: 50.0,
              left: MediaQuery.of(context).size.width * 0.25,
              right: MediaQuery.of(context).size.width * 0.25,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  'Odaberite mali prozorčić gdje naš AI može brzo i točno izračunati što trebate.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ),

          // panel za prikazivanje latex rezultata (rezultata AI)
          if (_isOpenAiLoading)
            Positioned(
              bottom: 0,
              left: MediaQuery.of(context).size.width / 2 - 300,
              child: Container(
                width: 600,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // prikazi latex rezultat iz mathpixa (ako je pronaden)
                    Align(
                      alignment: Alignment.topLeft,
                      child: LaTexT(
                        laTeXCode: Text(
                          _latexResult!,
                          textAlign: TextAlign.left,
                          style: GoogleFonts.inter(fontSize: 40),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // prikazi loading spinner dok se ceka na odgovor od OpenAI
                    if (_isOpenAiLoading) ...[
                      Image.asset(
                        'assets/animations/spinning_circle.gif',
                        width: 100,
                        height: 100,
                      ),
                    ],

                    // ako postoji prikazi rjesenje od OpenAI
                    if (!_isOpenAiLoading && _openAiAnswer != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _openAiAnswer.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Bottom panel za zoomiranje
          Positioned(
            left: 30,
            bottom: 30,
            child: Container(
              decoration: _panelDecoration,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _zoomOut,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${(_currentScale * 100).toStringAsFixed(0)}%',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _zoomIn,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  //     SCALE HANDLERS (Handle pinch, pan, and drawing)
  // ----------------------------------------------------------

  // funkcija za pocetak skaliranja
  void _handleScaleStart(ScaleStartDetails details) {
    if (_selectedTextElement != null) return;

    _lastScale = _currentScale;
    _initialTransformationMatrix = Matrix4.copy(_transformationMatrix);
    _initialGestureFocalPoint = details.localFocalPoint;

    if (_currentTool == ToolMode.hand) {
      _lastPanOffset = details.focalPoint;
    } else if (_currentTool == ToolMode.pen) {
      final transformedPoint = _transformPoint(details.focalPoint);
      _currentCommands = [];
      _currentPath = Path();
      _currentPath!.moveTo(transformedPoint.dx, transformedPoint.dy);
      _currentCommands!.add({
        'type': 'moveTo',
        'x': transformedPoint.dx,
        'y': transformedPoint.dy,
      });
    }
    if (_currentTool == ToolMode.shape) {
      final transformedPoint = _transformPoint(details.focalPoint);
      _currentShape = ShapeShape(
        type: _currentShapeType,
        startPoint: transformedPoint,
        endPoint: transformedPoint, // oboje na istoj poziciji
        color: _currentColor,
        strokeWidth: _strokeWidth,
      );
    }
  }

  // funkcija za azuriranje skaliranje
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale != 1.0) {
      // zoom skaliranje
      final newScale = _lastScale * details.scale;
      final clampedScale = newScale.clamp(_minScale, _maxScale);

      final inverseInitialMatrix =
          Matrix4.inverted(_initialTransformationMatrix);
      final transformedFocal = MatrixUtils.transformPoint(
        inverseInitialMatrix,
        _initialGestureFocalPoint,
      );

      final scaleDelta = clampedScale / _lastScale;

      _transformationMatrix = Matrix4.copy(_initialTransformationMatrix)
        ..translate(transformedFocal.dx, transformedFocal.dy)
        ..scale(scaleDelta)
        ..translate(-transformedFocal.dx, -transformedFocal.dy);

      _currentScale = clampedScale;
      setState(() {});
      _autoSave();
    } else if (_currentTool == ToolMode.hand) {
      // pomicanje whiteboarda
      final delta = details.focalPointDelta;
      _transformationMatrix.translate(
        delta.dx / _currentScale,
        delta.dy / _currentScale,
      );
      setState(() {});
      _autoSave();
    } else if (_currentTool == ToolMode.pen) {
      final transformedPoint = _transformPoint(details.focalPoint);
      _currentPath!.lineTo(transformedPoint.dx, transformedPoint.dy);
      _currentCommands!.add({
        'type': 'lineTo',
        'x': transformedPoint.dx,
        'y': transformedPoint.dy,
      });
      setState(() {});
      _autoSave();
    }
    if (_currentTool == ToolMode.shape && _currentShape != null) {
      final transformedPoint = _transformPoint(details.focalPoint);
      setState(() {
        _currentShape!.endPoint = transformedPoint;
      });
    }
  }

  // funkcija za zavrsetak skaliranja

  void _handleScaleEnd(ScaleEndDetails details) {
    _lastPanOffset = null;
    if (_currentCommands != null && _currentPath != null) {
      final path = DrawingPath(
        commands: _currentCommands!,
        color: _currentColor,
        strokeWidth: _strokeWidth,
        drawingMode: _drawingMode,
      );

      // dodaj path direktno i zabiljezi akciju
      _paths.add(path);
      _recordAction(UndoableAction(
        type: ActionType.addPath,
        item: path,
      ));

      _currentCommands = null;
      _currentPath = null;
    }

    if (_currentShape != null) {
      setState(() {
        // dodaj oblik direktno i zabiljezi akciju
        _shapes.add(_currentShape!);
        _recordAction(UndoableAction(
          type: ActionType.addShape,
          item: _currentShape!,
        ));

        _currentShape = null;
      });
    }
  }

  // ----------------------------------------------------------
  //     Utility Methods
  // ----------------------------------------------------------
  Offset _transformPoint(Offset screenOffset) {
    final inverseMatrix = Matrix4.inverted(_transformationMatrix);
    final transformed = inverseMatrix
        .transform3(vm.Vector3(screenOffset.dx, screenOffset.dy, 0));
    return Offset(transformed.x, transformed.y);
  }

  // funkcija za azuriranje skale
  void _updateScale(double newScale, {Offset? focalPoint}) {
    final clampedScale = newScale.clamp(_minScale, _maxScale);
    if (focalPoint != null) {
      final deltaScale = clampedScale / _currentScale;
      _transformationMatrix.translate(focalPoint.dx, focalPoint.dy);
      _transformationMatrix.scale(deltaScale);
      _transformationMatrix.translate(-focalPoint.dx, -focalPoint.dy);
    } else {
      _transformationMatrix.setIdentity();
      _transformationMatrix.scale(clampedScale);
    }

    setState(() {
      _currentScale = clampedScale;
    });
    _autoSave();
  }

  // funkcija za zumiranje whiteboarda
  void _zoomIn() => _updateScale(
        _currentScale * 1.1,
        focalPoint: Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
        ),
      );

  // funkcija za odzumiranje whiteboarda
  void _zoomOut() => _updateScale(
        _currentScale * 0.9,
        focalPoint: Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
        ),
      );

  // funkcija za mijenjanje alata
  void _changeTool(ToolMode mode) {
    setState(() {
      _currentTool = mode;
      if (mode != ToolMode.text) {
        _selectedTextElement = null;
        _showPenOptions = false;
        _showColorOptions = false;
        // makni tipkovnicu ako nije text tool
        FocusManager.instance.primaryFocus?.unfocus();
      }
      if (mode == ToolMode.hand) {
        _showPenOptions = false;
        _showColorOptions = false;
      }
      for (var element in _textElements) {
        element.isEditing = false;
      }
    });
  }

  void _recordAction(UndoableAction action) {
    _undoStack.add(action);
    // izbrisi redo stack kad se nesto novo doda
    _redoStack.clear();
    _autoSave();
  }

  T _getTypedItem<T>(dynamic item) {
    if (item is T) {
      return item;
    }
    throw Exception(
        'Invalid item type: expected $T but got ${item.runtimeType}');
  }

  // undo funkcija
  void _undo() {
    if (_undoStack.isEmpty) return;

    final action = _undoStack.removeLast();
    _redoStack.add(action);

    setState(() {
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
    });

    _autoSave();
  }

  // redo funkcija
  void _redo() {
    if (_redoStack.isEmpty) return;

    final action = _redoStack.removeLast();
    _undoStack.add(action);

    setState(() {
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
      }
    });

    _autoSave();
  }

  // ----------------------------------------------------------
  //     Dekoracije i widgeti
  // ----------------------------------------------------------
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

enum ToolMode { hand, pen, text, shape, ai, image }

enum DrawingTool { pen, marker, eraser }

enum ShapeType { circle, square, triangle, hexagon }
