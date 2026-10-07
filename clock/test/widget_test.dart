import 'package:clock_app/app.dart';
import 'package:clock_app/debug.dart';
import 'package:clock_app/util.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fmt', () {
    expect(
      fmt(
        const Duration(minutes: 1, seconds: 5, milliseconds: 239),
        centis: true,
      ),
      '01:05.23',
    );
    expect(fmt(const Duration(hours: 2, minutes: 3)), '2:03:00');
    expect(fmt(Duration.zero), '00:00');
  });

  testWidgets('debug outlines toggle by button and D key', (tester) async {
    debugOutlines.value = false;
    await tester.pumpWidget(const ClockApp());
    await tester.pump();
    expect(find.text('analog clock'), findsNothing);

    await tester.tap(find.byTooltip('Debug outlines (D)'));
    await tester.pump();
    expect(find.text('analog clock'), findsOneWidget);
    expect(find.text('debug toggle'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
    await tester.pump();
    expect(find.text('analog clock'), findsNothing);

    await tester.pumpWidget(const SizedBox()); // dispose tickers and timers
  });

  testWidgets('timer preset and start/pause', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ClockApp());
    await tester.tap(find.byTooltip('Timer'));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('1 min'));
    await tester.pump();
    expect(find.text('01:00'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Start').first);
    await tester.pump();
    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(find.text('Pause'));
    await tester.pump();

    await tester.pumpWidget(const SizedBox());
  });
}
