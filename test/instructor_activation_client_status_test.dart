import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/utils/instructor_activation_client_status.dart';

void main() {
  test('prioriza activationClientStatus del backend', () {
    expect(
      instructorActivationClientStatus(
          {'activationClientStatus': 'documents_pending'}),
      'documents_pending',
    );
  });

  test('fallback active solo con publishable e isListed', () {
    expect(
      instructorActivationClientStatus({'publishable': true, 'isListed': true}),
      'active',
    );
    expect(
      instructorActivationClientStatus(
          {'publishable': true, 'isListed': false}),
      'blocked',
    );
  });

  test('null → blocked', () {
    expect(instructorActivationClientStatus(null), 'blocked');
  });
}
