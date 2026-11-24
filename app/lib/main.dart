import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/analytics.dart';
import 'core/config.dart';
import 'core/providers.dart';
import 'demo/demo_http.dart';
import 'demo/demo_repositories.dart';
import 'demo/demo_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  if (AppConfig.demoMode) {
    // Web preview: no backend. Supabase runs against a local fake for auth only;
    // data, AI and payments come from lib/demo/.
    await DemoStore.init(prefs);
    await Supabase.initialize(
      url: DemoHttpClient.url,
      publishableKey: DemoHttpClient.anonKey,
      httpClient: DemoHttpClient(),
      authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
    );
    runApp(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        quranRepoProvider.overrideWith((ref) => DemoQuranRepository(ref.watch(supabaseProvider))),
        userRepoProvider.overrideWith((ref) => DemoUserRepository(ref.watch(supabaseProvider))),
        edgeApiProvider.overrideWith((ref) => DemoEdgeApi(ref.watch(supabaseProvider))),
        paymentProvider.overrideWith((ref) => DemoPaymentProvider()),
      ],
      child: const MuslimAiApp(),
    ));
    return;
  }

  Future<void> start() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      // Accepts the legacy anon key or the new sb_publishable_ key.
      publishableKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
    );
    await Analytics.init();
    Analytics.track(Events.appOpened);
    runApp(ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MuslimAiApp(),
    ));
  }

  if (AppConfig.sentryDsn.isEmpty) {
    await start();
    return;
  }
  await SentryFlutter.init(
    (o) {
      o.dsn = AppConfig.sentryDsn;
      o.environment = AppConfig.environment;
      o.tracesSampleRate = 0.2;
      o.sendDefaultPii = false;
    },
    appRunner: start,
  );
}
