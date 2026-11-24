import 'package:posthog_flutter/posthog_flutter.dart';

import 'config.dart';

/// Product analytics event names. Keep in sync with docs/05-data.md.
abstract final class Events {
  static const appOpened = 'app_opened';
  static const onboardingStarted = 'onboarding_started';
  static const onboardingStepCompleted = 'onboarding_step_completed';
  static const onboardingCompleted = 'onboarding_completed';
  static const notificationPermissionResult = 'notification_permission_result';
  static const accountLinked = 'account_linked';
  static const quranSurahOpened = 'quran_surah_opened';
  static const quranAyahsRead = 'quran_ayahs_read';
  static const audioPlayed = 'audio_played';
  static const recitationStarted = 'recitation_started';
  static const recitationSubmitted = 'recitation_submitted';
  static const recitationResultViewed = 'recitation_result_viewed';
  static const hifzPlanCreated = 'hifz_plan_created';
  static const hifzReviewed = 'hifz_reviewed';
  static const searchPerformed = 'search_performed';
  static const askQuestion = 'ask_question';
  static const askReported = 'ask_reported';
  static const shareTapped = 'share_tapped';
  static const assistantMessage = 'assistant_message';
  static const dhikrCompleted = 'dhikr_completed';
  static const adhkarSetCompleted = 'adhkar_set_completed';
  static const prayerLogged = 'prayer_logged';
  static const goalUpdated = 'goal_updated';
  static const achievementUnlocked = 'achievement_unlocked';
  static const levelUp = 'level_up';
  static const quotaHit = 'quota_hit';
  static const paywallViewed = 'paywall_viewed';
  static const purchaseStarted = 'purchase_started';
  static const purchaseCompleted = 'purchase_completed';
  static const purchaseFailed = 'purchase_failed';
  static const purchaseRestored = 'purchase_restored';
  static const referralShared = 'referral_shared';
  static const referralApplied = 'referral_applied';
  static const accountDeleted = 'account_deleted';
  // Value-first funnel (docs/full-audit.md §16)
  static const onboardingIntent = 'onboarding_intent';
  static const paywallDismissed = 'paywall_dismissed';
  static const offerShown = 'offer_shown';
  static const valueGatePassed = 'value_gate_passed';
  static const weeklySummaryViewed = 'weekly_summary_viewed';
  static const milestoneReached = 'milestone_reached';
  static const trialReminderScheduled = 'trial_reminder_scheduled';
  static const weakWordsOpened = 'weak_words_opened';
  static const searchFallback = 'search_fallback';
}

class Analytics {
  static bool get _enabled => AppConfig.posthogKey.isNotEmpty;

  static Future<void> init() async {
    if (!_enabled) return;
    final config = PostHogConfig(AppConfig.posthogKey)
      ..host = AppConfig.posthogHost
      ..captureApplicationLifecycleEvents = true
      ..personProfiles = PostHogPersonProfiles.identifiedOnly;
    await Posthog().setup(config);
  }

  static Future<void> identify(String userId, {Map<String, Object>? props}) async {
    if (!_enabled) return;
    await Posthog().identify(userId: userId, userProperties: props);
  }

  static void track(String event, [Map<String, Object>? props]) {
    if (!_enabled) return;
    Posthog().capture(eventName: event, properties: props);
  }

  static Future<void> reset() async {
    if (!_enabled) return;
    await Posthog().reset();
  }
}
