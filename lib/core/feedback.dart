import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

// Persistent players so we don't allocate one on every save/delete. Each is
// configured to stop (not loop) and release native buffers on completion.
final AudioPlayer _addPlayer = AudioPlayer()
  ..setReleaseMode(ReleaseMode.stop)
  ..setPlayerMode(PlayerMode.lowLatency);
final AudioPlayer _deletePlayer = AudioPlayer()
  ..setReleaseMode(ReleaseMode.stop)
  ..setPlayerMode(PlayerMode.lowLatency);

/// Plays a short bundled chime when an entry is added. Haptic always fires
/// (it's a tactile cue and doesn't disturb anyone); the click only plays
/// when the user has sounds enabled in settings.
void playEntryAdded(WidgetRef ref) {
  HapticFeedback.lightImpact();
  if (ref.read(settingsProvider).soundsEnabled) {
    _addPlayer.stop();
    _addPlayer.play(AssetSource('sounds/add.wav'));
  }
}

/// Distinguishable cue for deletes — lower-pitched tone + medium haptic.
void playEntryDeleted(WidgetRef ref) {
  HapticFeedback.mediumImpact();
  if (ref.read(settingsProvider).soundsEnabled) {
    _deletePlayer.stop();
    _deletePlayer.play(AssetSource('sounds/delete.wav'));
  }
}
