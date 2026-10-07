import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../debug.dart';
import '../util.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> {
  static const _max = Duration(hours: 99);

  final _sw = Stopwatch(); // time used so far
  Duration _set = const Duration(minutes: 5);
  Timer?
  _tick; // Timer, not a Ticker: must still finish while the tab is hidden

  bool get _running => _sw.isRunning;
  Duration get _remaining {
    final d = _set - _sw.elapsed;
    return d < Duration.zero ? Duration.zero : d;
  }

  bool get _finished => _set > Duration.zero && _remaining == Duration.zero;

  void _start() {
    _sw.start();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_remaining > Duration.zero) return setState(() {});
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.vibrate();
      _pause();
    });
    setState(() {});
  }

  void _pause() => setState(() {
    _sw.stop();
    _tick?.cancel();
  });

  void _reset() => setState(() {
    _pause();
    _sw.reset();
  });

  void _setTo(Duration d) {
    _set = Duration(seconds: d.inSeconds.clamp(0, _max.inSeconds));
    _reset();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  Widget _stepper(String label, Duration step) => Outline(
    '$label stepper',
    interactive: true,
    child: Column(
      children: [
        IconButton(
          onPressed: _running ? null : () => _setTo(_set + step),
          icon: const Icon(Icons.keyboard_arrow_up),
        ),
        Text(label),
        IconButton(
          onPressed: _running ? null : () => _setTo(_set - step),
          icon: const Icon(Icons.keyboard_arrow_down),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rem = _remaining;
    final shown = Duration(seconds: (rem.inMilliseconds / 1000).ceil());
    final dial = (MediaQuery.sizeOf(context).shortestSide - 360).clamp(
      140.0,
      400.0,
    );

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Outline(
              'countdown',
              child: SizedBox.square(
                dimension: dial,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: _set == Duration.zero
                            ? 0
                            : rem.inMilliseconds / _set.inMilliseconds,
                        strokeWidth: 8,
                      ),
                    ),
                    Text(
                      _finished ? "Time's up" : fmt(shown),
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontFeatures: tabular,
                        color: _finished ? theme.colorScheme.error : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _stepper('hours', const Duration(hours: 1)),
                _stepper('min', const Duration(minutes: 1)),
                _stepper('sec', const Duration(seconds: 1)),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final m in [1, 5, 10, 25])
                  Outline(
                    'preset $m',
                    interactive: true,
                    child: ActionChip(
                      label: Text('$m min'),
                      onPressed: _running
                          ? null
                          : () => _setTo(Duration(minutes: m)),
                    ),
                  ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Outline(
                  'start/pause',
                  interactive: true,
                  child: FilledButton(
                    onPressed: _running
                        ? _pause
                        : (rem > Duration.zero ? _start : null),
                    child: Text(_running ? 'Pause' : 'Start'),
                  ),
                ),
                Outline(
                  'reset',
                  interactive: true,
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: const Text('Reset'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
