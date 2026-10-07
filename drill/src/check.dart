import 'dart:convert';
import 'dart:io';

const allowed = {
  'rg',
  'fd',
  'sed',
  'awk',
  'grep',
  'sort',
  'uniq',
  'cut',
  'tr',
  'xargs',
  'head',
  'tail',
  'wc',
  'cat',
  'ls',
  'find',
  'diff',
};

/// Every pipeline segment must start with an allowed tool; no substitution,
/// `..` or absolute paths. ponytail: string checks, not a sandbox. Upgrade to
/// bubblewrap/unshare if cards ever run untrusted commands.
bool isAllowed(String line) {
  if (line.contains(r'$(') || line.contains('`') || line.contains('..'))
    return false;
  if (RegExp(r'(^|\s)/').hasMatch(line)) return false;
  return line
      .split(RegExp(r'\||&&|;'))
      .every((s) => allowed.contains(s.trim().split(RegExp(r'\s+')).first));
}

/// Trim and sort lines so output order and padding don't matter.
String normalize(String s) =>
    (s.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList()
          ..sort())
        .join('\n');

/// Runs [line] in [dir] with a 5 s kill timeout. Returns stdout and stderr.
Future<({String out, String err})> run(String line, Directory dir) async {
  final p = await Process.start('sh', ['-c', line], workingDirectory: dir.path);
  final out = p.stdout.transform(utf8.decoder).join();
  final err = p.stderr.transform(utf8.decoder).join();
  await p.exitCode.timeout(const Duration(seconds: 5), onTimeout: () {
    p.kill();
    return -1;
  });
  return (out: await out, err: await err);
}

Future<void> copyTree(String from, Directory to) async {
  await Process.run('cp', ['-r', '$from/.', to.path]);
}

Future<bool> sameTree(Directory a, String b) async =>
    (await Process.run('diff', ['-r', a.path, b])).exitCode == 0;
