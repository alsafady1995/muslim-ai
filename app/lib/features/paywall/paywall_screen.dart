import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics.dart';
import '../../core/config.dart';
import '../../core/monetization.dart';
import '../../core/notifications.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../payments/payment_provider.dart';

final _offersProvider = FutureProvider.autoDispose<List<PlanOffer>>((ref) => ref.watch(paymentProvider).offers());

/// Sells one outcome, the Hifz Coach, with an honest trial timeline (docs/subscription-growth-audit.md §14.1).
/// No price-led copy, no promises of features that are not built, and a full-width "Continue free".
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, required this.source});
  final String source;
  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  PlanOffer? _selected;
  bool _busy = false;
  bool _purchased = false;
  late final PaywallGate _gate;

  @override
  void initState() {
    super.initState();
    _gate = ref.read(paywallGateProvider); // ref is unusable in dispose()
    Analytics.track(Events.paywallViewed, {'source': widget.source, 'intent': userIntent(ref)});
  }

  @override
  void dispose() {
    if (!_purchased) {
      Analytics.track(Events.paywallDismissed, {'source': widget.source});
      _gate.recordDismissed();
    }
    super.dispose();
  }

  Future<void> _buy(PlanOffer offer) async {
    setState(() => _busy = true);
    Analytics.track(Events.purchaseStarted, {'offer': offer.id, 'source': widget.source});
    final outcome = await ref.read(paymentProvider).purchase(offer);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome.status) {
      case PurchaseStatus.success:
        _purchased = true;
        Analytics.track(Events.purchaseCompleted, {'offer': offer.id, 'source': widget.source, 'trial': offer.trialDays != null});
        await _gate.recordEngaged();
        await _scheduleTrialReminder(offer);
        ref.invalidate(premiumProvider);
        ref.invalidate(dashboardProvider);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.welcomePremium)));
        _close();
      case PurchaseStatus.pending:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.purchasePending)));
      case PurchaseStatus.cancelled:
        break;
      case PurchaseStatus.failed:
        Analytics.track(Events.purchaseFailed, {'offer': offer.id, 'message': outcome.message ?? ''});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.purchaseFailed)));
    }
  }

  /// The promise on the paywall: "we remind you before any charge". Two days before the trial ends.
  Future<void> _scheduleTrialReminder(PlanOffer offer) async {
    final days = offer.trialDays;
    if (days == null || days < 3) return;
    final l10n = context.l10n;
    final at = DateTime.now().add(Duration(days: days - 2));
    await Reminders.scheduleOnce(Reminders.trialEnding, l10n.trialReminderTitle, l10n.trialReminderBody, at);
    Analytics.track(Events.trialReminderScheduled, {'days': days});
  }

  /// The paywall is normally pushed, but a reload or a direct link on the web opens it as the only
  /// page; popping that page leaves a blank screen, so go Home instead.
  void _close() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final offers = ref.watch(_offersProvider);
    final recite = userIntent(ref) == 'recite';
    final benefits = [
      (Icons.psychology, l10n.benefitHifzTests),
      (Icons.menu_book, l10n.benefitFullPage),
      (Icons.spellcheck, l10n.benefitWeakWords),
      (Icons.auto_awesome, l10n.benefitBestAi),
    ];
    return Scaffold(
      appBar: AppBar(leading: CloseButton(onPressed: _close)),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 20), children: [
          const Icon(Icons.workspace_premium, size: 56, color: AppColors.gold),
          const SizedBox(height: 8),
          Text(recite ? l10n.paywallHeadlineRecite : l10n.paywallHeadlineMemorize,
              textAlign: TextAlign.center, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(l10n.premiumSubtitle, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          for (final (icon, text) in benefits)
            ListTile(dense: true, leading: Icon(icon, color: theme.colorScheme.primary), title: Text(text)),
          const SizedBox(height: 8),
          offers.when(
            loading: () => const SizedBox(height: 120, child: LoadingView()),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_offersProvider)),
            data: (list) {
              if (list.isEmpty) return Text(l10n.storeUnavailable, textAlign: TextAlign.center);
              // Annual is the default and highlighted; monthly stays one tap away.
              final selected = _selected ?? list.firstWhere((o) => o.period == 'year', orElse: () => list.first);
              final savePct = _annualSavingsPercent(list);
              final period = selected.period == 'year' ? l10n.perYear : l10n.perMonth;
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final o in list)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: o == selected ? theme.colorScheme.primary : Colors.transparent, width: 2),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => setState(() => _selected = o),
                      leading: Icon(o == selected ? Icons.radio_button_checked : Icons.radio_button_off),
                      title: Row(children: [
                        Text(o.period == 'year' ? l10n.yearly : l10n.monthly),
                        if (o.period == 'year') ...[
                          const SizedBox(width: 8),
                          Flexible(child: _Badge(savePct != null ? '${l10n.bestValue} · ${l10n.savePercent(savePct)}' : l10n.bestValue)),
                        ],
                      ]),
                      subtitle: o.trialDays != null ? Text(l10n.freeTrialDays(o.trialDays!)) : null,
                      trailing: Text('${o.priceString} / ${o.period == 'year' ? l10n.perYear : l10n.perMonth}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                if (selected.trialDays != null) ...[
                  const SizedBox(height: 8),
                  _TrialTimeline(days: selected.trialDays!, price: selected.priceString, period: period),
                ],
                const SizedBox(height: 12),
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: _busy ? null : () => _buy(selected),
                  child: Text(_busy
                      ? '…'
                      : selected.trialDays != null
                          ? l10n.startMyFreeDays(selected.trialDays!)
                          : (selected.period == 'month' ? l10n.subscribeMonthly : l10n.subscribe)),
                ),
                const SizedBox(height: 4),
                // As visible as the buy button's neighbour, not a grey link hidden at the bottom.
                TextButton(
                  style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: _busy ? null : _close,
                  child: Text(l10n.continueFree),
                ),
                const SizedBox(height: 4),
                Text(selected.trialDays != null ? l10n.noChargeToday : l10n.subscriptionTerms,
                    textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
                const SizedBox(height: 8),
                Text(l10n.adFreePromise, textAlign: TextAlign.center, style: theme.textTheme.bodySmall),
              ]);
            },
          ),
          Wrap(alignment: WrapAlignment.center, children: [
            TextButton(
              onPressed: () async {
                final ok = await ref.read(paymentProvider).restore();
                if (ok) {
                  _purchased = true;
                  Analytics.track(Events.purchaseRestored);
                  ref.invalidate(premiumProvider);
                  if (context.mounted) _close();
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.nothingToRestore)));
                }
              },
              child: Text(l10n.restorePurchases),
            ),
            TextButton(onPressed: () => launchUrl(Uri.parse(AppConfig.termsUrl)), child: Text(l10n.terms)),
            TextButton(onPressed: () => launchUrl(Uri.parse(AppConfig.privacyUrl)), child: Text(l10n.privacyPolicy)),
          ]),
        ]),
      ),
    );
  }
}

