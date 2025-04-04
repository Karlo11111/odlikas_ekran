import 'package:flutter/material.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/whiteboard_state.dart';
import 'package:odlikas_ekran/pages/MathNotes/Managers/ai_manager.dart';
import 'package:odlikas_ekran/pages/MathNotes/Managers/drawing_manager.dart';
import 'package:odlikas_ekran/pages/MathNotes/Managers/image_manager.dart';
import 'package:odlikas_ekran/pages/MathNotes/Managers/shape_manager.dart';
import 'package:odlikas_ekran/pages/MathNotes/Managers/storage_manager.dart';
import 'package:odlikas_ekran/pages/MathNotes/Managers/text_menager.dart';
import 'package:odlikas_ekran/pages/MathNotes/Managers/transformation_manager.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/types.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/tool.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/toolbar_widget.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/color_picker_widget.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/pen_options_widget.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/shape_options_widget.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/zoom_controls_widget.dart';
import 'package:odlikas_ekran/pages/MathNotes/widgets/white_board_painter.dart';
import 'package:odlikas_ekran/pages/MathNotes/saveWhiteboards/whiteboard_data.dart';
import 'package:odlikas_ekran/pages/SolutionStepsPage/solution_steps_page.dart';
import 'package:odlikas_ekran/pages/UploadFiles/uploaded_files.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latext/latext.dart';

class MathNotes extends StatefulWidget {
  final WhiteboardData? whiteboardData;
  const MathNotes({super.key, this.whiteboardData});

  @override
  _MathNotesState createState() => _MathNotesState();
}

class _MathNotesState extends State<MathNotes> {
  late WhiteboardState _state;
  late DrawingManager _drawingManager;
  late ShapeManager _shapeManager;
  late TextManager _textManager;
  late ImageManager _imageManager;
  late AiManager _aiManager;
  late StorageManager _storageManager;
  late TransformationManager _transformationManager;

  final GlobalKey _whiteboardKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Initialize state
    _state = WhiteboardState();

    // Initialize managers
    _drawingManager = DrawingManager(_state);
    _shapeManager = ShapeManager(_state);
    _textManager = TextManager(_state);
    _imageManager = ImageManager(_state);
    _aiManager = AiManager(_state, _whiteboardKey);
    _storageManager = StorageManager(_state, widget.whiteboardData!,
        whiteboardKey: _whiteboardKey);
    _transformationManager = TransformationManager(_state);

    // Load saved state
    _storageManager.loadSavedState();

