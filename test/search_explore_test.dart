import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/navigation/explore_intent.dart';

void main() {
  group('ExploreIntent', () {
    test('fromArguments null → null', () {
      expect(ExploreIntent.fromArguments(null), isNull);
    });

    test('fromArguments Map aplica flags y query', () {
      final intent = ExploreIntent.fromArguments(<String, dynamic>{
        'preferUserAnchor': false,
        'transmission': 'MANUAL',
        'availableToday': true,
        'initialInstructorNameQuery': 'Ana',
        'focusZoneSearch': true,
      });
      expect(intent, isNotNull);
      expect(intent!.preferUserAnchor, isFalse);
      expect(intent.transmission, 'MANUAL');
      expect(intent.availableToday, isTrue);
      expect(intent.initialInstructorNameQuery, 'Ana');
      expect(intent.focusZoneSearch, isTrue);
    });

    test('fromArguments ExploreIntent pasa por identidad', () {
      const original = ExploreIntent(preferUserAnchor: false);
      expect(ExploreIntent.fromArguments(original), same(original));
    });
  });
}
