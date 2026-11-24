/// Payment abstraction. Launch uses RevenueCat (Apple IAP + Google Play Billing).
/// A web/Stripe/Moyasar provider can be added later by implementing this interface;
/// the server-side source of truth is the `subscriptions` table, fed by webhooks.
abstract class PaymentProvider {
  Future<void> init({required String userId});
  Future<void> logIn(String userId);
  Future<void> logOut();
  Future<List<PlanOffer>> offers();
  Future<PurchaseOutcome> purchase(PlanOffer offer);
  Future<bool> restore();
  Future<bool> isPremium();
  Stream<bool> get premiumChanges;
  /// Store page where the user manages / cancels the subscription.
  Uri? get manageSubscriptionsUrl;
}

class PlanOffer {
  PlanOffer({required this.id, required this.priceString, required this.period, this.price, this.trialDays, this.native});
  final String id;
  final String priceString; // localized, e.g. "$2.99" or "11.99 SAR"
  final double? price; // numeric price in the store currency, used for the savings badge
  final String period; // "month" | "year"
  final int? trialDays;
  final Object? native; // provider-specific package object
}

enum PurchaseStatus { success, cancelled, pending, failed }

class PurchaseOutcome {
  PurchaseOutcome(this.status, [this.message]);
  final PurchaseStatus status;
  final String? message;
}
