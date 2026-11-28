import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/adhkar/adhkar_screen.dart';
import '../features/ask/ask_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/benchmark/benchmark_recorder_screen.dart';
import '../features/coach/coach_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/groups/group_screen.dart';
import '../features/groups/groups_screen.dart';
import '../features/hifz/hifz_screen.dart';
import '../features/hifz/weak_words_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/paywall/paywall_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/qibla/qibla_screen.dart';
import '../features/quran/reader_screen.dart';
import '../features/quran/surah_list_screen.dart';
import '../features/search/search_screen.dart';
import '../features/shell/app_shell.dart';
import 'config.dart';
import 'providers.dart';

/// Set while the user is in onboarding. The guest account is created early (before the
/// first Al-Fatiha check), so "signed in" alone no longer means "onboarding finished".
const onboardingInProgressKey = 'onboarding_in_progress';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(supabaseProvider).auth.currentUser != null;
      final inProgress = ref.read(sharedPrefsProvider).getBool(onboardingInProgressKey) ?? false;
      final loc = state.matchedLocation;
      final onboarding = loc == '/onboarding' || loc == '/sign-in';
      // The onboarding Al-Fatiha check opens the coach. The paywall is deliberately not reachable
      // during onboarding (no ask for money before the user has had value).
      final allowedDuringOnboarding = onboarding || loc == '/coach';
      if (!signedIn && !onboarding) return '/onboarding';
      if (signedIn && inProgress && !allowedDuringOnboarding) return '/onboarding';
      if (signedIn && !inProgress && loc == '/onboarding') return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/sign-in', builder: (_, s) => SignInScreen(linkMode: s.uri.queryParameters['link'] == '1')),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/quran',
              builder: (_, _) => const SurahListScreen(),
              routes: [
                GoRoute(
                  path: ':surah',
                  builder: (_, s) => ReaderScreen(
                    surahId: int.parse(s.pathParameters['surah']!),
                    initialAyah: int.tryParse(s.uri.queryParameters['ayah'] ?? ''),
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: '/learn', builder: (_, _) => const HifzScreen()),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/ask', builder: (_, _) => const AskScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/me', builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      GoRoute(
        path: '/coach',
        builder: (_, s) => CoachScreen(
          startAyahId: int.tryParse(s.uri.queryParameters['from'] ?? ''),
          endAyahId: int.tryParse(s.uri.queryParameters['to'] ?? ''),
          hifzMode: s.uri.queryParameters['mode'] == 'hifz',
          source: s.uri.queryParameters['source'] ?? (s.uri.queryParameters['mode'] == 'hifz' ? 'hifz' : 'coach'),
        ),
      ),
      GoRoute(path: '/weak-words', builder: (_, _) => const WeakWordsScreen()),
      GoRoute(path: '/search', builder: (_, s) => SearchScreen(initialQuery: s.uri.queryParameters['q'])),
      GoRoute(path: '/assistant', builder: (_, _) => const AskScreen(assistantMode: true)),
      GoRoute(path: '/adhkar', builder: (_, _) => const AdhkarScreen()),
      GoRoute(path: '/adhkar/:id', builder: (_, s) => AdhkarDetailScreen(categoryId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      if (AppConfig.benchmarkRecorder && !AppConfig.demoMode)
        GoRoute(path: '/benchmark', builder: (_, _) => const BenchmarkRecorderScreen()),
      GoRoute(path: '/qibla', builder: (_, _) => const QiblaScreen()),
      GoRoute(path: '/groups', builder: (_, _) => const GroupsScreen()),
      GoRoute(
        path: '/groups/:id',
        builder: (_, s) => GroupScreen(groupId: s.pathParameters['id']!, initialTab: s.uri.queryParameters['tab']),
      ),
      GoRoute(
        path: '/paywall',
        pageBuilder: (_, s) => MaterialPage(
          fullscreenDialog: true,
          child: PaywallScreen(source: s.uri.queryParameters['source'] ?? 'unknown'),
        ),
      ),
    ],
  );
});
