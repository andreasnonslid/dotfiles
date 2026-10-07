import 'dart:convert';
import 'dart:io';

import 'check.dart';

const _days = [0, 1, 3, 7, 21]; // review interval per Leitner box

/// Walks up from the working dir, then from the executable, to find tasks/.
Directory findTasks() {
  for (final start in [
    Directory.current,
    File(Platform.resolvedExecutable).parent,
  ]) {
    for (var d = start.absolute; d.parent.path != d.path; d = d.parent) {
      final t = Directory('${d.path}/tasks');
      if (t.existsSync()) return t;
    }
  }
  throw StateError('no tasks/ folder found above ${Directory.current.path}');
}

class Flashcard {
  Flashcard(this.dir)
    : _j = jsonDecode(File('${dir.path}/card.json').readAsStringSync());

  final Directory dir;
  final Map<String, dynamic> _j;

  String get id => dir.path.split('/').last;
  String get prompt => _j['prompt'];
  String get why => _j['why'];
  List<String> get ref => List<String>.from(_j['ref']);

  Future<Directory> start() async {
    final work = Directory.systemTemp.createTempSync('drill');
    await copyTree('${dir.path}/fixture', work);
    return work;
  }

  /// find: [out] equals the answer. transform: the tree equals expected/.
  Future<bool> passes(Directory work, String out) async => _j['kind'] == 'find'
      ? normalize(out) == normalize(_j['answer'])
      : sameTree(work, '${dir.path}/expected');
}

/// How far a failed attempt was from passing, e.g. "found 1 of 2, 0 extra".
extension Feedback on Flashcard {
  Future<String> miss(Directory work, String out) async {
    if (_j['kind'] == 'find') {
      final got = normalize(out).split('\n').where((l) => l.isNotEmpty).toSet();
      final want = normalize(_j['answer']).split('\n').toSet();
      if (got.isEmpty) return 'no output';
      return 'found ${got.intersection(want).length} of ${want.length}, ${got.difference(want).length} extra';
    }
    final d = await Process.run('diff', [
      '-rq',
      work.path,
      '${dir.path}/expected',
    ]);
    final n = '${d.stdout}'
        .trim()
        .split('\n')
        .where((l) => l.isNotEmpty)
        .length;
    return '$n file${n == 1 ? '' : 's'} still differ${n == 1 ? 's' : ''} from the goal';
  }
}

class Deck {
  Deck._(this._file, this._state, this.cards);

  final File _file;
  final Map<String, dynamic> _state;
  final List<Flashcard> cards;

  factory Deck.load() {
    final base =
        Platform.environment['XDG_STATE_HOME'] ??
        '${Platform.environment['HOME']}/.local/state';
    final file = File('$base/drill/state.json');
    final cards =
        findTasks()
            .listSync()
            .whereType<Directory>()
            .map(Flashcard.new)
            .toList()
          ..sort((a, b) => a.id.compareTo(b.id));
    final state = file.existsSync()
        ? Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()))
        : <String, dynamic>{};
    return Deck._(file, state, cards);
  }

  static String _date(int plusDays) => DateTime.now()
      .add(Duration(days: plusDays))
      .toIso8601String()
      .substring(0, 10);

  /// Cards never seen or due today or earlier.
  List<Flashcard> get due => [
    for (final c in cards)
      if (((_state[c.id]?['due'] ?? '') as String).compareTo(_date(0)) <= 0) c,
  ];

  /// Pass within the reference length, no hints: next box. Otherwise same box. Skip: box 0.
  void grade(
    Flashcard c, {
    required int commands,
    required int hints,
    required bool skipped,
  }) {
    final old = (_state[c.id]?['box'] ?? 0) as int;
    final box = skipped
        ? 0
        : (commands <= c.ref.length
              ? (old + 1).clamp(0, _days.length - 1)
              : old);
    _state[c.id] = {'box': box, 'due': _date(_days[box])};
    _file.parent.createSync(recursive: true);
    _file.writeAsStringSync(jsonEncode(_state));
  }
}
