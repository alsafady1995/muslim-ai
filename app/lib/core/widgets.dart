import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});
  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry});
  final Object error;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off, size: 48),
            const SizedBox(height: 12),
            Text(context.l10n.errorGeneric, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton(onPressed: onRetry, child: Text(context.l10n.retry)),
            ],
          ]),
        ),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
        child: Row(children: [
          Expanded(child: Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          if (trailing != null) trailing!,
        ]),
      );
}

class ProgressRing extends StatelessWidget {
  const ProgressRing({super.key, required this.value, required this.child, this.size = 64, this.color});
  final double value;
  final Widget child;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(alignment: Alignment.center, children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: value.clamp(0, 1),
              strokeWidth: 6,
              strokeCap: StrokeCap.round,
              color: color,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          child,
        ]),
      );
}

/// Snackbar celebrating XP / achievements after a gamified action.
void showXpToast(BuildContext context, int xp, {List<Map<String, dynamic>> achievements = const []}) {
  if (xp <= 0 && achievements.isEmpty) return;
  final l10n = context.l10n;
  final names = achievements.map((a) => context.isArabic ? a['name_ar'] : a['name_en']).join(', ');
  // Shown near the top so it never covers the action buttons at the bottom of a
  // screen (e.g. the hifz grade buttons), which would swallow the next tap.
  final height = MediaQuery.sizeOf(context).height;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: const Duration(milliseconds: 2500),
    margin: EdgeInsets.fromLTRB(16, 0, 16, (height - 170).clamp(16, double.infinity)),
    content: Text(achievements.isEmpty ? l10n.xpEarned(xp) : '${l10n.xpEarned(xp)} · ${l10n.achievementUnlocked(names)}'),
  ));
}
