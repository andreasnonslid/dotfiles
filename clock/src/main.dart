import 'package:flutter/material.dart';

import 'app.dart';
import 'window_frame.dart';

Future<void> main() async {
  await initWindow('Clock');
  runApp(const ClockApp());
}
