# Clock

Analog + digital clock, timer, stopwatch and debug outlines. Flutter, no runtime packages, Linux only.

## Layout
Treat it as a template: swap `app.dart` and `pages/` for your own app.
- `src/main.dart` entry point, 9 lines
- `src/window_frame.dart` frameless window: setup, close button, drag and resize (template, app-agnostic)
- `src/debug.dart` debug outlines (D key): `Outline` widget + toggle (template)
- `src/app.dart` MaterialApp, theme, icon rail (app-specific)
- `src/pages/` the three clock-app pages; `src/util.dart` their shared helpers
- `test/`, `assets/`, `pubspec.yaml`, `analysis_options.yaml`, `setup.sh`
- `generated/` throwaway Flutter project made by `./setup.sh` (symlinks into the above), `build/` output; both gitignored

## Setup / run / test
    ./setup.sh
    cd generated
    flutter run -d linux
    flutter test

## Debug mode
Bug button at the bottom of the left rail, or press D. Red outline = interactable, blue = display item.
