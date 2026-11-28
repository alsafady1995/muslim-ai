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

  /// Off unless the user (or onboarding) actually scheduled it. It used to default to on,
  /// so the switches claimed reminders that were never scheduled.
  bool _reminder(String key) => _prefs.getBool('reminder_$key') ?? false;

  TimeOfDay _time(String key, TimeOfDay fallback) {
    final parts = (_prefs.getString('reminder_${key}_time') ?? '').split(':');
    final h = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final m = parts.length == 2 ? int.tryParse(parts[1]) : null;
    return h == null || m == null ? fallback : TimeOfDay(hour: h, minute: m);
  }

  Future<void> _setReminder(String key, bool on, int id, String title, String body, TimeOfDay at) async {
    if (on) {
      final granted = await Reminders.requestPermission();
      Analytics.track(Events.notificationPermissionResult, {'granted': granted});
      if (!granted) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.notificationsBlocked)));
        return;
      }
      await Reminders.scheduleDaily(id, title, body, at.hour, at.minute);
      await _prefs.setString('reminder_${key}_time',
          '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}');
    } else {
      await Reminders.cancel(id);
    }
    await _prefs.setBool('reminder_$key', on);
    if (mounted) setState(() {});
  }

  Widget _reminderTile(String key, String label, int id, String title, String body, TimeOfDay fallback) {
    final at = _time(key, fallback);
    return ListTile(
      title: Text(label),
      subtitle: Text(at.format(context)),
      // Tap the row to change the time; the switch turns it on or off.
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: at);
        if (t != null) await _setReminder(key, true, id, title, body, t);
      },
      trailing: Switch(value: _reminder(key), onChanged: (v) => _setReminder(key, v, id, title, body, at)),
    );
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
    try {
      await ref.read(edgeApiProvider).call('delete-account', {});
    } catch (_) {
      // Never sign the user out (and lose their guest data) when the delete did not happen.
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      return;
    }
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
                  // All reciters are free (docs/subscription-growth-audit.md): no lock, no paywall.
                  trailing: prefs['reciter_id'] == r.id ? const Icon(Icons.check) : null,
                  onTap: () {
                    Navigator.pop(c);
                    ref.read(prefsProvider.notifier).setValue('reciter_id', r.id);
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
        _reminderTile('morning', l10n.morningAdhkar, Reminders.morningAdhkar, l10n.reminderMorningTitle, l10n.reminderMorningBody,
            const TimeOfDay(hour: 6, minute: 30)),
        _reminderTile('evening', l10n.eveningAdhkar, Reminders.eveningAdhkar, l10n.reminderEveningTitle, l10n.reminderEveningBody,
            const TimeOfDay(hour: 17, minute: 30)),
        _reminderTile('hifz', l10n.hifzReview, Reminders.hifzReview, l10n.reminderHifzTitle, l10n.reminderHifzBody,
            const TimeOfDay(hour: 20, minute: 0)),
        _reminderTile('streak', l10n.streakReminder, Reminders.streakSaver, l10n.reminderStreakTitle, l10n.reminderStreakBody,
            const TimeOfDay(hour: 21, minute: 0)),
        ],
        SectionTitle(l10n.subscription),
        if (premium)
          ListTile(
            leading: const Icon(Icons.workspace_premium),
            title: Text(l10n.manageSubscription),
            onTap: payments.manageSubscriptionsUrl == null
                ? null
                : () => launchUrl(payments.manageSubscriptionsUrl!, mode: LaunchMode.externalApplication),
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
        if (AppConfig.benchmarkRecorder && !AppConfig.demoMode)
          ListTile(
            leading: const Icon(Icons.graphic_eq),
            title: Text(l10n.benchTitle),
            onTap: () => context.push('/benchmark'),
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
