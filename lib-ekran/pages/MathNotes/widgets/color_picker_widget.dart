import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/whiteboard_state.dart';
import 'package:odlikas_ekran/pages/MathNotes/core/types.dart';

class ColorPickerWidget extends StatelessWidget {
  final WhiteboardState state;
  final Function(Color) onColorSelected;
  final Function(double) onStrokeWidthChanged;

  const ColorPickerWidget({
    Key? key,
    required this.state,
    required this.onColorSelected,
    required this.onStrokeWidthChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 166,
      top: MediaQuery.of(context).size.height / 2 - 30,
      child: Container(
        margin: const EdgeInsets.only(right: 25),
        decoration: BoxDecoration(
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
        ),
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 16),
        child: Column(
          children: [
            // Stroke width slider
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
                      value: state.strokeWidth,
                      min: 1,
                      max: 30,
                      onChanged: onStrokeWidthChanged,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        state.showShapeOptions ? 'Ispunjenost' : 'Debljina',
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
            if (state.drawingMode != DrawingMode.eraser)
              SizedBox(
                width: 180,
                height: 180,
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: colorPalette.length,
                  itemBuilder: (context, index) {
                    final colorData = colorPalette[index];
                    return GestureDetector(
                      onTap: () {
                        Color selectedColor = colorData['color']!;
                        if (state.drawingMode == DrawingMode.marker) {
                          // Make marker semi-transparent
                          selectedColor = selectedColor.withOpacity(0.5);
                        }
                        onColorSelected(selectedColor);
                      },
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
                          if (state.currentColor.value ==
                                  colorData['color']!.value ||
                              (state.drawingMode == DrawingMode.marker &&
                                  state.currentColor.withOpacity(1.0).value ==
                                      colorData['color']!.value))
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
    );
  }
}
