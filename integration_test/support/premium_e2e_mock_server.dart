import 'dart:convert';
import 'dart:io';

import 'package:manejapp/services/config_service.dart';

/// Mock HTTP mínimo para integration_test de reservas premium (mismo proceso que `flutter test`).
///
/// Correr con host loopback:
/// `flutter test integration_test/premium_reservations_e2e_test.dart -d macos`
///
/// En simulador iOS/Android, `127.0.0.1` apunta al dispositivo: ahí conviene backend real o túnel.
class PremiumE2eMockServer {
  PremiumE2eMockServer._(this._server);

  final HttpServer _server;

  /// Tras cancelar en flujo alumno, la lista upcoming queda vacía.
  bool studentUpcomingEmpty = false;
  bool studentDetailCancelled = false;

  /// Si es true, `GET /messages/conversations` responde 500 (para E2E error + reintento).
  bool conversationsRespond500 = false;

  int get port => _server.port;
  String get baseUrl => 'http://127.0.0.1:$port';

  static Future<PremiumE2eMockServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final mock = PremiumE2eMockServer._(server);
    server.listen(mock._onRequest);
    ConfigService.setIntegrationTestBaseUrl(mock.baseUrl);
    return mock;
  }

  Future<void> stop() async {
    ConfigService.setIntegrationTestBaseUrl(null);
    await _server.close(force: true);
  }

  Future<void> _onRequest(HttpRequest request) async {
    final path = request.uri.path;
    final method = request.method;

    try {
      if (method == 'GET' && path == '/api/v1/config') {
        await _json(request, {
          'googleClientId': null,
          'baseUrl': baseUrl,
        });
        return;
      }

      if (method == 'GET' && path == '/api/v1/instructors') {
        await _raw(request, '[]');
        return;
      }

      if (method == 'GET' && path == '/api/v1/auth/me') {
        await _json(request, {'id': 7, 'email': 'e2e@test.com'});
        return;
      }

      if (method == 'GET' && path == '/api/v1/users/7') {
        await _json(request, _e2eStudentProfileComplete());
        return;
      }

      if (method == 'GET' && path == '/api/v1/messages/conversations') {
        if (conversationsRespond500) {
          await _text(request, 500, 'mock: conversations unavailable');
          return;
        }
        await _json(request, {'success': true, 'data': <dynamic>[]});
        return;
      }

      if (method == 'GET' && path == '/api/v1/messages/unread-count') {
        await _json(request, {
          'success': true,
          'data': {'unreadCount': 0},
        });
        return;
      }

      /// Listado genérico de clases (p. ej. [StudentPaymentsScreen] vía [ApiService.getDrivingClasses]).
      if (method == 'GET' && path == '/api/v1/classes') {
        await _raw(request, '[${_e2eDrivingClassForPayments()}]');
        return;
      }

      /// Envelope como backend real ([ResponseFormatter]).
      if (method == 'GET' && path == '/api/v1/payments') {
        await _json(request, {
          'success': true,
          'data': [_e2ePaymentForClass501()],
        });
        return;
      }

      if (method == 'GET' && path == '/api/v1/classes/student/upcoming') {
        if (studentUpcomingEmpty) {
          await _raw(request, '[]');
        } else {
          await _raw(request, '[${_studentPremiumJson(1001)}]');
        }
        return;
      }

      if (method == 'GET' && path == '/api/v1/classes/student/history') {
        await _raw(request, '[]');
        return;
      }

      if (method == 'GET' && path == '/api/v1/classes/student/1001') {
        final raw = studentDetailCancelled
            ? _studentCancelledDetailJson(1001)
            : _studentPremiumJson(1001);
        await _json(
          request,
          jsonDecode(raw) as Map<String, dynamic>,
        );
        return;
      }

      if (method == 'PATCH' && path == '/api/v1/classes/1001/cancel') {
        studentUpcomingEmpty = true;
        studentDetailCancelled = true;
        await _json(request, {'ok': true});
        return;
      }

      if (method == 'GET' && path == '/api/v1/classes/instructor/upcoming') {
        await _raw(request, '[${_instructorPremiumJson(2001)}]');
        return;
      }

      if (method == 'GET' && path == '/api/v1/classes/instructor/history') {
        await _raw(request, '[]');
        return;
      }

      if (method == 'GET' && path == '/api/v1/classes/instructor/2001') {
        await _json(
          request,
          jsonDecode(_instructorPremiumJson(2001)) as Map<String, dynamic>,
        );
        return;
      }

      await _text(request, 404, 'not found: $method $path');
    } catch (e, st) {
      await _text(request, 500, '$e\n$st');
    }
  }

  Future<void> _json(HttpRequest request, Object body) async {
    request.response.statusCode = 200;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode(body));
    await request.response.close();
  }

  Future<void> _raw(HttpRequest request, String body) async {
    request.response.statusCode = 200;
    request.response.headers.contentType = ContentType.json;
    request.response.write(body);
    await request.response.close();
  }

  Future<void> _text(HttpRequest request, int code, String msg) async {
    request.response.statusCode = code;
    request.response.headers.contentType = ContentType.text;
    request.response.write(msg);
    await request.response.close();
  }
}

String _e2eDrivingClassForPayments() {
  return '{"id":501,"instructorId":1,"studentId":2,"date":"2099-08-01T10:00:00.000Z","time":"10:00","duration":60,"status":"CONFIRMED","createdAt":"2099-01-01T10:00:00.000Z","updatedAt":"2099-01-01T10:00:00.000Z"}';
}

Map<String, dynamic> _e2ePaymentForClass501() {
  return {
    'id': 9001,
    'drivingClassId': 501,
    'amount': 2500.0,
    'paymentMethod': 'mercadopago',
    'status': 'paid',
    'createdAt': '2099-01-02T10:00:00.000Z',
    'updatedAt': '2099-01-02T10:00:00.000Z',
  };
}

