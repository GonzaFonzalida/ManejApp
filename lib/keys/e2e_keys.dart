import 'package:flutter/material.dart';

/// Keys para integration_test (encontrar widgets sin depender solo del texto).
class E2eKeys {
  E2eKeys._();

  static const Key studentNavReservations =
      ValueKey<String>('e2e_student_nav_reservations');

  static Key studentReservationCard(int id) =>
      ValueKey<String>('e2e_student_reservation_$id');

  static const Key studentReservationDetailPrimary =
      ValueKey<String>('e2e_student_res_detail_primary');
  static const Key studentReservationDetailWhatsapp =
      ValueKey<String>('e2e_student_res_detail_whatsapp');
  static const Key studentReservationDetailCancel =
      ValueKey<String>('e2e_student_res_detail_cancel');

  static const Key studentReservationsRefresh =
      ValueKey<String>('e2e_student_reservations_refresh');
  static const Key studentReservationsEmpty =
      ValueKey<String>('e2e_student_reservations_empty');

  static const Key dialogConfirm = ValueKey<String>('e2e_dialog_confirm');

  static const Key instructorClassesRefresh =
      ValueKey<String>('e2e_instructor_classes_refresh');
  static Key instructorReservationCard(int id) =>
      ValueKey<String>('e2e_instructor_reservation_$id');
  static const Key instructorReservationDetailPrimary =
      ValueKey<String>('e2e_instructor_res_detail_primary');
  static const Key instructorReservationDetailWhatsapp =
      ValueKey<String>('e2e_instructor_res_detail_whatsapp');
  static const Key instructorReservationDetailComplete =
      ValueKey<String>('e2e_instructor_res_detail_complete');
  static const Key instructorReservationDetailRetry =
      ValueKey<String>('e2e_instructor_res_detail_retry');

  static const Key instructorDashboardRefresh =
      ValueKey<String>('e2e_instructor_dashboard_refresh');
  static const Key instructorTodayEmpty =
      ValueKey<String>('e2e_instructor_today_empty');
  static Key instructorTodayCard(int id) =>
      ValueKey<String>('e2e_instructor_today_$id');

  /// Empty state en Mis clases (true = pestaña Próximas).
  static Key instructorClassesEmpty({required bool upcoming}) =>
      ValueKey<String>(
        upcoming
            ? 'e2e_instructor_classes_empty_upcoming'
            : 'e2e_instructor_classes_empty_history',
      );

  static const Key studentReservationDetailRetry =
      ValueKey<String>('e2e_student_res_detail_retry');

  static const Key reservationSuccessGoToList =
      ValueKey<String>('e2e_reservation_success_to_list');
  static const Key reservationSuccessRefreshStatus =
      ValueKey<String>('e2e_reservation_success_refresh');

  /// Reintentar carga de conversaciones ([ConversationsScreen] + [AppErrorState]).
  static const Key conversationsRetry =
      ValueKey<String>('e2e_conversations_retry');

  /// Tarjeta principal del home alumno cuando no hay reservas (copy estable para E2E).
  static const Key studentHomeNoBookingsCard =
      ValueKey<String>('e2e_student_home_no_bookings');
}
