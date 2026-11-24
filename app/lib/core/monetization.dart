import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';
import 'analytics.dart';
import 'api.dart';
import 'providers.dart';
import 'widgets.dart';

/// "Show value first, ask for money second" (docs/subscription-growth-audit.md §7-8).
///
/// Automatic Premium surfaces (offer cards, banners, the paywall opened by the app rather
/// than by the user) only appear when:
///   * the user has had real value on at least [valueDaysRequired] different days
///     (a recitation check, an AI hifz test or a completed review), and
///   * at most once a day, three times a week and never twice in one app session, and
///   * not within 7 days after the user said "not now" twice in a row.
///
/// Limit sheets are not gated: a user who used up a weekly limit has had the value, and
/// the sheet has to explain the limit anyway. Settings / Profile entries are user-initiated.
class PaywallGate {
  PaywallGate(this._prefs, {DateTime Function()? clock}) : _now = clock ?? DateTime.now;

  static const valueDaysRequired = 3;
  static const maxPerDay = 1;
  static const maxPerWeek = 3;
  static const snoozeAfterDismissals = 2;
  static const snoozeDays = 7;

  static const _kShown = 'paywall_shown_at';
  static const _kDismissStreak = 'paywall_dismiss_streak';
  static const _kSnoozed = 'paywall_snoozed_until';
  static const _kOnce = 'paywall_once_';

  /// One automatic offer per app launch (static: survives screen rebuilds, resets on restart).
  static bool _shownThisSession = false;
  static void resetSession() => _shownThisSession = false;

  final SharedPreferences _prefs;
  final DateTime Function() _now;

  List<DateTime> get _shown =>
      (_prefs.getStringList(_kShown) ?? const []).map(DateTime.tryParse).whereType<DateTime>().toList();

  bool valueGatePassed(int valueDays) => valueDays >= valueDaysRequired;

  /// Whether the app may show an offer on its own right now.
  bool canAutoShow({required int valueDays, required bool premium}) {
    if (premium || !valueGatePassed(valueDays) || _shownThisSession) return false;
    final now = _now();
    final snoozed = DateTime.tryParse(_prefs.getString(_kSnoozed) ?? '');
    if (snoozed != null && now.isBefore(snoozed)) return false;
    final shown = _shown;
    if (shown.where((t) => now.difference(t) < const Duration(days: 1)).length >= maxPerDay) return false;
    if (shown.where((t) => now.difference(t) < const Duration(days: 7)).length >= maxPerWeek) return false;
    return true;
  }

  /// Some offers appear once per user (first weekly summary, 7-day streak, each milestone type).
  bool usedOnce(String key) => _prefs.getBool('$_kOnce$key') ?? false;
  Future<void> markOnce(String key) => _prefs.setBool('$_kOnce$key', true);

  Future<void> recordShown() async {
    _shownThisSession = true;
    final now = _now();
    final recent = _shown.where((t) => now.difference(t) < const Duration(days: 7)).toList()..add(now);
    await _prefs.setStringList(_kShown, recent.map((t) => t.toIso8601String()).toList());
  }

  /// "Not now" / closed without buying. Two in a row snooze automatic offers for a week.
  Future<void> recordDismissed() async {
    final streak = (_prefs.getInt(_kDismissStreak) ?? 0) + 1;
    if (streak >= snoozeAfterDismissals) {
      await _prefs.setString(_kSnoozed, _now().add(const Duration(days: snoozeDays)).toIso8601String());
      await _prefs.setInt(_kDismissStreak, 0);
    } else {
      await _prefs.setInt(_kDismissStreak, streak);
    }
  }

  Future<void> recordEngaged() => _prefs.setInt(_kDismissStreak, 0);
}

final paywallGateProvider = Provider<PaywallGate>((ref) => PaywallGate(ref.watch(sharedPrefsProvider)));

final weeklyQuotaProvider = FutureProvider.autoDispose<WeeklyQuota>((ref) {
  ref.watch(currentUserProvider);
  return ref.watch(userRepoProvider).weeklyQuota();
});

/// The user's main goal from onboarding: memorize | recite | read | understand.
String userIntent(WidgetRef ref) => ref.read(sharedPrefsProvider).getString('intent') ?? 'memorize';

