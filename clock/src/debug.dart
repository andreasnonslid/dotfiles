import 'package:flutter/material.dart';

/// Debug outlines on/off. Toggle with the bug button or the D key.
final debugOutlines = ValueNotifier<bool>(false);

/// Outlines [child] with a label while debug mode is on.
/// Red = interactable, blue = display item.
/// The tree shape never changes, so state below is kept when toggling.
class Outline extends StatelessWidget {
  const Outline(
    this.label, {
    super.key,
    required this.child,
    this.interactive = false,
  });

  final String label;
  final Widget child;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: debugOutlines,
      builder: (context, on, _) {
        final color = interactive ? Colors.red : Colors.blue;
        return Stack(
          fit: StackFit.passthrough,
          clipBehavior: Clip.none,
          children: [
            DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: on
                  ? BoxDecoration(border: Border.all(color: color))
                  : const BoxDecoration(),
              child: child,
            ),
            if (on)
              Positioned(
                left: 0,
                top: 0,
                child: IgnorePointer(
                  child: Container(
                    color: color,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      label,
                      style: const TextStyle(fontSize: 9, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
