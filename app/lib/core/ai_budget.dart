import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'analytics.dart';
import 'api.dart';
import 'widgets.dart';

String _date(BuildContext context, DateTime? d) =>
    MaterialLocalizations.of(context).formatMediumDate((d ?? DateTime.now().add(const Duration(days: 30))).toLocal());

/// Friendly sheet shown when the server says this period's AI allowance is used up.
Future<void> showAiBudgetExhausted(BuildContext context, AiBudgetExhausted e) {
  Analytics.track(Events.quotaHit, {'feature': e.feature, 'kind': 'ai_budget', 'tier': e.tier});
  final l10n = context.l10n;
  final date = _date(context, e.resetsAt);
  final body = switch (e.tier) {
    'free' => l10n.aiBudgetFree(date),
    'trial' => l10n.aiBudgetTrial(date),
    _ => l10n.aiBudgetPremium(date),
  };
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Icon(Icons.hourglass_bottom, size: 40, color: Theme.of(sheet).colorScheme.primary),
          const SizedBox(height: 12),
          Text(l10n.aiBudgetTitle, textAlign: TextAlign.center, style: Theme.of(sheet).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          if (e.tier == 'free') ...[
            FilledButton(
              onPressed: () {
                Navigator.of(sheet).pop();
                context.push('/paywall?source=ai_budget_${e.feature}');
              },
              child: Text(l10n.goPremium),
            ),
            const SizedBox(height: 8),
          ],
          OutlinedButton(onPressed: () => Navigator.of(sheet).pop(), child: Text(l10n.done)),
        ]),
      ),
    ),
  );
}

/// Short note when a premium answer used the lighter model because the allowance is nearly used.
void showLighterModeNote(BuildContext context, DateTime? resetsAt) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(context.l10n.aiLighterMode(_date(context, resetsAt)))));
}
