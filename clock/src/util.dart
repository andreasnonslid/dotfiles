import 'package:flutter/material.dart';

String two(int n) => n.toString().padLeft(2, '0');

/// 1:02:03, 02:03, or with [centis] 02:03.45
String fmt(Duration d, {bool centis = false}) {
  final h = d.inHours;
  final base =
      '${h > 0 ? '$h:' : ''}${two(d.inMinutes % 60)}:${two(d.inSeconds % 60)}';
  return centis ? '$base.${two(d.inMilliseconds % 1000 ~/ 10)}' : base;
}

const tabular = [FontFeature.tabularFigures()];

/// Rebuilds [builder] every frame. Flutter mutes the ticker while the tab is hidden.
class Frames extends StatefulWidget {
  const Frames(this.builder, {super.key});

  final WidgetBuilder builder;

  @override
  State<Frames> createState() => _FramesState();
}

class _FramesState extends State<Frames> with SingleTickerProviderStateMixin {
  late final _ticker = createTicker((_) => setState(() {}))..start();

  @override
  void dispose() {
    _ticker.dispose();
    return super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}
