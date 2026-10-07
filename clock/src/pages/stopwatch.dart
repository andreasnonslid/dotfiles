import 'package:flutter/material.dart';

import '../debug.dart';
import '../util.dart';

class StopwatchPage extends StatefulWidget {
  const StopwatchPage({super.key});

  @override
  State<StopwatchPage> createState() => _StopwatchPageState();
}

class _StopwatchPageState extends State<StopwatchPage> {
  final _sw = Stopwatch();
  final _laps = <Duration>[]; // lap end times, newest first

  void _toggle() => setState(() => _sw.isRunning ? _sw.stop() : _sw.start());

  void _lap() => setState(() => _laps.insert(0, _sw.elapsed));

  void _reset() => setState(() {
    _sw.reset();
    _laps.clear();
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final running = _sw.isRunning;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Outline(
            'elapsed',
            child: Frames(
              (_) => Text(
                fmt(_sw.elapsed, centis: true),
                style: theme.textTheme.displayMedium?.copyWith(
                  fontFeatures: tabular,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Outline(
                'start/stop',
                interactive: true,
                child: FilledButton(
                  onPressed: _toggle,
                  child: Text(running ? 'Stop' : 'Start'),
                ),
              ),
              const SizedBox(width: 12),
              Outline(
                running ? 'lap' : 'reset',
                interactive: true,
                child: OutlinedButton(
                  onPressed: running
                      ? _lap
                      : (_sw.elapsed > Duration.zero ? _reset : null),
                  child: Text(running ? 'Lap' : 'Reset'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Outline(
              'laps',
              child: ListView.builder(
                itemCount: _laps.length,
                itemBuilder: (context, i) {
                  final split =
                      _laps[i] -
                      (i + 1 < _laps.length ? _laps[i + 1] : Duration.zero);
                  return Outline(
                    'lap row',
                    child: ListTile(
                      dense: true,
                      title: Text('Lap ${_laps.length - i}'),
                      subtitle: Text(fmt(_laps[i], centis: true)),
                      trailing: Text(
                        fmt(split, centis: true),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontFeatures: tabular,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
