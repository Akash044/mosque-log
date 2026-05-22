import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

// One fresh player per playback. Reusing a long-lived AudioPlayer in
// non-lowLatency mode caused inconsistent replay on Redmi/MIUI — repeat
// calls to play() while the prior playback hadn't fully released its
// source were dropped. Creating per-call and disposing after completion
// is simpler and always reliable.

Future<void> _play(String asset) async {
  final player = AudioPlayer();
  player.onPlayerComplete.first.then((_) => player.dispose());
  try {
    await player.play(AssetSource(asset));
  } catch (e) {
    debugPrint('feedback audio failed for $asset: $e');
    await player.dispose();
  }
}

/// Plays a short bundled chime when an entry is added. Haptic always fires
/// (it's a tactile cue and doesn't disturb anyone); the click only plays
/// when the user has sounds enabled in settings.
void playEntryAdded(WidgetRef ref) {
  HapticFeedback.lightImpact();
  if (!ref.read(settingsProvider).soundsEnabled) return;
  _play('sounds/add.wav');
}

/// Distinguishable cue for deletes — lower-pitched tone + medium haptic.
void playEntryDeleted(WidgetRef ref) {
  HapticFeedback.mediumImpact();
  if (!ref.read(settingsProvider).soundsEnabled) return;
  _play('sounds/delete.wav');
}
