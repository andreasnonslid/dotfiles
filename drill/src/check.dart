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
  'comm',
  'paste',
  'tac',
  'rev',
  'basename',
  'dirname',
  'echo',
  'printf',
  'tee',
  'mv',
  'cp',
  'rm',
  'mkdir',
  'touch',
};

/// Flags after which the next word is a command that gets run.
const _runs = {'-x', '-X', '--exec', '--exec-batch', '-exec', '-execdir'};

/// Guardrail, not a sandbox: it stops fat-fingered commands, and the work
/// happens in a temp copy. Single-quoted text is ignored, so regexes and awk
/// programs may contain `|`, `/`, `..` and `$1`. Every pipeline segment must
/// start with an allowed tool, and so must whatever xargs/-x/-exec runs.
/// ponytail: awk's system() and GNU sed's `e` still escape. Upgrade to
/// bubblewrap/unshare if cards ever run untrusted commands.
bool isAllowed(String line) {
  final sq = line.replaceAll(RegExp(r"'[^']*'"), "''");
  if (sq.contains(r'$(') || sq.contains('`') || sq.contains('..')) return false;
  if (RegExp(r'(^|\s)(/|~)|\$[A-Za-z_{]').hasMatch(sq)) return false;
  final bare = sq.replaceAll(RegExp(r'"[^"]*"'), '""');
  for (final seg in bare.split(RegExp(r'\|+|&&|;'))) {
    final t = seg.trim().split(RegExp(r'\s+'));
    if (!allowed.contains(t.first)) return false;
    for (var i = 0; i < t.length - 1; i++) {
      if (!_runs.contains(t[i]) && t[i] != 'xargs') continue;
      // xargs takes flags and their numbers first; the others run the next word.
      final cmd = t[i] == 'xargs'
          ? t
                .skip(i + 1)
                .firstWhere(
                  (w) =>
                      !w.startsWith('-') &&
                      int.tryParse(w) == null &&
                      w != '{}',
                  orElse: () => '',
                )
          : t[i + 1];
      if (cmd.isNotEmpty && !allowed.contains(cmd)) return false;
    }
  }
  return true;
}

/// Trim lines; sort them too unless [ordered], so rg's file order doesn't matter.
String normalize(String s, {bool ordered = false}) {
  final lines = s
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();
  return (ordered ? lines : (lines..sort())).join('\n');
}

/// Runs [line] in [dir] with a 5 s kill timeout and stdin on /dev/null (rg would
/// otherwise search a piped stdin instead of the folder). Returns stdout and stderr.
Future<({String out, String err})> run(String line, Directory dir) async {
  final p = await Process.start('sh', [
    '-c',
    '{ $line\n} </dev/null',
  ], workingDirectory: dir.path);
  final out = p.stdout.transform(utf8.decoder).join();
  final err = p.stderr.transform(utf8.decoder).join();
  await p.exitCode.timeout(
    const Duration(seconds: 5),
    onTimeout: () {
      p.kill();
      return -1;
    },
  );
  return (out: await out, err: await err);
}

Future<void> copyTree(String from, Directory to) async {
  await Process.run('cp', ['-r', '$from/.', to.path]);
}

Future<bool> sameTree(Directory a, String b) async =>
    (await Process.run('diff', ['-r', a.path, b])).exitCode == 0;

/// Allowed tools in [cmd], in order, no repeats. First hint level.
List<String> tools(String cmd) =>
    cmd.split(RegExp(r'\s+')).where(allowed.contains).toSet().toList();

/// [cmd] with arguments hidden: tools, flags and separators stay, the rest is `…`.
/// Second hint level. ponytail: whitespace tokens, so `a|b` without spaces isn't split.
String mask(String cmd) {
  final out = <String>[];
  for (final t in cmd.split(RegExp(r'\s+'))) {
    final keep =
        allowed.contains(t) ||
        t.startsWith('-') ||
        {'|', '&&', ';'}.contains(t);
    if (keep) {
      out.add(t);
    } else if (out.isEmpty || out.last != '…') {
      out.add('…');
    }
  }
  return out.join(' ');
}
