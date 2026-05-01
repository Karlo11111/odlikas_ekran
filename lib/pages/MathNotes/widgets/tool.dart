import 'package:flutter/material.dart';

// klasa za gumb alata
class ToolButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final bool isActive;

  const ToolButton({
    required this.child,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 32,
      splashRadius: 20,
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      icon: Container(
        padding: const EdgeInsets.all(4),
        color: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isActive
                  ? const Color.fromRGBO(182, 221, 241, 0.5)
                  : Colors.transparent,
            ),
            child: Container(
              color: isActive ? Colors.transparent : Colors.transparent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// tool settings za boje i debljine linija
class ToolSettings {
  Color color;
  double strokeWidth;

  ToolSettings({
    required this.color,
    required this.strokeWidth,
  });
}
