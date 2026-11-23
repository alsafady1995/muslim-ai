import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/adhkar/adhkar_screen.dart';
import '../features/ask/ask_screen.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/coach/coach_screen.dart';
import '../features/goals/goals_screen.dart';
import '../features/hifz/hifz_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/paywall/paywall_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/quran/reader_screen.dart';
import '../features/quran/surah_list_screen.dart';
import '../features/search/search_screen.dart';
import '../features/shell/app_shell.dart';
import 'providers.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final signedIn = ref.read(supabaseProvider).auth.currentUser != null;
      final onboarding = state.matchedLocation == '/onboarding' || state.matchedLocation == '/sign-in';
      if (!signedIn && !onboarding) return '/onboarding';
      if (signedIn && state.matchedLocation == '/onboarding') return '/home';
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
        ),
      ),
      GoRoute(path: '/search', builder: (_, s) => SearchScreen(initialQuery: s.uri.queryParameters['q'])),
      GoRoute(path: '/assistant', builder: (_, _) => const AskScreen(assistantMode: true)),
      GoRoute(path: '/adhkar', builder: (_, _) => const AdhkarScreen()),
      GoRoute(path: '/adhkar/:id', builder: (_, s) => AdhkarDetailScreen(categoryId: int.parse(s.pathParameters['id']!))),
      GoRoute(path: '/goals', builder: (_, _) => const GoalsScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
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
