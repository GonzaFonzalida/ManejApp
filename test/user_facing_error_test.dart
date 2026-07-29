import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/utils/user_facing_error.dart';

void main() {
  test('humanizeApiError redactea Exception:', () {
    expect(
      humanizeApiError(Exception('falló')),
      'falló',
    );
  });

  test('humanizeApiError detecta red', () {
    expect(
      humanizeApiError('SocketException: failed'),
      contains('conectar'),
    );
  });
}
