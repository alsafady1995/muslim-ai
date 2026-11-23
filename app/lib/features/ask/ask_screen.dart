import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/analytics.dart';
import '../../core/api.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import 'answer_view.dart';

/// Ask the Quran (single questions, verse-focused) and the Islamic assistant
/// (multi-turn chat). Both use the same grounded-answer backend.
class AskScreen extends ConsumerStatefulWidget {
  const AskScreen({super.key, this.assistantMode = false});
  final bool assistantMode;
  @override
  ConsumerState<AskScreen> createState() => _AskScreenState();
}

class _Turn {
  _Turn(this.question);
  final String question;
  GroundedAnswer? answer;
  bool failed = false;
}

class _AskScreenState extends ConsumerState<AskScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _turns = <_Turn>[];
  String? _conversationId;
  bool _busy = false;

  String get _fn => widget.assistantMode ? 'assistant' : 'ask-quran';

  Future<void> _ask(String q) async {
    q = q.trim();
    if (q.length < 3 || _busy) return;
    _input.clear();
    final turn = _Turn(q);
    setState(() {
      _turns.add(turn);
      _busy = true;
    });
    Analytics.track(widget.assistantMode ? Events.assistantMessage : Events.askQuestion, {'length': q.length});
    try {
      final res = await ref.read(edgeApiProvider).call(_fn, {
        'question': q,
        'locale': ref.read(localeProvider).languageCode,
        if (widget.assistantMode && _conversationId != null) 'conversation_id': _conversationId,
      });
      turn.answer = GroundedAnswer(res);
      _conversationId = turn.answer!.conversationId;
    } on QuotaExceeded {
      _turns.remove(turn);
      Analytics.track(Events.quotaHit, {'feature': 'ask'});
      if (mounted) context.push('/paywall?source=ask_quota');
    } catch (_) {
      turn.failed = true;
    } finally {
      if (mounted) setState(() => _busy = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      });
    }
  }

  void _report(_Turn t) {
    Analytics.track(Events.askReported, {'answer_type': t.answer?.answerType ?? '', 'conversation_id': _conversationId ?? ''});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.thanksForReport)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final suggestions = [l10n.suggestStress, l10n.suggestForgiveness, l10n.suggestAnger, l10n.suggestGratitude];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.assistantMode ? l10n.assistant : l10n.askTheQuran),
        actions: [
          if (!widget.assistantMode)
            IconButton(tooltip: l10n.assistant, icon: const Icon(Icons.forum_outlined), onPressed: () => context.push('/assistant')),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: _turns.isEmpty
              ? ListView(padding: const EdgeInsets.all(20), children: [
                  Icon(Icons.auto_awesome, size: 56, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(widget.assistantMode ? l10n.assistantIntro : l10n.askIntro, textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  for (final s in suggestions)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(onPressed: () => _ask(s), child: Text(s)),
                    ),
                ])
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(16),
                  itemCount: _turns.length,
                  itemBuilder: (_, i) {
                    final t = _turns[i];
                    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(t.question),
                        ),
                      ),
                      if (t.answer != null)
                        AnswerView(answer: t.answer!, onFollowUp: _ask, onReport: () => _report(t))
                      else if (t.failed)
                        ListTile(leading: const Icon(Icons.error_outline), title: Text(l10n.errorGeneric),
                            trailing: TextButton(onPressed: () {
                              setState(() => _turns.remove(t));
                              _ask(t.question);
                            }, child: Text(l10n.retry)))
                      else
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                            const SizedBox(width: 12),
                            Text(l10n.searchingSources),
                          ]),
                        ),
                    ]);
                  },
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 600,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _ask,
                  decoration: InputDecoration(hintText: l10n.askPlaceholder, counterText: ''),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _busy ? null : () => _ask(_input.text), icon: const Icon(Icons.send)),
            ]),
          ),
        ),
      ]),
    );
  }
}
