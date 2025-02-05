import 'package:flutter/material.dart';

class ColorWidthIndicator extends StatelessWidget {
  final Color color;
  final double strokeWidth;
  final double maxWidth;

  const ColorWidthIndicator({
    required this.color,
    required this.strokeWidth,
    this.maxWidth = 30,
  });

  @override
  Widget build(BuildContext context) {
    final double ratio = strokeWidth / maxWidth;
    final double outerSize = 40;
    final double innerSize = outerSize * ratio;

    return Container(
      width: outerSize,
      height: outerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey, width: 2),
      ),
      child: Center(
        child: Container(
          width: innerSize,
          height: innerSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }
}
