# drill
Anki-style drills for core shell tools. Run: `dart run src/main.dart`, or build once: `dart compile exe src/main.dart -o build/drill`.
Add a card: new folder `tasks/<id>/` with `card.json` (kind transform|find, prompt, ref, why, answer for find), `fixture/`, and `expected/` for transform. Progress: `~/.local/state/drill/state.json`.
Test: `dart pub get && dart test`.