/// "Friday" in the app language, falling back to the next Friday when the server sent no date.
String renewalDay(BuildContext context, DateTime? resetsAt) {
  var d = resetsAt?.toLocal();
  if (d == null) {
    final now = DateTime.now();
    final add = (DateTime.friday - now.weekday + 7) % 7;
    d = DateTime(now.year, now.month, now.day + (add == 0 ? 7 : add));
  }
  return DateFormat.EEEE(Localizations.localeOf(context).languageCode).format(d);
}

/// Opens the paywall if the gate allows it. Returns true when it was shown.
Future<bool> maybeShowOffer(BuildContext context, WidgetRef ref, String source, {required int valueDays}) async {
  final gate = ref.read(paywallGateProvider);
  final premium = ref.read(premiumProvider).value ?? false;
  if (!gate.canAutoShow(valueDays: valueDays, premium: premium)) return false;
  await gate.recordShown();
  if (context.mounted) await context.push('/paywall?source=$source');
  return true;
}

/// Bottom sheet for a weekly limit: what renews when, and an equal-weight Premium option.
/// [allowUpgrade] is false in sensitive moments (e.g. an Ask conversation about a crisis).
Future<void> showLimitSheet(BuildContext context, QuotaExceeded e, {bool allowUpgrade = true}) {
  Analytics.track(Events.quotaHit, {'feature': e.feature, 'kind': 'weekly_limit', 'limit': e.limit});
  final l10n = context.l10n;
  final day = renewalDay(context, e.resetsAt);
  final title = switch (e.feature) {
    'hifz' => l10n.limitTitleHifz(e.limit),
    'ask' => l10n.limitTitleAsk(e.limit),
    'search' => l10n.limitTitleSearch(e.limit),
    _ => l10n.limitTitleRecitation(e.limit),
  };
  final upgrade = allowUpgrade && !e.premium;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Icon(Icons.event_repeat, size: 40, color: Theme.of(sheet).colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: Theme.of(sheet).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(l10n.limitRenews(day), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(l10n.limitKeepsWorking, textAlign: TextAlign.center, style: Theme.of(sheet).textTheme.bodySmall),
          const SizedBox(height: 20),
          // Two buttons of equal weight: waiting is a real choice, not a dark pattern.
          Row(children: [
            Expanded(
              child: OutlinedButton(onPressed: () => Navigator.of(sheet).pop(), child: Text(l10n.limitWaitUntil(day))),
            ),
            if (upgrade) ...[
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(sheet).pop();
                    context.push('/paywall?source=limit_${e.feature}');
                  },
                  child: Text(l10n.tryPremiumFree),
                ),
              ),
            ],
          ]),
        ]),
      ),
    ),
  );
}

/// Pure "what should I do today" logic for the Home hero card (unit-tested).
enum NextAction { review, learnNew, startPlan, recite, read, done }

NextAction nextBestAction({
  required int hifzDue,
  required bool hasPlan,
  required int newAvailable,
  required int recitationsToday,
  required int reviewsToday,
  required String intent,
}) {
  if (hifzDue > 0) return NextAction.review;
  if (newAvailable > 0) return NextAction.learnNew;
  if (hasPlan && reviewsToday > 0) return NextAction.done;
  if (!hasPlan && intent == 'memorize') return NextAction.startPlan;
  if (recitationsToday == 0 && intent != 'read' && intent != 'understand') return NextAction.recite;
  return NextAction.read;
}

/// Juz Amma memorization order: An-Nas first, then backwards to An-Naba.
const juzAmmaOrder = [114, 113, 112, 111, 110, 109, 108, 107, 106, 105, 104, 103, 102, 101, 100, 99, 98, 97, 96, 95, 94,
  93, 92, 91, 90, 89, 88, 87, 86, 85, 84, 83, 82, 81, 80, 79, 78];

/// Surahs offered as "I already know" chips in onboarding (Al-Fatiha + Juz Amma + common ones).
const knownSurahChoices = [1, ...juzAmmaOrder, 67, 36, 18];

/// The first surah the user doesn't know yet, in the usual order (Al-Fatiha, then Juz Amma
/// from An-Nas backwards, then Al-Mulk). Null when they know all of them.
int? nextSurahToMemorize(Set<int> known) {
  for (final s in [1, ...juzAmmaOrder, 67]) {
    if (!known.contains(s)) return s;
  }
  return null;
}
