import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:drill/check.dart';

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
}
