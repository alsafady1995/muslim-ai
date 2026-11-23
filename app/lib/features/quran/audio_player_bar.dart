import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets.dart';
import 'audio_controller.dart';

class AudioPlayerBar extends ConsumerWidget {
  const AudioPlayerBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(audioProvider);
    if (s.ayahs.isEmpty) return const SizedBox.shrink();
    final c = ref.read(audioProvider.notifier);
    final current = s.ayahs.where((a) => a.id == s.currentAyahId).firstOrNull;
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            IconButton(icon: const Icon(Icons.close), onPressed: c.stop),
            Expanded(
              child: Text(current == null ? '' : context.l10n.ayahN(current.verseKey),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            PopupMenuButton<double>(
              tooltip: context.l10n.speed,
              initialValue: s.speed,
              onSelected: c.setSpeed,
              itemBuilder: (_) => [0.5, 0.75, 1.0, 1.25, 1.5]
                  .map((v) => PopupMenuItem(value: v, child: Text('${v}x')))
                  .toList(),
              child: Padding(padding: const EdgeInsets.all(8), child: Text('${s.speed}x')),
            ),
            IconButton(
              icon: Icon(Icons.repeat, color: s.loop ? Theme.of(context).colorScheme.primary : null),
              tooltip: context.l10n.repeatRange,
              onPressed: () => c.setLoop(!s.loop),
            ),
            IconButton(icon: const Icon(Icons.skip_previous), onPressed: c.previous),
            IconButton.filled(icon: Icon(s.playing ? Icons.pause : Icons.play_arrow), onPressed: c.toggle),
            IconButton(icon: const Icon(Icons.skip_next), onPressed: c.next),
          ]),
        ),
      ),
    );
  }
}
