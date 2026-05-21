import "package:flutter_test/flutter_test.dart";
import "package:life_pattern_tracker/utils/crisis_support.dart";

void main() {
  group("CrisisSupport.isCrisisRelated", () {
    test("detects suicide-related phrases", () {
      expect(CrisisSupport.isCrisisRelated("I want to die"), isTrue);
      expect(CrisisSupport.isCrisisRelated("thinking about suicide"), isTrue);
      expect(CrisisSupport.isCrisisRelated("committing suicide tonight"), isTrue);
      expect(CrisisSupport.isCrisisRelated("trying to die"), isTrue);
      expect(CrisisSupport.isCrisisRelated("I might kill myself"), isTrue);
      expect(CrisisSupport.isCrisisRelated("self harm"), isTrue);
    });

    test("ignores normal wellness chat", () {
      expect(CrisisSupport.isCrisisRelated("How is my focus today?"), isFalse);
      expect(CrisisSupport.isCrisisRelated("Tips to reduce screen time"), isFalse);
      expect(CrisisSupport.isCrisisRelated(""), isFalse);
    });
  });
}
