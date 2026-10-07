import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:drill/check.dart';
import 'package:drill/deck.dart';

void main() {
  test('allow-list and normalize', () {
    expect(isAllowed("rg -l x sub | xargs sed -i 's/a/b/'"), isTrue);
    for (final bad in [
      'rm -rf x',
      r'cat $(ls)',
      'cat /etc/passwd',
      'cat ../x',
      'rg x | sh',
    ]) {
      expect(isAllowed(bad), isFalse, reason: bad);
    }
    expect(normalize(' b\n a \n\n'), 'a\nb');
    const ref = r"rg -l 'f\(' sub | xargs sed -i 's/a/b/g'";
    expect(tools(ref), ['rg', 'xargs', 'sed']);
    expect(mask(ref), 'rg -l … | xargs sed -i …');
  });

  test('every seed card passes with its own reference', () async {
    for (final d in Directory('tasks').listSync().whereType<Directory>()) {
      final card = jsonDecode(File('${d.path}/card.json').readAsStringSync());
      final work = Directory.systemTemp.createTempSync('drilltest');
      await copyTree('${d.path}/fixture', work);
      final r = await run((card['ref'] as List).join(' && '), work);
      final ok = card['kind'] == 'find'
          ? normalize(r.out) == normalize(card['answer'])
          : await sameTree(work, '${d.path}/expected');
      expect(ok, isTrue, reason: d.path);
      work.deleteSync(recursive: true);
    }
  });

  test('feedback says how close a miss was', () async {
    final work = Directory.systemTemp.createTempSync('drilltest');
    final find = Flashcard(Directory('tasks/02-which-files'));
    expect(await find.miss(work, 'subdir/a.js\n'), 'found 1 of 2, 0 extra');
    expect(await find.miss(work, ''), 'no output');
    final rename = Flashcard(Directory('tasks/01-rename-call'));
    await rename.start().then(
      (w) async => expect(
        await rename.miss(w, ''),
        '2 files still differ from the goal',
      ),
    );
    work.deleteSync(recursive: true);
  });
}
