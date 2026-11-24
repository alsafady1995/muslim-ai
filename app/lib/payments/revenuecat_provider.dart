import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/config.dart';
import 'payment_provider.dart';

class RevenueCatProvider implements PaymentProvider {
  final _premium = StreamController<bool>.broadcast();
  bool _configured = false;

  String get _apiKey => Platform.isIOS ? AppConfig.revenueCatAppleKey : AppConfig.revenueCatGoogleKey;

  bool _hasEntitlement(CustomerInfo info) => info.entitlements.active.containsKey(AppConfig.premiumEntitlement);

  @override
  Future<void> init({required String userId}) async {
    if (_configured || _apiKey.isEmpty) return;
    await Purchases.setLogLevel(AppConfig.environment == 'prod' ? LogLevel.warn : LogLevel.debug);
    await Purchases.configure(PurchasesConfiguration(_apiKey)..appUserID = userId);
    Purchases.addCustomerInfoUpdateListener((info) => _premium.add(_hasEntitlement(info)));
    _configured = true;
  }

  @override
  Future<void> logIn(String userId) async {
    if (!_configured) return init(userId: userId);
    await Purchases.logIn(userId);
  }

  @override
  Future<void> logOut() async {
    if (!_configured) return;
    if (!await Purchases.isAnonymous) await Purchases.logOut();
  }

  @override
  Future<List<PlanOffer>> offers() async {
    if (!_configured) return [];
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) return [];
    return current.availablePackages.map((p) {
      final product = p.storeProduct;
      final intro = product.introductoryPrice;
      return PlanOffer(
        id: p.identifier,
        priceString: product.priceString,
        price: product.price,
        period: p.packageType == PackageType.annual ? 'year' : 'month',
        trialDays: intro != null && intro.price == 0 ? intro.periodNumberOfUnits * _days(intro.periodUnit) : null,
        native: p,
      );
    }).toList();
  }

  int _days(PeriodUnit unit) => switch (unit) {
        PeriodUnit.day => 1,
        PeriodUnit.week => 7,
        PeriodUnit.month => 30,
        PeriodUnit.year => 365,
        _ => 1,
      };

  @override
  Future<PurchaseOutcome> purchase(PlanOffer offer) async {
    try {
      final result = await Purchases.purchase(PurchaseParams.package(offer.native! as Package));
      final ok = _hasEntitlement(result.customerInfo);
      _premium.add(ok);
      return PurchaseOutcome(ok ? PurchaseStatus.success : PurchaseStatus.pending);
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) return PurchaseOutcome(PurchaseStatus.cancelled);
      if (code == PurchasesErrorCode.paymentPendingError) return PurchaseOutcome(PurchaseStatus.pending);
      return PurchaseOutcome(PurchaseStatus.failed, e.message);
    }
  }

  @override
  Future<bool> restore() async {
    if (!_configured) return false;
    final info = await Purchases.restorePurchases();
    final ok = _hasEntitlement(info);
    _premium.add(ok);
    return ok;
  }

  @override
  Future<bool> isPremium() async {
    if (!_configured) return false;
    return _hasEntitlement(await Purchases.getCustomerInfo());
  }

  @override
  Stream<bool> get premiumChanges => _premium.stream;

  @override
  Uri? get manageSubscriptionsUrl => Platform.isIOS
      ? Uri.parse('https://apps.apple.com/account/subscriptions')
      : Uri.parse('https://play.google.com/store/account/subscriptions');
}
