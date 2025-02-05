// ignore_for_file: prefer_final_fields, unused_field, depend_on_referenced_packages, library_private_types_in_public_api, deprecated_member_use, avoid_print

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hive/hive.dart';
import 'package:latext/latext.dart';
import 'package:odlikas_ekran/database/api/matpix_ai_solving.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/debouncer.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/whiteboard_data.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/color_width_indicator.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/drawing_path.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/select_rectangle_mathpix.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/tool.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/white_board_painter.dart';
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

  final List<DrawingPath> _redoStack = [];

  bool _showPenOptions = false;
  bool _showColorOptions = false;

  // AI image selector varijable
  bool _isSelectingArea = false;
  Offset? _selectionStart;
  Offset? _selectionEnd;
  GlobalKey _whiteboardKey = GlobalKey();

  Uint8List? _capturedImage;
  String? _latexResult;

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
  }

  void _loadSavedState() {
    _paths =
        _whiteboardData.paths.map((path) => DrawingPath.fromMap(path)).toList();

    _transformationMatrix = Matrix4.fromList(
      _whiteboardData.transformationMatrix,
    );
    _currentScale = _whiteboardData.currentScale;
  }

  Future<void> _autoSave() async {
    _saveDebounce.run(() async {
      try {
        // 1) prvo sejvamo sve podatke o whiteboardu (matrice transformacije, putanje, boje, itd.)
        final updatedData = _whiteboardData.copyWith(
          paths: _paths.map((p) => p.toMap()).toList(),
          transformationMatrix: _transformationMatrix.storage.toList(),
          currentScale: _currentScale,
          lastModified: DateTime.now(),
        );

        // 2) sada uzimamo screenshot whiteboarda i konvertujemo ga u Uint8List(za preview u galeriji)
        final boundary = _whiteboardKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
        if (boundary != null) {
          final uiImage = await boundary.toImage(pixelRatio: 1.5);
          final byteData =
              await uiImage.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            // convert u Uint8List
            final pngBytes = byteData.buffer.asUint8List();

            // 3)spremanje tih bytova u whiteboardData (tj hive box)
            updatedData.screenshot = pngBytes;
          }
        }

        // 4) sejvanje u hive box sve skupa
        final box = Hive.box<WhiteboardData>('whiteboards');
        final index =
            box.values.toList().indexWhere((wb) => wb.id == updatedData.id);
        if (index != -1) {
          box.putAt(index, updatedData);
          _whiteboardData = updatedData;
          debugPrint('Saved successfully to box, including screenshot');
        }
      } catch (e, stack) {
        debugPrint('AutoSave error: $e\n$stack');
      }
    });
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

                // zvanje mathpix ai metode za prepoznavanje slike i slanje slike njima da dobijemo latex rezultate
                final MathpixAiSolving mathpixAiSolving = MathpixAiSolving();
                final result = await mathpixAiSolving.sendImageToMathpix(image);
                if (result != null) {
                  // moramo uredit latex jer ne dobijemo stopostotno cist rezultat iz mathpixa
                  String sanitized =
                      result.replaceAll(r"\(", r"$$").replaceAll(r"\)", r"$$");

                  setState(() {
                    _latexResult = sanitized;
                  });
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
            child: GestureDetector(
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: _handleScaleEnd,
              child: CustomPaint(
                painter: WhiteboardPainter(
                  paths: _paths,
                  transformationMatrix: _transformationMatrix,
                  currentColor: _currentColor,
                  currentPath: _currentPath,
                  strokeWidth: _strokeWidth,
                ),
                size: Size.infinite,
              ),
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
                              _toolSettings[_drawingMode]!.color =
                                  colorData['color']!;
                              _currentColor = colorData['color']!;
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

          //prikazivanje widgeta za biranje vrstu olovke (marker, gumica, normalna olovka)
          if (_showPenOptions)
            Positioned(
              right: 100,
              top: MediaQuery.of(context).size.height / 2 - 120,
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
                      child: Icon(Icons.edit,
                          color: _drawingMode == DrawingMode.pen
                              ? const Color.fromRGBO(23, 148, 210, 1)
                              : Colors.black),
                    ),
                    ToolButton(
                        isActive: _drawingMode == DrawingMode.marker,
                        onPressed: () {
                          setState(() {
                            _drawingMode = DrawingMode.marker;
                            _currentColor = _toolSettings[_drawingMode]!.color;
                            _strokeWidth =
                                _toolSettings[_drawingMode]!.strokeWidth;
                            _showColorOptions = false;
                          });
                        },
                        child: Icon(Icons.brush,
                            color: _drawingMode == DrawingMode.marker
                                ? const Color.fromRGBO(23, 148, 210, 1)
                                : Colors.black)),
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
                      child: Icon(Icons.cleaning_services,
                          color: _drawingMode == DrawingMode.eraser
                              ? const Color.fromRGBO(23, 148, 210, 1)
                              : Colors.black),
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

          // glavni panel za biranje alata
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height / 2 - 170,
            child: Column(
              children: [
                Container(
                  decoration: _panelDecoration,
                  child: Column(
                    children: [
                      ToolButton(
                        isActive: _currentTool == ToolMode.hand,
                        onPressed: () => _changeTool(ToolMode.hand),
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
                            _showColorOptions = false;
                          });
                        },
                        child: Icon(Icons.edit,
                            color: _currentTool == ToolMode.pen
                                ? const Color.fromRGBO(23, 148, 210, 1)
                                : Colors.black),
                      ),
                      ToolButton(
                        child: const Icon(Icons.text_fields),
                        onPressed: () {},
                      ),
                      ToolButton(
                        child: const Icon(Icons.shape_line),
                        onPressed: () {},
                      ),
                      ToolButton(
                        isActive: _currentTool == ToolMode.ai,
                        child: SvgPicture.asset(
                          _currentTool == ToolMode.ai
                              ? 'assets/icons/screen_sidebar_ai_selected.svg'
                              : 'assets/icons/screen_sidebar_ai.svg',
                          width: 30,
                          height: 30,
                        ),
                        onPressed: () {
                          _changeTool(ToolMode.ai);
                          setState(() {
                            _isSelectingArea = true;
                            // Disable other tools while selecting
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
                          onPressed: _undo, child: const Icon(Icons.undo)),
                      ToolButton(
                          onPressed: _redo, child: const Icon(Icons.redo)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // panel za prikazivanje latex rezultata (rezultata AI)
          if (_latexResult != null && _latexResult!.isNotEmpty)
            Positioned(
              bottom: 0,
              left: MediaQuery.of(context).size.width / 2 - 290,
              child: Container(
                width: 600,
                height: 150,
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
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox.expand(
                      child: SingleChildScrollView(
                        child: Transform.translate(
                          offset: Offset(
                              -MediaQuery.of(context).size.width * 0.15, -40),
                          child: LaTexT(
                            laTeXCode: Text(
                              textAlign: TextAlign.left,
                              _latexResult!,
                              style: GoogleFonts.inter(
                                fontSize: 40,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          // Bottom panel za zoomiranje
          Positioned(
            left: 20,
            bottom: 20,
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

          //ako je AI tool selektiran, prikazi overlay za selektiranje slike
          if (_isSelectingArea) _buildSelectionOverlay(),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  //     SCALE HANDLERS (Handle pinch, pan, and drawing)
  // ----------------------------------------------------------
  void _handleScaleStart(ScaleStartDetails details) {
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
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (details.scale != 1.0) {
      // Calculate new scale based on initial scale
      final newScale = _lastScale * details.scale;
      final clampedScale = newScale.clamp(_minScale, _maxScale);

      // Convert focal point to original coordinate space
      final inverseInitialMatrix =
          Matrix4.inverted(_initialTransformationMatrix);
      final transformedFocal = MatrixUtils.transformPoint(
        inverseInitialMatrix,
        _initialGestureFocalPoint,
      );

      // Calculate scale delta relative to initial state
      final scaleDelta = clampedScale / _lastScale;

      // Create new transformation matrix
      final updatedMatrix = Matrix4.copy(_initialTransformationMatrix)
        ..translate(transformedFocal.dx, transformedFocal.dy)
        ..scale(scaleDelta)
        ..translate(-transformedFocal.dx, -transformedFocal.dy);

      _transformationMatrix = updatedMatrix;
      _currentScale = clampedScale;
      setState(() {});
      _autoSave();
    } else if (_currentTool == ToolMode.hand) {
      final delta = details.focalPoint - _lastPanOffset!;
      _transformationMatrix.translate(
        delta.dx / _currentScale,
        delta.dy / _currentScale,
      );
      _lastPanOffset = details.focalPoint;
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
  }

  // ----------------------------------------------------------
  //     Utility Methods
  // ----------------------------------------------------------
  Offset _transformPoint(Offset point) {
    final inverseMatrix = Matrix4.inverted(_transformationMatrix);
    final transformed =
        inverseMatrix.transform3(vm.Vector3(point.dx, point.dy, 0));
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
      if (mode == ToolMode.hand) {
        _showPenOptions = false;
        _showColorOptions = false;
      }
    });
    _autoSave();
  }

  void _undo() {
    if (_paths.isNotEmpty) {
      setState(() {
        _redoStack.add(_paths.removeLast());
      });
      _autoSave();
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _paths.add(_redoStack.removeLast());
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
