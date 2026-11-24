import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/analytics.dart';
import 'core/config.dart';
import 'core/providers.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'demo/demo_banner.dart';
import 'l10n/app_localizations.dart';

class MuslimAiApp extends ConsumerStatefulWidget {
  const MuslimAiApp({super.key});
  @override
  ConsumerState<MuslimAiApp> createState() => _MuslimAiAppState();
}

class _MuslimAiAppState extends ConsumerState<MuslimAiApp> {
  @override
  void initState() {
    super.initState();
    // Keep analytics, error reporting and payments tied to the signed-in user.
    ref.listenManual(currentUserProvider, (prev, user) async {
      if (user == null || user.id == prev?.id) return;
      final premium = await ref.read(premiumProvider.future).catchError((_) => false);
      await Analytics.identify(user.id, props: {
        'locale': ref.read(localeProvider).languageCode,
        'is_anonymous': user.isAnonymous,
        'premium': premium,
      });
      Sentry.configureScope((s) => s.setUser(SentryUser(id: user.id)));
      await ref.read(paymentProvider).init(userId: user.id);
      await ref.read(paymentProvider).logIn(user.id);
      ref.invalidate(premiumProvider);
    }, fireImmediately: true);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      onGenerateTitle: (c) => AppLocalizations.of(c).appName,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(locale),
      darkTheme: AppTheme.dark(locale),
      routerConfig: router,
      builder: AppConfig.demoMode ? (_, child) => DemoBanner(child: child!) : null,
    );
  }
}
