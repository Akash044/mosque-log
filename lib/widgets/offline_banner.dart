import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';

final _connectivityProvider =
    StreamProvider<List<ConnectivityResult>>((ref) {
  return Connectivity().onConnectivityChanged;
});

/// Thin banner shown at the top of the screen when the device has no
/// internet. Cloud Firestore keeps queueing writes locally either way; this
/// just makes the offline state visible so admins aren't anxious that an
/// entry might be lost.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final result = ref.watch(_connectivityProvider).valueOrNull;
    final offline = result != null &&
        (result.isEmpty || result.every((r) => r == ConnectivityResult.none));
    if (!offline) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        child: Row(
          children: [
            Icon(Icons.cloud_off,
                size: 14, color: scheme.onErrorContainer),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l.offlineBanner,
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontSize: 11.5,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
