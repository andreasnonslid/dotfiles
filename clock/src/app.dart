import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'debug.dart';
import 'pages/clock.dart';
import 'pages/stopwatch.dart';
import 'pages/timer.dart';
import 'window_frame.dart';

const _tabs = [
  (Icons.schedule, 'Clock'),
  (Icons.hourglass_bottom, 'Timer'),
  (Icons.timer_outlined, 'Stopwatch'),
];

class ClockApp extends StatelessWidget {
  const ClockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: const WindowFrame(child: Home()),
    );
  }
}

/// Icon rail on the left, the selected page on the right.
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _tab = 0;

  void _toggleDebug() => debugOutlines.value = !debugOutlines.value;

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.keyD): _toggleDebug},
      child: Focus(
        autofocus: true,
        child: Row(
          children: [
            Outline(
              'tabs',
              interactive: true,
              child: NavigationRail(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: [
                  for (final (icon, name) in _tabs)
                    NavigationRailDestination(
                      icon: Tooltip(message: name, child: Icon(icon)),
                      label: Text(name),
                    ),
                ],
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ValueListenableBuilder<bool>(
                        valueListenable: debugOutlines,
                        builder: (context, on, _) => Outline(
                          'debug toggle',
                          interactive: true,
                          child: IconButton(
                            tooltip: 'Debug outlines (D)',
                            isSelected: on,
                            icon: const Icon(Icons.bug_report_outlined),
                            selectedIcon: const Icon(Icons.bug_report),
                            onPressed: _toggleDebug,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // IndexedStack keeps the timer and stopwatch running on other tabs.
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const [ClockPage(), TimerPage(), StopwatchPage()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
