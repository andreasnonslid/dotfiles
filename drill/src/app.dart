import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'check.dart';
import 'deck.dart';
import 'window_frame.dart';

const _mono = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: ['Menlo', 'Consolas'],
  fontSize: 14,
);

class DrillApp extends StatelessWidget {
  const DrillApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Drill',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorSchemeSeed: Colors.teal),
    darkTheme: ThemeData(
      colorSchemeSeed: Colors.teal,
      brightness: Brightness.dark,
    ),
    home: const WindowFrame(child: DrillPage()),
  );
}

class DrillPage extends StatefulWidget {
  const DrillPage({super.key});

  @override
  State<DrillPage> createState() => _DrillPageState();
}

class _DrillPageState extends State<DrillPage> {
  final _deck = Deck.load();
  late final _due = _deck.due;
  final _input = TextEditingController();
  late final _focus = FocusNode(onKeyEvent: _key);
  final _scroll = ScrollController();
  final _log = <(String, String, String)>[]; // (command, output, note)
  Directory? _work;
  int _i = 0;
  int _n = 0; // commands run on this card
  int _hints = 0;
  final _history = <String>[]; // commands this session, up/down recalls them
  int _hi = 0; // history cursor; == length means the empty line
  bool? _skipped; // non-null once the card is finished

  Flashcard? get _card => _i < _due.length ? _due[_i] : null;

  @override
  void initState() {
    super.initState();
    _begin();
  }

  @override
  void dispose() {
    _work?.deleteSync(recursive: true);
    super.dispose();
  }

  Future<void> _begin() async {
    final c = _card;
    if (c == null) return setState(() {});
    _work?.deleteSync(recursive: true);
    _work = await c.start();
    setState(() {
      _log.clear();
      _n = 0;
      _hints = 0;
      _skipped = null;
    });
    _focus.requestFocus();
  }

  void _finish(bool skipped) {
    _deck.grade(_card!, commands: _n, hints: _hints, skipped: skipped);
    setState(() => _skipped = skipped);
  }

  Future<void> _submit(String raw) async {
    final line = raw.trim();
    _input.clear();
    _focus.requestFocus();
    if (line.isEmpty) return;
    if (_history.isEmpty || _history.last != line) _history.add(line);
    _hi = _history.length;
    if (!isAllowed(line)) {
      return setState(
        () => _log.add((line, '', 'not allowed. Tools: ${allowed.join(' ')}')),
      );
    }
    _n++;
    final r = await run(line, _work!);
    final lines = (r.out + r.err).trimRight().split('\n');
    final out = lines.take(40).join('\n') + (lines.length > 40 ? '\n…' : '');
    final ok = await _card!.passes(_work!, r.out);
    final note = ok ? '' : await _card!.miss(_work!, r.out);
    setState(() => _log.add((line, out, note)));
    if (ok) _finish(false);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _scroll.jumpTo(_scroll.position.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = _card;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
          child: c == null
              ? Center(
                  child: Text(
                    _due.isEmpty
                        ? 'Nothing due. Come back tomorrow.'
                        : 'All done for today.',
                    style: theme.textTheme.headlineMedium,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Flashcard ${_i + 1} of ${_due.length}',
                          style: theme.textTheme.labelLarge,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: LinearProgressIndicator(
                            value: _i / _due.length,
                          ),
                        ),
                      ],
                    ),
                    Text(c.prompt, style: theme.textTheme.headlineSmall),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView(
                          controller: _scroll,
                          children: [
                            for (final (cmd, out, note) in _log) ...[
                              if (cmd.isNotEmpty)
                                SelectableText(
                                  '\$ $cmd',
                                  style: _mono.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              if (out.isNotEmpty)
                                SelectableText(out, style: _mono),
                              if (note.isNotEmpty)
                                Text(
                                  note,
                                  style: _mono.copyWith(
                                    color: theme.colorScheme.tertiary,
                                  ),
                                ),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_skipped == null) _prompt() else _result(c),
                  ],
                ),
        ),
      ),
    );
  }

  KeyEventResult _key(FocusNode node, KeyEvent e) {
    final up = e.logicalKey == LogicalKeyboardKey.arrowUp;
    if (e is KeyUpEvent ||
        (!up && e.logicalKey != LogicalKeyboardKey.arrowDown)) {
      return KeyEventResult.ignored;
    }
    _hi = (_hi + (up ? -1 : 1)).clamp(0, _history.length);
    final text = _hi == _history.length ? '' : _history[_hi];
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    return KeyEventResult.handled;
  }

  void _hint() {
    final c = _card!;
    final levels = [
      ...c.hints,
      'uses ${c.ref.expand(tools).toSet().join(', ')}',
      c.ref.map(mask).join('  then  '),
    ];
    final text = _hints < levels.length
        ? 'hint ${_hints + 1}/${levels.length}: ${levels[_hints]}'
        : 'no more hints: skip to see the answer';
    _hints++;
    setState(() => _log.add(('', '', text)));
  }

  Widget _prompt() => TextField(
    controller: _input,
    focusNode: _focus,
    autofocus: true,
    style: _mono,
    onSubmitted: _submit,
    decoration: InputDecoration(
      prefixText: '\$ ',
      prefixStyle: _mono,
      hintText: 'type a command, Enter to run',
      border: const OutlineInputBorder(),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Hint',
            icon: const Icon(Icons.lightbulb_outline),
            onPressed: _hint,
          ),
          IconButton(
            tooltip: 'Reset files',
            icon: const Icon(Icons.restart_alt),
            onPressed: _begin,
          ),
          IconButton(
            tooltip: 'Skip and show answer',
            icon: const Icon(Icons.skip_next),
            onPressed: () => _finish(true),
          ),
        ],
      ),
    ),
  );

  Widget _result(Flashcard c) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _skipped! ? colors.errorContainer : colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 8,
        children: [
          Row(
            spacing: 8,
            children: [
              Icon(_skipped! ? Icons.close : Icons.check_circle),
              Text(
                _skipped!
                    ? 'Skipped'
                    : 'Correct: $_n command${_n == 1 ? '' : 's'} (reference ${c.ref.length}${_hints > 0 ? ', $_hints hint${_hints == 1 ? '' : 's'}' : ''})',
                style: theme.textTheme.titleMedium,
              ),
            ],
          ),
          SelectableText(c.ref.join('\n'), style: _mono),
          Text(c.why),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              autofocus: true,
              onPressed: () {
                _i++;
                _begin();
              },
              child: Text(_i + 1 < _due.length ? 'Next' : 'Finish'),
            ),
          ),
        ],
      ),
    );
  }
}
