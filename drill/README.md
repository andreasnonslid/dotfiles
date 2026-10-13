# drill

Anki-style GUI drills for core shell tools (rg, fd, sed, awk, sort, uniq, cut, tr, find...). Flutter, desktop.

    ./setup.sh && cd generated && flutter run -d linux     # tests: flutter test

In the app: Enter runs a command, Up/Down recall earlier ones, the bulb gives progressive hints (using one keeps the card in its box), skip shows the answer. Each session = reviews due + 10 new cards, shuffled. Progress: `~/.local/state/drill/state.json`.

Add a card = a folder `tasks/<id>/` with `card.json` {kind: find|transform, prompt, ref[], hints[], why, answer (find), ordered (optional)}, `fixture/`, and `expected/` (transform). `flutter test` runs every card's reference solution against its fixture.
