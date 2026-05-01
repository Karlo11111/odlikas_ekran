import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:odlikas_ekran/pages/MathNotes/Core/whiteboard_state.dart';

class ZoomControlsWidget extends StatelessWidget {
  final WhiteboardState state;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const ZoomControlsWidget({
    Key? key,
    required this.state,
    required this.onZoomIn,
    required this.onZoomOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 30,
      bottom: 30,
      child: Container(
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
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: onZoomOut,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${(state.currentScale * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onZoomIn,
            ),
          ],
        ),
      ),
    );
  }
}