String _studentPremiumJson(int id) {
  return '''
{"id":$id,"status":"CONFIRMED","paymentStatus":"paid","slotStatus":"BOOKED","canCancel":true,"canReschedule":false,"cancelDeadline":"2099-12-31T22:00:00.000Z","rescheduleDeadline":"2099-12-31T20:00:00.000Z","nextRecommendedAction":"VIEW_CLASS_DETAILS","whatsappContact":{"enabled":true,"counterpartName":"Ana Pérez","phoneNumber":"+5491122334455","launchUrl":"https://wa.me/5491122334455?text=Hola%20Ana%20P%C3%A9rez.%20Acabo%20de%20reservar%20una%20clase%20con%20vos%20a%20trav%C3%A9s%20de%20ManejApp!","unavailableReason":null},"policySummary":{"cancelWindowHours":6,"rescheduleWindowHours":12,"text":"Cancelación permitida hasta 6h antes. Reprogramación hasta 12h antes (próximamente)."},"priceSummary":{"amount":5000,"currency":"ARS","hourlyRate":2500,"estimatedTotalLabel":"ARS 5.000"},"durationMinutes":60,"startsAt":"2099-06-15T14:00:00.000Z","endsAt":"2099-06-15T15:00:00.000Z","instructorSnapshot":{"id":1,"name":"Ana","surname":"Pérez","hourlyRate":2500,"bio":null,"addressText":null,"lat":null,"lng":null},"studentSnapshot":{"id":2,"name":"Luis","surname":"Gómez","experienceLevel":3},"location":{"addressText":null,"lat":null,"lng":null,"zoneLabel":"Palermo"},"legacy":{"instructorId":1,"studentId":2,"date":"2099-06-15T14:00:00.000Z","duration":60,"amount":5000,"currency":"ARS"}}
'''
      .trim()
      .replaceAll('\n', '');
}

String _studentCancelledDetailJson(int id) {
  return '''
{"id":$id,"status":"CANCELLED","paymentStatus":"paid","slotStatus":"BOOKED","canCancel":false,"canReschedule":false,"cancelDeadline":"2099-12-31T22:00:00.000Z","rescheduleDeadline":"2099-12-31T20:00:00.000Z","nextRecommendedAction":"BOOK_ANOTHER_CLASS","policySummary":{"cancelWindowHours":6,"rescheduleWindowHours":12,"text":"Cancelación permitida hasta 6h antes. Reprogramación hasta 12h antes (próximamente)."},"priceSummary":{"amount":5000,"currency":"ARS","hourlyRate":2500,"estimatedTotalLabel":"ARS 5.000"},"durationMinutes":60,"startsAt":"2099-06-15T14:00:00.000Z","endsAt":"2099-06-15T15:00:00.000Z","instructorSnapshot":{"id":1,"name":"Ana","surname":"Pérez","hourlyRate":2500,"bio":null,"addressText":null,"lat":null,"lng":null},"studentSnapshot":{"id":2,"name":"Luis","surname":"Gómez","experienceLevel":3},"location":{"addressText":null,"lat":null,"lng":null,"zoneLabel":"Palermo"},"legacy":{"instructorId":1,"studentId":2,"date":"2099-06-15T14:00:00.000Z","duration":60,"amount":5000,"currency":"ARS"}}
'''
      .trim()
      .replaceAll('\n', '');
}

String _instructorPremiumJson(int id) {
  return '''
{"id":$id,"status":"CONFIRMED","paymentStatus":"paid","slotStatus":"BOOKED","canCancel":true,"canReschedule":false,"cancelDeadline":"2099-12-31T22:00:00.000Z","rescheduleDeadline":"2099-12-31T20:00:00.000Z","nextRecommendedAction":"VIEW_CLASS_DETAILS","whatsappContact":{"enabled":true,"counterpartName":"Luis Gómez","phoneNumber":"+5491166677788","launchUrl":"https://wa.me/5491166677788?text=Hola%20Luis%20G%C3%B3mez","unavailableReason":null},"policySummary":{"cancelWindowHours":6,"rescheduleWindowHours":12,"text":"Cancelación permitida hasta 6h antes. Reprogramación hasta 12h antes (próximamente)."},"priceSummary":{"amount":5000,"currency":"ARS","hourlyRate":2500,"estimatedTotalLabel":"ARS 5.000"},"durationMinutes":60,"startsAt":"2099-06-15T14:00:00.000Z","endsAt":"2099-06-15T15:00:00.000Z","instructorSnapshot":{"id":1,"name":"Ana","surname":"Pérez","hourlyRate":2500,"bio":null,"addressText":null,"lat":null,"lng":null},"studentSnapshot":{"id":2,"name":"Luis","surname":"Gómez","experienceLevel":3},"location":{"addressText":null,"lat":null,"lng":null,"zoneLabel":"Palermo"},"legacy":{"instructorId":1,"studentId":2,"date":"2099-06-15T14:00:00.000Z","duration":60,"amount":5000,"currency":"ARS"}}
'''
      .trim()
      .replaceAll('\n', '');
}

/// Perfil alumno completo al 100% para que el home muestre el CTA "Todavía no reservaste" (sin wizard de perfil).
Map<String, dynamic> _e2eStudentProfileComplete() {
  return {
    'id': 7,
    'role': 'STUDENT',
    'email': 'e2e@test.com',
    'name': 'E2E',
    'surname': 'Alumno',
    'phoneNumber': '+5491122334455',
    'location': 'CABA',
    'profileImage': 'https://example.com/e2e-avatar.png',
    'student': {'experienceLevel': 3},
  };
}
