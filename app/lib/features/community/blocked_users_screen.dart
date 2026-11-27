import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets.dart';
import 'community_common.dart';

final _blocksProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) => ref.watch(communityRepoProvider).blocks());

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final blocks = ref.watch(_blocksProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockedUsers)),
      body: blocks.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(_blocksProvider)),
        data: (list) => list.isEmpty
            ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.blockedUsersEmpty, textAlign: TextAlign.center)))
            : ListView(children: [
                for (final b in list)
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: Text((b['display_name'] as String?) ?? l10n.formerMember),
                    trailing: TextButton(
                      onPressed: () async {
                        try {
                          await ref.read(communityRepoProvider).unblock(b['user_id'] as String);
                          ref.invalidate(_blocksProvider);
                        } catch (e) {
                          if (context.mounted) showCommunityError(context, e);
                        }
                      },
                      child: Text(l10n.unblock),
                    ),
                  ),
              ]),
      ),
    );
  }
}
