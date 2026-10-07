import 'dart:convert';
import 'dart:io';

import 'package:drill/check.dart';
import 'package:drill/deck.dart';
import 'package:flutter_test/flutter_test.dart';

Directory tasks() => Directory('tasks');
List<Directory> cardDirs() =>
    tasks().listSync().whereType<Directory>().toList();

void main() {
  group('isAllowed', () {
    test('accepts core pipelines, quoted regexes and awk programs', () {
      for (final ok in [
        "rg -l x sub | xargs sed -i 's/a/b/'",
        "rg 'a|b' file",
        "awk '{print \$2}' f",
        "sed -n '/x/,/y/p' f",
        "fd -e tmp -x rm",
        "fd -e txt -x mv {} {.}.md",
        "xargs -n 1 rm",
        "sort -u a > b",
        "tr a-z A-Z < f",
        "rg 'a..b' f",
      ]) {
        expect(isAllowed(ok), isTrue, reason: ok);
      }
    });
    test('rejects escapes', () {
      for (final bad in [
        'curl x',
        r'cat $(ls)',
        'cat `ls`',
        'cat /etc/passwd',
        'cat ../x',
        'rm -rf ~',
        r'cat $HOME/x',
        'rg x | sh',
        'rg x | xargs sh',
        'fd -x sh -c x',
        'find . -exec sh {} ;',
        'ls && curl x',
      ]) {
        expect(isAllowed(bad), isFalse, reason: bad);
      }
    });
  });

  test('normalize, tools and mask', () {
    expect(normalize(' b\n a \n\n'), 'a\nb');
    expect(normalize('b\na', ordered: true), 'b\na');
    const ref = r"rg -l 'f\(' sub | xargs sed -i 's/a/b/g'";
    expect(tools(ref), ['rg', 'xargs', 'sed']);
    expect(mask(ref), 'rg -l … | xargs sed -i …');
  });

  group('cards', () {
    test('are well formed', () {
      expect(cardDirs().length, greaterThanOrEqualTo(30));
      for (final d in cardDirs()) {
        final j = jsonDecode(File('${d.path}/card.json').readAsStringSync());
        expect(['find', 'transform'], contains(j['kind']), reason: d.path);
        expect((j['ref'] as List), isNotEmpty, reason: d.path);
        expect(
          (j['hints'] as List).length,
          greaterThanOrEqualTo(1),
          reason: d.path,
        );
        expect(j['why'], isNotEmpty, reason: d.path);
        expect(
          Directory('${d.path}/fixture').existsSync(),
          isTrue,
          reason: d.path,
        );
        if (j['kind'] == 'find') {
          expect(j['answer'], isNotEmpty, reason: d.path);
        } else {
          expect(
            Directory('${d.path}/expected').existsSync(),
            isTrue,
            reason: d.path,
          );
        }
        for (final r in j['ref']) {
          expect(isAllowed(r), isTrue, reason: '${d.path}: $r');
        }
      }
    });

    test('every reference solution passes, and a no-op does not', () async {
      for (final d in cardDirs()) {
        final c = Flashcard(d);
        final work = await c.start();
        // a command that changes nothing and prints nothing must not pass
        expect(
          await c.passes(work, ''),
          isFalse,
          reason: '${d.path} passes untouched',
        );
        final r = await run(c.ref.join(' && '), work);
        expect(
          await c.passes(work, r.out),
          isTrue,
          reason: '${d.path}: ${r.err}',
        );
        work.deleteSync(recursive: true);
      }
    });
  });

  test('feedback says how close a miss was', () async {
    final work = Directory.systemTemp.createTempSync('drilltest');
    final find = Flashcard(Directory('tasks/02-which-files'));
    expect(await find.miss(work, 'subdir/a.js\n'), 'found 1 of 2, 0 extra');
    expect(await find.miss(work, ''), 'no output');
    final sorted = Flashcard(Directory('tasks/31-sort-num'));
    expect(
      await sorted.miss(work, '33\n10\n2\n1\n'),
      'right lines, wrong order',
    );
    final rename = Flashcard(Directory('tasks/01-rename-call'));
    final w = await rename.start();
    expect(await rename.miss(w, ''), '2 files still differ from the goal');
    w.deleteSync(recursive: true);
    work.deleteSync(recursive: true);
  });

  group('Deck', () {
    late Directory tmp;
    late File state;
    setUp(() {
      tmp = Directory.systemTemp.createTempSync('deck');
      state = File('${tmp.path}/state.json');
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    Deck load() => Deck.load(state: state, tasks: tasks());

    test('caps new cards per session', () {
      expect(load().due.length, newPerSession);
    });

    test(
      'pass moves up a box, hints or extra commands do not, skip resets',
      () {
        final deck = load();
        final c = deck.cards.first; // 01: one reference command
        deck.grade(c, commands: 1, hints: 0, skipped: false);
        expect(jsonDecode(state.readAsStringSync())[c.id]['box'], 1);
        deck.grade(c, commands: 1, hints: 1, skipped: false);
        expect(jsonDecode(state.readAsStringSync())[c.id]['box'], 1);
        deck.grade(c, commands: 3, hints: 0, skipped: false);
        expect(jsonDecode(state.readAsStringSync())[c.id]['box'], 1);
        deck.grade(c, commands: 1, hints: 0, skipped: true);
        expect(jsonDecode(state.readAsStringSync())[c.id]['box'], 0);
      },
    );

    test('a card passed today is not due again today', () {
      final deck = load();
      final c = deck.cards.first;
      deck.grade(c, commands: 1, hints: 0, skipped: false);
      expect(load().due.map((d) => d.id), isNot(contains(c.id)));
    });
  });
}
