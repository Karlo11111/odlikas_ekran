// ignore_for_file: prefer_final_fields, unused_field, depend_on_referenced_packages, library_private_types_in_public_api, deprecated_member_use, avoid_print

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:latext/latext.dart';
import 'package:odlikas_ekran/database/api/matpix_ai_solving.dart';
import 'package:odlikas_ekran/database/api/open_ai_service.dart';
import 'package:odlikas_ekran/pages/MathNotes/Shapes/shape_shape.dart';
import 'package:odlikas_ekran/pages/MathNotes/Shapes/shape_painters.dart';
import 'package:odlikas_ekran/pages/MathNotes/TextAdding/text_model.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/debouncer.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/whiteboard_data.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/color_width_indicator.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/drawing_path.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/select_rectangle_mathpix.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/tool.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/white_board_painter.dart';
import 'package:odlikas_ekran/pages/SolutionStepsPage/solution_steps_page.dart';
import 'package:vector_math/vector_math_64.dart' as vm;
import 'package:google_fonts/google_fonts.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as imglib;
import 'dart:ui' as ui;

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

  final List<dynamic> _redoStack = [];

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
    _saveDebounce.cancel(); // Cancel pending debounced saves
    _saveNow(); // Save immediately on exit
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

// Helper function for deep conversion
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

  Future<void> _autoSave({bool force = false}) async {
    if (force) {
      await _saveNow(); // Save immediately without debounce
    } else {
      _saveDebounce.run(() => _saveNow());
    }
  }

  Future<void> _saveNow() async {
    try {
      // Don't create a whole new object, instead update the existing one
      // This preserves the Hive key/reference
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

      // Safely capture new screenshot
      if (_whiteboardKey.currentContext != null &&
          _whiteboardKey.currentContext!.findRenderObject() != null &&
          _whiteboardKey.currentContext!.findRenderObject()
              is RenderRepaintBoundary) {
        final boundary = _whiteboardKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;

        // Wait for stable frame
        await SchedulerBinding.instance.endOfFrame;
        if (boundary.debugNeedsPaint) {
          await Future.delayed(const Duration(milliseconds: 50));
        }

        try {
          final uiImage = await boundary.toImage(pixelRatio: 2.5);
          final byteData =
              await uiImage.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            _whiteboardData.screenshot = byteData.buffer.asUint8List();
          }
        } catch (screenshotError) {
          debugPrint('Screenshot capture error: $screenshotError');
        }
      }

      // Save the modified existing object
      await _whiteboardData.save();
    } catch (e, stack) {
      debugPrint('Save error: $e\n$stack');
    }
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

                // Send image to Mathpix AI
                final MathpixAiSolving mathpixAiSolving = MathpixAiSolving();
                final result = await mathpixAiSolving.sendImageToMathpix(image);
                if (result != null) {
                  // Sanitize the LaTeX result
                  String sanitized =
                      result.replaceAll(r"\(", r"$$").replaceAll(r"\)", r"$$");

                  setState(() {
                    _latexResult = sanitized;
                  });

                  // OpenAI service for solving math expressions
                  setState(() {
                    _isOpenAiLoading = true;
                    _openAiAnswer = null;
                  });

                  final openAiService = OpenAiService();
                  final openAiResult =
                      await openAiService.solveMathExpression(sanitized);

                  setState(() {
                    _isOpenAiLoading = false;
                  });

                  // Navigate to Solution Steps Page
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
          // ----------------------------------------------------------
          RepaintBoundary(
            key: _whiteboardKey,
            // stack da kada se uzme screenshot za whiteboard preview da se vide tekst i oblici
            child: Stack(
              children: [
                GestureDetector(
                  onScaleStart: _handleScaleStart,
                  onScaleUpdate: _handleScaleUpdate,
                  onScaleEnd: _handleScaleEnd,
                  onTapDown: (details) {
                    if (_currentTool == ToolMode.text) {
                      final newElement = TextElement(
                        id: DateTime.now().microsecondsSinceEpoch.toString(),
                        position: _transformPoint(details.localPosition),
                        fontSize: 24, // Store base font size (not scaled)
                        size: Size(150, 50), // Store base size (not scaled)
                        isEditing: true,
                      );
                      setState(() {
                        _textElements.add(newElement);
                        _selectedTextElement = newElement;
                      });
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
                // dodavanje pravog texta ne rukopis
                ..._textElements.map((element) {
                  // 1) In board space, the rectangle corners:
                  //    top-left = element.position
                  //    bottom-right = element.position + element.size
                  final Offset boardTopLeft = element.position;
                  final Offset boardBottomRight = element.position +
                      Offset(element.size.width, element.size.height);

                  // 2) Convert both corners to screen space:
                  final Offset screenTopLeft = _applyMatrix(boardTopLeft);
                  final Offset screenBottomRight =
                      _applyMatrix(boardBottomRight);

                  // 3) The resulting bounding box in screen space:
                  double boxLeft = screenTopLeft.dx;
                  double boxTop = screenTopLeft.dy;
                  double boxRight = screenBottomRight.dx;
                  double boxBottom = screenBottomRight.dy;

                  // If your transform can flip coordinates (e.g. negative scaling),
                  // ensure left < right and top < bottom by sorting:
                  if (boxRight < boxLeft) {
                    final temp = boxLeft;
                    boxLeft = boxRight;
                    boxRight = temp;
                  }
                  if (boxBottom < boxTop) {
                    final temp = boxTop;
                    boxTop = boxBottom;
                    boxBottom = temp;
                  }

                  final double boxWidth = boxRight - boxLeft;
                  final double boxHeight = boxBottom - boxTop;

                  // 4) Derive a scale factor for the font:
                  //    - For simplicity, scale by ratio of screenHeight to boardHeight.
                  //    - If there's no rotation or severe distortion, this is fine.
                  //    - If you do rotate the board, you'd need more advanced handling.
                  double boardHeight = element.size.height;
                  double fontScale =
                      (boardHeight == 0) ? 1 : (boxHeight / boardHeight);
                  if (fontScale.isNaN || fontScale.isInfinite) {
                    fontScale = 1; // fallback if something weird
                  }
                  final double finalFontSize = element.fontSize * fontScale;

                  return Positioned(
                    left: boxLeft,
                    top: boxTop,
                    // Use the scaled size in screen coordinates
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,

                      // Select text if user long-presses
                      onLongPress: () {
                        setState(() {
                          _selectedTextElement = element;
                          _currentTool = ToolMode.text;
                        });
                      },

                      // Fixed: Drag the text in board space considering transformations
                      onPanUpdate: (details) {
                        setState(() {
                          // Get the inverse of the transformation matrix
                          final inverseMatrix =
                              Matrix4.inverted(_transformationMatrix);

                          // Convert the delta to board space
                          final deltaVec = inverseMatrix.transform3(
                            vm.Vector3(details.delta.dx, details.delta.dy, 0),
                          );

                          // Update position with the proper transformation
                          element.position += Offset(deltaVec.x, deltaVec.y);
                        });
                      },

                      child: Container(
                        width: boxWidth,
                        height: boxHeight,
                        decoration: BoxDecoration(
                          border: (_selectedTextElement == element)
                              ? Border.all(color: Colors.blue, width: 1)
                              : null,
                        ),
                        child: Stack(
                          children: [
                            // Editing vs. displayed text
                            if (element.isEditing)
                              TextField(
                                autofocus: true,
                                style: TextStyle(fontSize: finalFontSize),
                                onChanged: (value) => element.text = value,
                                onSubmitted: (value) {
                                  setState(() => element.isEditing = false);
                                },
                              )
                            else
                              Text(
                                element.text,
                                style: TextStyle(fontSize: finalFontSize),
                              ),

                            // Resize handle if this is the selected text
                            if (_selectedTextElement == element)
                              Positioned(
                                right:
                                    -10, // handle sits partly outside to appear as a corner
                                bottom: -10,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onPanUpdate: (details) {
                                    setState(() {
                                      final inverseMatrix = Matrix4.inverted(
                                          _transformationMatrix);

                                      // Convert the delta to board space
                                      final deltaVec = inverseMatrix.transform3(
                                        vm.Vector3(details.delta.dx,
                                            details.delta.dy, 0),
                                      );

                                      // Apply a damping factor to make scaling less sensitive
                                      double dampingFactor = 0.5;

                                      // Update size with damping
                                      double newW = element.size.width +
                                          (deltaVec.x * dampingFactor);
                                      double newH = element.size.height +
                                          (deltaVec.y * dampingFactor);

                                      // Clamp to avoid going negative
                                      if (newW < 20) newW = 20;
                                      if (newH < 20) newH = 20;

                                      element.size = Size(newW, newH);
                                      element.fontSize =
                                          newH * 0.6; // 60% of height
                                    });
                                  },
                                  child: Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white),
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
          // return botun
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
                                'Debljina',
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
                    // Circle shape
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
                    // Square shape
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
                    // Triangle shape
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
                    // Hexagon shape
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
                    // Color/width indicator
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

          //prikazivanje widgeta za biranje vrstu olovke (marker, gumica, normalna olovka)
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
                              .withOpacity(0.5); // transparentno
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
                  _changeTool(ToolMode.pen);
                  setState(() {
                    _showPenOptions = !_showPenOptions;
                    _showColorOptions = false;
                  });
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
                            // Disable other tools while selecting
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
                // Undo/Redo buttons
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

          //AI selekcija i panel za prikazivanje uputa
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
                    // Display the LaTeX result from Mathpix
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

                    // Display the spinner if we are still loading the OpenAI answer
                    if (_isOpenAiLoading) ...[
                      Image.asset(
                        'assets/animations/spinning_circle.gif',
                        width: 100,
                        height: 100,
                      ),
                    ],

                    // Otherwise, display the OpenAI answer (if any)
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
        endPoint: transformedPoint, // Initialize both points to same position
        color: _currentColor,
        strokeWidth: _strokeWidth,
      );
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale != 1.0) {
      // Handle zoom scaling
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
      // Handle panning
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

  void _handleScaleEnd(ScaleEndDetails details) {
    _lastPanOffset = null;
    if (_currentCommands != null && _currentPath != null) {
      _paths.add(
        DrawingPath(
          commands: _currentCommands!,
          color: _currentColor,
          strokeWidth: _strokeWidth,
          drawingMode: _drawingMode,
        ),
      );
      _currentCommands = null;
      _currentPath = null;
      _autoSave();
    }
    if (_currentShape != null) {
      setState(() {
        _shapes.add(_currentShape!);
        _currentShape = null;
      });
      _autoSave();
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

  Offset _applyMatrix(Offset whiteboardOffset) {
    final transformed = _transformationMatrix
        .transform3(vm.Vector3(whiteboardOffset.dx, whiteboardOffset.dy, 0));
    return Offset(transformed.x, transformed.y);
  }

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

  void _zoomIn() => _updateScale(
        _currentScale * 1.1,
        focalPoint: Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
        ),
      );

  void _zoomOut() => _updateScale(
        _currentScale * 0.9,
        focalPoint: Offset(
          MediaQuery.of(context).size.width / 2,
          MediaQuery.of(context).size.height / 2,
        ),
      );

  void _changeTool(ToolMode mode) {
    setState(() {
      _currentTool = mode;
      if (mode != ToolMode.text) {
        _selectedTextElement = null;
        _showPenOptions = false;
        _showColorOptions = false;
      }
      if (mode == ToolMode.hand) {
        _showPenOptions = false;
        _showColorOptions = false;
      }
      // Clear any text editing states
      for (var element in _textElements) {
        element.isEditing = false;
      }
    });
  }

  void _undo() {
    // First try undoing paths
    if (_paths.isNotEmpty) {
      setState(() {
        _redoStack.add(_paths.removeLast());
      });
      _autoSave();
    }
    // If no paths left, try undoing shapes
    else if (_shapes.isNotEmpty) {
      setState(() {
        _redoStack.add(_shapes.removeLast());
      });
      _autoSave();
    } else if (_textElements.isNotEmpty) {
      setState(() {
        _redoStack.add(_textElements.removeLast());
      });
      _autoSave();
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        final item = _redoStack.removeLast();
        if (item is DrawingPath) {
          _paths.add(item);
        } else if (item is ShapeShape) {
          _shapes.add(item);
        }
      });
      _autoSave();
    }
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

enum ToolMode { hand, pen, text, shape, ai }

enum DrawingTool { pen, marker, eraser }

enum ShapeType { circle, square, triangle, hexagon }
