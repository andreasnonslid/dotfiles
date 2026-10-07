import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../debug.dart';
import '../util.dart';

class ClockPage extends StatelessWidget {
  const ClockPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Frames((context) {
      final now = DateTime.now();
      return LayoutBuilder(
        builder: (context, c) => Padding(
          padding: const EdgeInsets.all(24),
          child: Flex(
            direction: c.maxWidth > c.maxHeight
                ? Axis.horizontal
                : Axis.vertical,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 32,
            children: [
              Flexible(
                child: Outline(
                  'analog clock',
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: CustomPaint(
                      painter: AnalogPainter(now, theme.colorScheme),
                    ),
                  ),
                ),
              ),
              Flexible(
                child: Outline(
                  'digital clock',
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      children: [
                        Text(
                          '${two(now.hour)}:${two(now.minute)}:${two(now.second)}',
                          style: theme.textTheme.displayLarge?.copyWith(
                            fontFeatures: tabular,
                          ),
                        ),
                        Text(
                          MaterialLocalizations.of(context).formatFullDate(now),
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class AnalogPainter extends CustomPainter {
  AnalogPainter(this.time, this.colors);

  final DateTime time;
  final ColorScheme colors;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    Offset dir(double turns) =>
        Offset(math.sin(turns * 2 * math.pi), -math.cos(turns * 2 * math.pi));

    canvas.drawCircle(c, r, Paint()..color = colors.surfaceContainerHighest);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = colors.outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.02,
    );

    for (var i = 0; i < 60; i++) {
      final major = i % 5 == 0;
      final d = dir(i / 60);
      canvas.drawLine(
        c + d * r * (major ? 0.80 : 0.88),
        c + d * r * 0.94,
        Paint()
          ..color = colors.onSurface
          ..strokeWidth = r * (major ? 0.025 : 0.008),
      );
    }

    void hand(double turns, double length, double width, Color color) {
      canvas.drawLine(
        c,
        c + dir(turns) * length,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    final s = time.second + time.millisecond / 1000;
    final m = time.minute + s / 60;
    final h = time.hour % 12 + m / 60;
    hand(h / 12, r * 0.50, r * 0.05, colors.onSurface);
    hand(m / 60, r * 0.75, r * 0.035, colors.onSurface);
    hand(s / 60, r * 0.85, r * 0.015, colors.primary);
    canvas.drawCircle(c, r * 0.04, Paint()..color = colors.primary);
  }

  @override
  bool shouldRepaint(AnalogPainter old) =>
      old.time != time || old.colors != colors;
}
