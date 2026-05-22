import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';

/// Plays a short feedback cue when an entry is added. Reads the
/// soundsEnabled setting and skips audio when disabled. Haptic still fires
/// either way — it's a tactile confirmation and doesn't disturb anyone.
void playEntryAdded(WidgetRef ref) {
  HapticFeedback.lightImpact();
  if (ref.read(settingsProvider).soundsEnabled) {
    SystemSound.play(SystemSoundType.click);
  }
}

/// Distinguishable cue for deletes — heavier vibration so it feels different
/// from an add even when sounds are muted.
void playEntryDeleted(WidgetRef ref) {
  HapticFeedback.mediumImpact();
  if (ref.read(settingsProvider).soundsEnabled) {
    SystemSound.play(SystemSoundType.click);
  }
}
