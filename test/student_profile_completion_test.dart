import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/utils/student_profile_completion.dart';

void main() {
  group('StudentProfileCompletion', () {
    test('shouldSkipProgressiveOnboarding when phone and location filled', () {
      expect(
        StudentProfileCompletion.shouldSkipProgressiveOnboarding({
          'phoneNumber': '+5491122334455',
          'location': 'Palermo',
        }),
        isTrue,
      );
      expect(
        StudentProfileCompletion.shouldSkipProgressiveOnboarding({
          'phoneNumber': '123',
          'location': 'Palermo',
        }),
        isFalse,
      );
    });

    test('completionPercent four quadrants', () {
      expect(
        StudentProfileCompletion.completionPercent({
          'student': {'experienceLevel': 1},
          'phoneNumber': '',
          'location': '',
        }),
        25,
      );
      expect(
        StudentProfileCompletion.completionPercent({
          'experienceLevel': 2,
          'phoneNumber': '+5491122334455',
          'location': 'CABA',
          'profileImage': '/uploads/x.jpg',
        }),
        100,
      );
    });

    test('promptsFor orders missing fields', () {
      final p = StudentProfileCompletion.promptsFor({
        'student': {'experienceLevel': 1},
        'phoneNumber': '',
        'location': '',
        'profileImage': null,
      });
      expect(p.isNotEmpty, isTrue);
      expect(p.first.id, 'phone');
    });
  });
}
