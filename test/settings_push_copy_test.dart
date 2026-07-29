import 'package:flutter_test/flutter_test.dart';
import 'package:manejapp/screens/legal_document_screen.dart';

void main() {
  test('política de privacidad describe las notificaciones disponibles', () {
    final doc = LegalDocumentScreen.privacy();
    final notifications = doc.sections.firstWhere(
      (s) => s.heading == '5. Notificaciones',
    );
    final text = notifications.paragraphs.join(' ');
    expect(text, contains('notificaciones push'));
    expect(text, contains('aprobación de documentación'));
    expect(text, isNot(contains('próximamente')));
  });
}
