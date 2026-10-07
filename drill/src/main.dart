import 'dart:convert';
import 'dart:io';

import 'check.dart';

const _days = [0, 1, 3, 7, 21]; // review interval per Leitner box

final _root = File(Platform.script.toFilePath()).parent.parent.path;
final _stateFile = File(
  '${Platform.environment['XDG_STATE_HOME'] ?? '${Platform.environment['HOME']}/.local/state'}/drill/state.json',
);

String _id(Directory d) => d.path.split('/').last;

String _date(int plusDays) => DateTime.now()
    .add(Duration(days: plusDays))
    .toIso8601String()
    .substring(0, 10);

Future<void> main() async {
  final state = _stateFile.existsSync()
      ? Map<String, dynamic>.from(jsonDecode(_stateFile.readAsStringSync()))
      : <String, dynamic>{};
  final cards = Directory('$_root/tasks')
      .listSync()
      .whereType<Directory>()
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final today = _date(0);
  final due = [
    for (final d in cards)
      if ((state[_id(d)]?['due'] ?? '').compareTo(today) <= 0) d,
  ];
  if (due.isEmpty) return print('Nothing due.');

  for (final dir in due) {
    final id = _id(dir);
    final card = jsonDecode(File('${dir.path}/card.json').readAsStringSync());
    final ref = List<String>.from(card['ref']);
    final work = Directory.systemTemp.createTempSync('drill');
    await copyTree('${dir.path}/fixture', work);
    print('\n[$id] ${card['prompt']}   (:reset  :skip  :quit)');

    var n = 0;
    var passed = false;
    var skipped = false;
    while (!passed && !skipped) {
      stdout.write('\$ ');
      final line = stdin.readLineSync()?.trim();
      if (line == null || line == ':quit') return _save(state);
      if (line.isEmpty) continue;
      if (line == ':skip') {
        skipped = true;
      } else if (line == ':reset') {
        work.deleteSync(recursive: true);
        work.createSync();
        await copyTree('${dir.path}/fixture', work);
        n = 0;
      } else if (!isAllowed(line)) {
        print('not allowed (tools: ${allowed.join(' ')})');
      } else {
        n++;
        final r = await run(line, work);
        final shown = (r.out + r.err).trimRight().split('\n');
        print(shown.take(40).join('\n') + (shown.length > 40 ? '\n…' : ''));
        passed = card['kind'] == 'find'
            ? normalize(r.out) == normalize(card['answer'])
            : await sameTree(work, '${dir.path}/expected');
      }
    }
    work.deleteSync(recursive: true);

    final old = (state[id]?['box'] ?? 0) as int;
    final box = skipped
        ? 0
        : (n <= ref.length ? (old + 1).clamp(0, _days.length - 1) : old);
    state[id] = {'box': box, 'due': _date(_days[box])};
    print(skipped
        ? 'skipped.'
        : 'correct: $n command(s), reference ${ref.length}');
    print('  ${ref.join('\n  ')}\n  why: ${card['why']}');
  }
  _save(state);
}

void _save(Map<String, dynamic> state) {
  _stateFile.parent.createSync(recursive: true);
  _stateFile.writeAsStringSync(jsonEncode(state));
}