    // Setup autosave
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        await _storageManager.autoSave(force: true);
      }
    });
  }

  @override
  void dispose() {
    _storageManager.saveImmediately();
    super.dispose();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    // Delegate to appropriate manager based on current tool
    switch (_state.currentTool) {
      case ToolMode.hand:
        _transformationManager.handleScaleStart(details);
        break;
      case ToolMode.pen:
        _drawingManager.handleDrawingStart(details);
        break;
      case ToolMode.shape:
        _shapeManager.handleShapeStart(details);
        break;
      default:
        break;
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Delegate to appropriate manager based on current tool
    switch (_state.currentTool) {
      case ToolMode.hand:
        _transformationManager.handleScaleUpdate(details);
        break;
      case ToolMode.pen:
        _drawingManager.handleDrawingUpdate(details);
        break;
      case ToolMode.shape:
        _shapeManager.handleShapeUpdate(details);
        break;
      default:
        break;
    }

    // Trigger autosave after scale update
    _storageManager.autoSave();
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    // Delegate to appropriate manager based on current tool
    switch (_state.currentTool) {
      case ToolMode.hand:
        _transformationManager.handleScaleEnd(details);
        break;
      case ToolMode.pen:
        _drawingManager.handleDrawingEnd(details);
        break;
      case ToolMode.shape:
        _shapeManager.handleShapeEnd(details);
        break;
      default:
        break;
    }

    // Trigger autosave after scale end
    _storageManager.autoSave();
  }

  void _handleToolSelection(ToolMode mode) {
    switch (mode) {
      case ToolMode.hand:
        setState(() {
          _state.currentTool = mode;
          _state.showPenOptions = false;
          _state.showShapeOptions = false;
          _state.showColorOptions = false;
        });
        break;

      case ToolMode.pen:
        setState(() {
          _state.currentTool = mode;
          _state.showPenOptions = !_state.showPenOptions;
          _state.showShapeOptions = false;
          _state.showColorOptions = false;
        });
        break;

      case ToolMode.text:
        setState(() {
          _state.currentTool = mode;
          _state.showPenOptions = false;
          _state.showShapeOptions = false;
          _state.showColorOptions = false;
        });
        break;

      case ToolMode.shape:
        setState(() {
          _state.currentTool = mode;
          _state.showPenOptions = false;
          _state.showShapeOptions = !_state.showShapeOptions;
          _state.showColorOptions = false;
        });
        break;

      case ToolMode.ai:
        setState(() {
          _aiManager.enterAiSelectionMode();
        });
        break;

      case ToolMode.image:
        // Image tool is only activated when an image is selected, not directly from toolbar
        break;
    }
  }

  void _handleDrawingModeSelection(DrawingMode mode) {
    setState(() {
      _drawingManager.setDrawingMode(mode);
    });
  }

  void _handleShapeTypeSelection(ShapeType type) {
    setState(() {
      _shapeManager.setShapeType(type);
    });
  }

  void _toggleColorOptions() {
    setState(() {
      _state.showColorOptions = !_state.showColorOptions;
    });
  }

  void _handleColorSelection(Color color) {
    setState(() {
      if (_state.currentTool == ToolMode.pen) {
        _drawingManager.setColor(color);
      } else if (_state.currentTool == ToolMode.shape) {
        _shapeManager.setShapeColor(color);
      }
    });
  }

  void _handleStrokeWidthChange(double width) {
    setState(() {
      if (_state.currentTool == ToolMode.pen) {
        _drawingManager.setStrokeWidth(width);
      } else if (_state.currentTool == ToolMode.shape) {
        _shapeManager.setShapeFill(width);
      }
    });
  }

  void _handleImageUpload() {
    // Navigate to upload page and return selected image URL
    _handleToolSelection(ToolMode.hand); // Switch to hand tool when leaving

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UploadFilesPages(
          onImageSelected: (String imageUrl) {
            _imageManager.addImageToWhiteboard(
              imageUrl,
              screenSize: MediaQuery.of(context).size,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Drawing canvas - base layer
          RepaintBoundary(
            key: _whiteboardKey,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onScaleStart: _handleScaleStart,
              onScaleUpdate: _handleScaleUpdate,
              onScaleEnd: _handleScaleEnd,
              onTapDown: (details) {
                // Handle taps based on current tool
                if (_state.currentTool == ToolMode.text) {
                  _textManager.handleTextTap(details.localPosition);
                } else {
                  // Check if tapped on existing elements
                  final tappedImage =
                      _imageManager.findImageElementAt(details.localPosition);

                  if (tappedImage != null) {
                    _imageManager.handleImageTap(details.localPosition);
                  } else {
                    // No element tapped, reset selections
                    setState(() {
                      _state.resetSelections();

                      // Only reset to hand tool if we're in image or text mode
                      if (_state.currentTool == ToolMode.image ||
                          _state.currentTool == ToolMode.text) {
                        _state.currentTool = ToolMode.hand;
                      }

                      // Dismiss keyboard
                      FocusManager.instance.primaryFocus?.unfocus();
                    });
                  }
                }
              },
              child: CustomPaint(
                painter: WhiteboardPainter(
                  paths: _state.paths,
                  transformationMatrix: _state.transformationMatrix,
                  currentPath: _state.currentPath,
                  currentColor: _state.currentColor,
                  strokeWidth: _state.strokeWidth,
                  shapes: _state.shapes,
                  currentShape: _state.currentShape,
                ),
                size: Size.infinite,
              ),
            ),
          ),

          // Images layer
          ..._buildImageElements(),

          // Text elements layer
          ..._buildTextElements(),

          // Return button
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

          // Upload button
          Positioned(
            right: 20,
            top: MediaQuery.of(context).size.height / 2 - 260,
            child: Container(
              decoration: _panelDecoration,
              child: ToolButton(
                onPressed: _handleImageUpload,
                child: Image.asset(
                  'assets/icons/notes_upload.png',
                  width: 35,
                  height: 35,
                ),
              ),
            ),
          ),

          // Tool selection panel
          ToolbarWidget(
            state: _state,
            onToolSelected: (mode) => _handleToolSelection(mode as ToolMode),
          ),

          // Color picker panel
          if (_state.showColorOptions)
            ColorPickerWidget(
              state: _state,
              onColorSelected: (color) => _handleColorSelection(color),
              onStrokeWidthChanged: (width) => _handleStrokeWidthChange(width),
            ),

          // Pen options panel
          if (_state.showPenOptions)
            PenOptionsWidget(
              state: _state,
              onDrawingModeSelected: (mode) =>
                  _handleDrawingModeSelection(mode as DrawingMode),
              onColorOptionsToggle: () => _toggleColorOptions(),
            ),

          // Shape options panel
          if (_state.showShapeOptions)
            ShapeOptionsWidget(
              state: _state,
              onShapeTypeSelected: (type) =>
                  _handleShapeTypeSelection(type as ShapeType),
              onColorOptionsToggle: () => _toggleColorOptions(),
            ),

          // AI selection overlay
          if (_state.isSelectingArea) _aiManager.buildSelectionOverlay(),

          // AI selection instructions
          if (_state.isSelectingArea)
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

          // AI result panel
          if (_state.isOpenAiLoading || _state.latexResult != null)
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
                    // Display LaTeX result
                    if (_state.latexResult != null)
                      Align(
                        alignment: Alignment.topLeft,
                        child: LaTexT(
                          laTeXCode: Text(
                            _state.latexResult!,
                            textAlign: TextAlign.left,
                            style: GoogleFonts.inter(fontSize: 40),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Display loading spinner
                    if (_state.isOpenAiLoading)
                      Image.asset(
                        'assets/animations/spinning_circle.gif',
                        width: 100,
                        height: 100,
                      ),

                    // Display AI answer
                    if (!_state.isOpenAiLoading && _state.openAiAnswer != null)
                      _buildAiAnswerWidget(),
                  ],
                ),
              ),
            ),

          // Zoom controls
          ZoomControlsWidget(
            state: _state,
            onZoomIn: () => _transformationManager.zoomIn(
              Offset(
                MediaQuery.of(context).size.width / 2,
                MediaQuery.of(context).size.height / 2,
              ),
            ),
            onZoomOut: () => _transformationManager.zoomOut(
              Offset(
                MediaQuery.of(context).size.width / 2,
                MediaQuery.of(context).size.height / 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods to build various components

  List<Widget> _buildImageElements() {
    return _state.imageElements.map((element) {
      // Apply transformation matrix
      final double scale = _state.transformationMatrix.getMaxScaleOnAxis();
      final double dx = _state.transformationMatrix.getTranslation().x;
      final double dy = _state.transformationMatrix.getTranslation().y;

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
          behavior: HitTestBehavior.opaque,
          onTap: () => _imageManager.handleImageTap(
            Offset(
              transformedPosition.dx + scaledSize.width / 2,
              transformedPosition.dy + scaledSize.height / 2,
            ),
          ),
          onPanStart: (details) {
            if (_state.selectedImageElement == element) {
              _state.lastPanOffset = details.localPosition;
            }
          },
          onPanUpdate: (details) {
            if (_state.selectedImageElement == element &&
                _state.lastPanOffset != null) {
              _imageManager.moveImageElement(details.delta);
            }
          },
          onPanEnd: (details) {
            _state.lastPanOffset = null;
            _storageManager.autoSave();
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main image container with border if selected
              Container(
                width: scaledSize.width,
                height: scaledSize.height,
                decoration: BoxDecoration(
                  border: (_state.selectedImageElement == element)
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
                ),
                child: Opacity(
                  opacity: element.opacity,
                  child: _imageManager.buildImageWidget(
                      element.imageUrl, scaledSize),
                ),
              ),

              // Only show these controls when the image is selected
              if (_state.selectedImageElement == element) ...[
                // Resize handle (bottom right)
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) {
                      _imageManager.resizeImageElement(details.delta);
                      _storageManager.autoSave();
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
                      _imageManager.deleteSelectedImage();
                      _storageManager.autoSave();
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
    }).toList();
  }

  List<Widget> _buildTextElements() {
    return _state.textElements.map((element) {
      // Apply transformation matrix
      final double scale = _state.transformationMatrix.getMaxScaleOnAxis();
      final double dx = _state.transformationMatrix.getTranslation().x;
      final double dy = _state.transformationMatrix.getTranslation().y;

      // Transform position
      final Offset transformedPosition = Offset(
        element.position.dx * scale + dx,
        element.position.dy * scale + dy,
      );

      // Calculate scaled size and font
      final double scaledFontSize = element.fontSize * scale;
      final Size scaledSize = Size(
        element.size.width * scale,
        element.size.height * scale,
      );

      return Positioned(
        left: transformedPosition.dx,
        top: transformedPosition.dy,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            setState(() {
              _state.selectedTextElement = element;
              _state.currentTool = ToolMode.text;
            });
          },
          onPanStart: (details) {
            if (_state.selectedTextElement == element) {
              _state.lastPanOffset = details.localPosition;
            }
          },
          onPanUpdate: (details) {
            if (_state.selectedTextElement == element &&
                _state.lastPanOffset != null) {
              _textManager.moveTextElement(details.delta);
            }
          },
          onPanEnd: (details) {
            _state.lastPanOffset = null;
            _storageManager.autoSave();
          },
          child: Container(
            width: scaledSize.width,
            height: scaledSize.height,
            decoration: BoxDecoration(
              border: (_state.selectedTextElement == element)
                  ? Border.all(color: Colors.blue, width: 2)
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Text editing field or display
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
                    onChanged: (value) {
                      _textManager.updateTextContent(value);
                      _storageManager.autoSave();
                    },
                    onSubmitted: (value) {
                      _textManager.setTextEditing(false);
                      _storageManager.autoSave();

                      // Hide keyboard
                      FocusManager.instance.primaryFocus?.unfocus();
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

                // Delete button (if selected)
                if (_state.selectedTextElement == element)
                  Positioned(
                    right: -10,
                    top: -10,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _textManager.deleteSelectedText();
                        _storageManager.autoSave();
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                // Resize handle (if selected)
                if (_state.selectedTextElement == element)
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanUpdate: (details) {
                        _textManager.resizeTextElement(details.delta);
                        _storageManager.autoSave();
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
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
    }).toList();
  }

  Widget _buildAiAnswerWidget() {
    // Handle displaying AI answer
    if (_state.openAiAnswer == null || _state.openAiAnswer!.isEmpty) {
      return const Text('No solution available');
    }

    // Navigate to solution page when answer is available
    Future.microtask(() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SolutionStepsPage(
            steps: _state.openAiAnswer!,
            originalTask: _state.latexResult ?? '',
          ),
        ),
      );
    });

    return const Text('Opening solution...');
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
