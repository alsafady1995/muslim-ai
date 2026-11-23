import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics.dart';
import '../../core/config.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../../payments/payment_provider.dart';

final _offersProvider = FutureProvider.autoDispose<List<PlanOffer>>((ref) => ref.watch(paymentProvider).offers());

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, required this.source});
  final String source;
  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  PlanOffer? _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    Analytics.track(Events.paywallViewed, {'source': widget.source});
  }

  Future<void> _buy(PlanOffer offer) async {
    setState(() => _busy = true);
    Analytics.track(Events.purchaseStarted, {'offer': offer.id, 'source': widget.source});
    final outcome = await ref.read(paymentProvider).purchase(offer);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome.status) {
      case PurchaseStatus.success:
        Analytics.track(Events.purchaseCompleted, {'offer': offer.id, 'source': widget.source});
        ref.invalidate(premiumProvider);
        ref.invalidate(dashboardProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.welcomePremium)));
        Navigator.of(context).pop();
      case PurchaseStatus.pending:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.purchasePending)));
      case PurchaseStatus.cancelled:
        break;
      case PurchaseStatus.failed:
        Analytics.track(Events.purchaseFailed, {'offer': offer.id, 'message': outcome.message ?? ''});
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.purchaseFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final offers = ref.watch(_offersProvider);
    final benefits = [
      (Icons.mic, l10n.benefitRecitation),
      (Icons.psychology, l10n.benefitHifz),
      (Icons.auto_awesome, l10n.benefitAsk),
      (Icons.insights, l10n.benefitAnalytics),
      (Icons.record_voice_over, l10n.benefitReciters),
      (Icons.favorite, l10n.benefitSupport),
    ];
    return Scaffold(
      appBar: AppBar(leading: const CloseButton()),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          const Icon(Icons.workspace_premium, size: 64, color: AppColors.gold),
          const SizedBox(height: 8),
          Text(l10n.premiumTitle, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(l10n.premiumSubtitle, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          for (final (icon, text) in benefits)
            ListTile(dense: true, leading: Icon(icon, color: Theme.of(context).colorScheme.primary), title: Text(text)),
          const SizedBox(height: 12),
          offers.when(
            loading: () => const SizedBox(height: 120, child: LoadingView()),
            error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_offersProvider)),
            data: (list) {
              if (list.isEmpty) return Text(l10n.storeUnavailable, textAlign: TextAlign.center);
              final selected = _selected ?? list.firstWhere((o) => o.period == 'month', orElse: () => list.first);
              return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final o in list)
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: o == selected ? Theme.of(context).colorScheme.primary : Colors.transparent, width: 2),
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => setState(() => _selected = o),
                      leading: Icon(o == selected ? Icons.radio_button_checked : Icons.radio_button_off),
                      title: Text(o.period == 'year' ? l10n.yearly : l10n.monthly),
                      subtitle: o.trialDays != null ? Text(l10n.freeTrialDays(o.trialDays!)) : null,
                      trailing: Text('${o.priceString} / ${o.period == 'year' ? l10n.perYear : l10n.perMonth}',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                const SizedBox(height: 8),
                FilledButton(onPressed: _busy ? null : () => _buy(selected), child: Text(_busy ? '…' : l10n.subscribe)),
                const SizedBox(height: 8),
                Text(l10n.subscriptionTerms, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
              ]);
            },
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            TextButton(
              onPressed: () async {
                final ok = await ref.read(paymentProvider).restore();
                if (ok) {
                  Analytics.track(Events.purchaseRestored);
                  ref.invalidate(premiumProvider);
                  if (context.mounted) Navigator.of(context).pop();
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
