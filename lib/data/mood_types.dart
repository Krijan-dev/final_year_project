import "package:life_pattern_tracker/models/mood_type.dart";

abstract final class MoodTypes {
  static MoodType? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  static const List<MoodType> all = [
    MoodType(id: "great", label: "Great", emoji: "😁", defaultScore: 9),
    MoodType(id: "good", label: "Good", emoji: "😊", defaultScore: 8),
    MoodType(id: "calm", label: "Calm", emoji: "😌", defaultScore: 7),
    MoodType(id: "okay", label: "Okay", emoji: "🙂", defaultScore: 6),
    MoodType(id: "tired", label: "Tired", emoji: "😴", defaultScore: 5),
    MoodType(id: "stressed", label: "Stressed", emoji: "😰", defaultScore: 4),
    MoodType(id: "sad", label: "Sad", emoji: "😔", defaultScore: 3),
    MoodType(id: "angry", label: "Angry", emoji: "😠", defaultScore: 3),
  ];
}
