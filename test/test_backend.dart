// Script de prueba para verificar el backend
// Ejecuta: dart test_backend.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

void main() async {
  debugPrint('=== PRUEBA DE BACKEND ===\n');
  
  // Cambia estos valores por los tuyos
  final userId = 'TU_USER_ID';
  final token = 'TU_TOKEN';
  final instructorId = 'TU_INSTRUCTOR_ID';
  
  debugPrint('1. Probando GET /users/$userId');
  final userResponse = await HttpClient()
      .getUrl(Uri.parse('http://192.168.0.3:3000/api/v1/users/$userId'))
      .then((req) {
        req.headers.add('Authorization', 'Bearer $token');
        return req.close();
      })
      .then((res) => res.transform(utf8.decoder).join());
  
  debugPrint('Respuesta: $userResponse');
  final userData = jsonDecode(userResponse);
  debugPrint('¿Tiene profileImage? ${userData['profileImage'] != null}');
  debugPrint('¿Tiene hourlyRate? ${userData['hourlyRate'] != null}\n');
  
  debugPrint('2. Probando GET /instructors');
  final instructorsResponse = await HttpClient()
      .getUrl(Uri.parse('http://192.168.0.3:3000/api/v1/instructors'))
      .then((req) {
        req.headers.add('Authorization', 'Bearer $token');
        return req.close();
      })
      .then((res) => res.transform(utf8.decoder).join());
  
  final instructors = jsonDecode(instructorsResponse) as List;
  final myInstructor = instructors.firstWhere((i) => i['id'].toString() == instructorId);
  debugPrint('Mi instructor: $myInstructor');
  debugPrint('¿Tiene description? ${myInstructor['description'] != null}\n');
  
  debugPrint('3. Probando PUT /instructors/$instructorId con description');
  final updateData = {'description': 'TEST DESDE DART - ${DateTime.now()}'};
  final updateResponse = await HttpClient()
      .putUrl(Uri.parse('http://192.168.0.3:3000/api/v1/instructors/$instructorId'))
      .then((req) {
        req.headers.add('Authorization', 'Bearer $token');
        req.headers.add('Content-Type', 'application/json');
        req.write(jsonEncode(updateData));
        return req.close();
      })
      .then((res) => res.transform(utf8.decoder).join());
  
  debugPrint('Respuesta: $updateResponse\n');
  
  debugPrint('4. Verificando si se guardó');
  final verifyResponse = await HttpClient()
      .getUrl(Uri.parse('http://192.168.0.3:3000/api/v1/instructors'))
      .then((req) {
        req.headers.add('Authorization', 'Bearer $token');
        return req.close();
      })
      .then((res) => res.transform(utf8.decoder).join());
  
  final verifyInstructors = jsonDecode(verifyResponse) as List;
  final verifyInstructor = verifyInstructors.firstWhere((i) => i['id'].toString() == instructorId);
  debugPrint('Description después del update: ${verifyInstructor['description']}');
  debugPrint('¿Se guardó? ${verifyInstructor['description'] == updateData['description']}');
}
