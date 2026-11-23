import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/models.dart';
import '../data/quran_repository.dart';
import '../data/user_repository.dart';
import '../payments/payment_provider.dart';
import '../payments/revenuecat_provider.dart';
import 'api.dart';

final sharedPrefsProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError('overridden in main'));

final supabaseProvider = Provider<SupabaseClient>((ref) => Supabase.instance.client);

final authStateProvider = StreamProvider<AuthState>((ref) => ref.watch(supabaseProvider).auth.onAuthStateChange);

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseProvider).auth.currentUser;
});

final edgeApiProvider = Provider<EdgeApi>((ref) => EdgeApi(ref.watch(supabaseProvider)));
final quranRepoProvider = Provider<QuranRepository>((ref) => QuranRepository(ref.watch(supabaseProvider)));
final userRepoProvider = Provider<UserRepository>((ref) => UserRepository(ref.watch(supabaseProvider)));
final paymentProvider = Provider<PaymentProvider>((ref) => RevenueCatProvider());

/// Home dashboard; invalidate after any gamified action.
final dashboardProvider = FutureProvider.autoDispose<Dashboard>((ref) async {
  ref.watch(currentUserProvider);
  return ref.watch(userRepoProvider).dashboard();
});

final surahsProvider = FutureProvider<List<Surah>>((ref) => ref.watch(quranRepoProvider).surahs());
final recitersProvider = FutureProvider<List<Reciter>>((ref) => ref.watch(quranRepoProvider).reciters());

/// Premium status: store entitlement (instant after purchase) OR server subscription row.
class PremiumController extends AsyncNotifier<bool> {
  StreamSubscription<bool>? _sub;

  @override
  Future<bool> build() async {
    final payments = ref.watch(paymentProvider);
    _sub?.cancel();
    _sub = payments.premiumChanges.listen((v) => state = AsyncData(v || (state.value ?? false)));
    ref.onDispose(() => _sub?.cancel());
    final store = await payments.isPremium().catchError((_) => false);
    if (store) return true;
    if (ref.read(supabaseProvider).auth.currentUser == null) return false;
    final dash = await ref.read(userRepoProvider).dashboard();
    return dash.premium;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final premiumProvider = AsyncNotifierProvider<PremiumController, bool>(PremiumController.new);

/// App language. Stored locally and mirrored to the profile for server-side features.
class LocaleController extends Notifier<Locale> {
  static const supported = [Locale('ar'), Locale('en')];
  static const _key = 'locale';

  @override
  Locale build() {
    final saved = ref.read(sharedPrefsProvider).getString(_key);
    if (saved != null) return Locale(saved);
    final device = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return supported.any((l) => l.languageCode == device) ? Locale(device) : const Locale('ar');
  }

  Future<void> set(Locale locale) async {
    state = locale;
    await ref.read(sharedPrefsProvider).setString(_key, locale.languageCode);
    if (ref.read(supabaseProvider).auth.currentUser != null) {
      await ref.read(userRepoProvider).updateProfile({'locale': locale.languageCode});
    }
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);

/// Simple persisted preferences (reciter, translation, playback speed).
class PrefsController extends Notifier<Map<String, Object>> {
  @override
  Map<String, Object> build() {
    final p = ref.read(sharedPrefsProvider);
    return {
      'reciter_id': p.getInt('reciter_id') ?? 1,
      'speed': p.getDouble('speed') ?? 1.0,
      'show_translation': p.getBool('show_translation') ?? true,
      'font_scale': p.getDouble('font_scale') ?? 1.0,
    };
  }

  Future<void> setValue(String key, Object value) async {
    final p = ref.read(sharedPrefsProvider);
    switch (value) {
      case int v:
        await p.setInt(key, v);
      case double v:
        await p.setDouble(key, v);
      case bool v:
        await p.setBool(key, v);
      case String v:
        await p.setString(key, v);
    }
    state = {...state, key: value};
  }
}

final prefsProvider = NotifierProvider<PrefsController, Map<String, Object>>(PrefsController.new);
