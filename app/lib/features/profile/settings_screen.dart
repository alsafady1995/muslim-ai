import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/analytics.dart';
import '../../core/config.dart';
import '../../core/notifications.dart';
import '../../core/providers.dart';
import '../../core/widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  SharedPreferences get _prefs => ref.read(sharedPrefsProvider);

  bool _reminder(String key) => _prefs.getBool('reminder_$key') ?? true;

  Future<void> _setReminder(String key, bool on, int id, String title, String body, int h, int m) async {
    await _prefs.setBool('reminder_$key', on);
    if (on) {
      final granted = await Reminders.requestPermission();
      Analytics.track(Events.notificationPermissionResult, {'granted': granted});
      if (granted) await Reminders.scheduleDaily(id, title, body, h, m);
    } else {
      await Reminders.cancel(id);
    }
    setState(() {});
  }

  Future<void> _deleteAccount() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Text(l10n.deleteAccountWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l10n.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(c, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(edgeApiProvider).call('delete-account', {});
    Analytics.track(Events.accountDeleted);
    await _signOut();
  }

  Future<void> _signOut() async {
    await ref.read(paymentProvider).logOut();
    await Analytics.reset();
    await ref.read(supabaseProvider).auth.signOut();
    if (mounted) context.go('/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = ref.watch(localeProvider);
    final prefs = ref.watch(prefsProvider);
    final reciters = ref.watch(recitersProvider).value ?? [];
    final premium = ref.watch(premiumProvider).value ?? false;
    final user = ref.watch(currentUserProvider);
    final payments = ref.read(paymentProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(children: [
        SectionTitle(l10n.general),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(l10n.language),
          trailing: DropdownButton<String>(
            value: locale.languageCode,
            underline: const SizedBox.shrink(),
            items: const [DropdownMenuItem(value: 'ar', child: Text('العربية')), DropdownMenuItem(value: 'en', child: Text('English'))],
            onChanged: (v) => ref.read(localeProvider.notifier).set(Locale(v!)),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.record_voice_over_outlined),
          title: Text(l10n.reciter),
          subtitle: Text(reciters.where((r) => r.id == prefs['reciter_id']).map((r) => context.isArabic ? r.nameAr : r.nameEn).firstOrNull ?? ''),
          onTap: () => showModalBottomSheet(
            context: context,
            showDragHandle: true,
            builder: (c) => ListView(shrinkWrap: true, children: [
              for (final r in reciters)
                ListTile(
                  title: Text(context.isArabic ? r.nameAr : r.nameEn),
                  trailing: r.isPremium && !premium ? const Icon(Icons.lock_outline) : (prefs['reciter_id'] == r.id ? const Icon(Icons.check) : null),
                  onTap: () {
                    Navigator.pop(c);
                    if (r.isPremium && !premium) {
                      context.push('/paywall?source=reciter');
                    } else {
                      ref.read(prefsProvider.notifier).setValue('reciter_id', r.id);
                    }
                  },
                ),
            ]),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.translate),
          title: Text(l10n.showTranslation),
          value: prefs['show_translation'] as bool? ?? true,
          onChanged: (v) => ref.read(prefsProvider.notifier).setValue('show_translation', v),
        ),
        SectionTitle(l10n.reminders),
        // Local notifications have no web implementation (web preview build).
        if (kIsWeb)
          ListTile(
            leading: const Icon(Icons.notifications_off_outlined),
            title: Text(context.isArabic ? 'التذكيرات متاحة في تطبيق الجوال فقط' : 'Reminders are available in the mobile app only'),
          )
        else ...[
        SwitchListTile(
          title: Text(l10n.morningAdhkar),
          subtitle: const Text('06:30'),
          value: _reminder('morning'),
          onChanged: (v) => _setReminder('morning', v, Reminders.morningAdhkar, l10n.reminderMorningTitle, l10n.reminderMorningBody, 6, 30),
        ),
        SwitchListTile(
          title: Text(l10n.eveningAdhkar),
          subtitle: const Text('17:30'),
          value: _reminder('evening'),
          onChanged: (v) => _setReminder('evening', v, Reminders.eveningAdhkar, l10n.reminderEveningTitle, l10n.reminderEveningBody, 17, 30),
        ),
        SwitchListTile(
          title: Text(l10n.hifzReview),
          subtitle: const Text('20:00'),
          value: _reminder('hifz'),
          onChanged: (v) => _setReminder('hifz', v, Reminders.hifzReview, l10n.reminderHifzTitle, l10n.reminderHifzBody, 20, 0),
        ),
        SwitchListTile(
          title: Text(l10n.streakReminder),
          subtitle: const Text('21:00'),
          value: _reminder('streak'),
          onChanged: (v) => _setReminder('streak', v, Reminders.streakSaver, l10n.reminderStreakTitle, l10n.reminderStreakBody, 21, 0),
        ),
        ],
        SectionTitle(l10n.subscription),
        if (premium)
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: Text(l10n.manageSubscription),
            onTap: () => launchUrl(payments.manageSubscriptionsUrl!, mode: LaunchMode.externalApplication),
          )
        else
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: Text(l10n.goPremium),
            onTap: () => context.push('/paywall?source=settings'),
          ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: Text(l10n.restorePurchases),
          onTap: () async {
            final ok = await payments.restore();
            if (ok) Analytics.track(Events.purchaseRestored);
            ref.invalidate(premiumProvider);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok ? l10n.restored : l10n.nothingToRestore)));
            }
          },
        ),
        SectionTitle(l10n.account),
        if (user?.isAnonymous == true)
          ListTile(leading: const Icon(Icons.cloud_upload_outlined), title: Text(l10n.saveProgress), onTap: () => context.push('/sign-in?link=1')),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(l10n.privacyPolicy),
          onTap: () => launchUrl(Uri.parse(AppConfig.privacyUrl)),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: Text(l10n.terms),
          onTap: () => launchUrl(Uri.parse(AppConfig.termsUrl)),
        ),
        if (user?.isAnonymous != true) ListTile(leading: const Icon(Icons.logout), title: Text(l10n.signOut), onTap: _signOut),
        ListTile(
          leading: Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
          title: Text(l10n.deleteAccount, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          onTap: _deleteAccount,
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}
