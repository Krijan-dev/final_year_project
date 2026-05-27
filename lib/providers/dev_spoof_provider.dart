import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:life_pattern_tracker/utils/dev_spoof.dart";

/// In-app setting for test (spoof) data level.
final devSpoofLevelProvider = StateProvider<DevSpoofLevel>((ref) {
  return DevSpoof.level;
});