/// Today: full access, no charge · Day N-2: we remind you · Day N: plan starts.
class _TrialTimeline extends StatelessWidget {
  const _TrialTimeline({required this.days, required this.price, required this.period});
  final int days;
  final String price;
  final String period;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final steps = [
      (Icons.lock_open, l10n.trialToday, l10n.trialTodayBody),
      if (days >= 3) (Icons.notifications_active_outlined, l10n.trialDayN(days - 2), l10n.trialReminderStep),
      (Icons.workspace_premium, l10n.trialDayN(days), l10n.trialChargeStep(price, period)),
    ];
    return Card(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(children: [
          for (final (icon, title, body) in steps)
            ListTile(
              dense: true,
              leading: Icon(icon, color: theme.colorScheme.primary),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(body),
            ),
        ]),
      ),
    );
  }
}

/// Savings of annual vs 12 x monthly, e.g. 49 for $29.99/yr vs $4.99/mo. Null if prices are unknown.
int? _annualSavingsPercent(List<PlanOffer> offers) {
  double? year, month;
  for (final o in offers) {
    if (o.period == 'year') year ??= o.price;
    if (o.period == 'month') month ??= o.price;
  }
  if (year == null || month == null || month <= 0) return null;
  final pct = ((1 - year / (month * 12)) * 100).floor();
  return pct >= 5 ? pct : null;
}

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(12)),
        child: Text(text,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black, fontWeight: FontWeight.w700)),
      );
}
