import 'dart:io' show Platform, exit;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'debug.dart';

final desktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;

/// Call before runApp. Frameless window: [WindowFrame] draws the close button,
/// drag strip and resize edges.
Future<void> initWindow() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!desktop) return;
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(1280, 720),
      title: 'Clock',
      titleBarStyle: TitleBarStyle.hidden,
    ),
    () async {
      await windowManager.show();
      await windowManager.focus();
    },
  );
}

/// Page scaffold plus the frameless-window chrome (desktop only).
/// Wrap your whole app body in this; nothing else knows about the window.
class WindowFrame extends StatelessWidget {
  const WindowFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final content = Stack(
      children: [
        child,
        if (desktop) ...[
          const Positioned(
            left: 56,
            right: 56,
            top: 0,
            height: 24,
            child: DragToMoveArea(child: SizedBox.expand()),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: Outline(
              'close',
              interactive: true,
              child: IconButton(
                tooltip: 'Exit',
                icon: const Icon(Icons.close),
                onPressed: () => exit(0),
              ),
            ),
          ),
        ],
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: desktop ? DragToResizeArea(child: content) : content,
      ),
    );
  }
}
