import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'analytics.dart';
import 'api.dart';
import 'widgets.dart';

String _date(BuildContext context, DateTime? d) =>
    MaterialLocalizations.of(context).formatMediumDate((d ?? DateTime.now().add(const Duration(days: 30))).toLocal());

/// Friendly sheet shown when the server refuses an AI call for budget reasons.
/// Tiers: free | trial | premium | promo (this period's allowance is used up), guest (a guest
/// account needs a free account for AI after the onboarding check), busy (the daily free-AI
/// pool is full until midnight UTC; never sells Premium, since that would look like
/// manufactured scarcity). [allowUpgrade] is false where Premium must not be offered.
Future<void> showAiBudgetExhausted(BuildContext context, AiBudgetExhausted e, {bool allowUpgrade = true}) {
  Analytics.track(Events.quotaHit, {'feature': e.feature, 'kind': 'ai_budget', 'tier': e.tier});
  final l10n = context.l10n;
  final date = _date(context, e.resetsAt);
  final title = switch (e.tier) {
    'guest' => l10n.aiGuestTitle,
    'busy' => l10n.aiBusyTitle,
    _ => l10n.aiBudgetTitle,
  };
  final body = switch (e.tier) {
    'guest' => l10n.aiGuestBody,
    'busy' => l10n.aiBusyBody(_time(context, e.resetsAt)),
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
          Icon(e.tier == 'guest' ? Icons.person_add_alt_1 : Icons.hourglass_bottom,
              size: 40, color: Theme.of(sheet).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: Theme.of(sheet).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          if (e.tier == 'guest') ...[
            FilledButton(
              onPressed: () {
                Navigator.of(sheet).pop();
                // Link mode upgrades the guest account in place, keeping XP, streak and hifz.
                context.push('/sign-in?link=1');
              },
              child: Text(l10n.createFreeAccount),
            ),
            const SizedBox(height: 8),
          ],
          if (e.tier == 'free' && allowUpgrade) ...[
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

/// Local time of day for the "busy" pool reset (midnight UTC is 03:00 in Riyadh).
String _time(BuildContext context, DateTime? d) => MaterialLocalizations.of(context)
    .formatTimeOfDay(TimeOfDay.fromDateTime((d ?? DateTime.now().add(const Duration(hours: 12))).toLocal()));

/// Short note when a premium answer used the lighter model because the allowance is nearly used.
void showLighterModeNote(BuildContext context, DateTime? resetsAt) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(context.l10n.aiLighterMode(_date(context, resetsAt)))));
}
