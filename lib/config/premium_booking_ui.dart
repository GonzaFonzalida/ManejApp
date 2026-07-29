import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:manejapp/config/design_system.dart';

/// Copy, etiquetas y colores compartidos para reservas premium (alumno + instructor).
class PremiumBookingUi {
  PremiumBookingUi._();

  static String statusLabel(String status) {
    switch (status) {
      case 'PENDING_PAYMENT':
        return 'Pendiente de pago';
      case 'CONFIRMED':
        return 'Confirmada';
      case 'CANCELLED':
        return 'Cancelada';
      case 'COMPLETED':
        return 'Completada';
      default:
        return status;
    }
  }

  /// Versión corta para chips en listas.
  static String statusChipLabel(String status) {
    switch (status) {
      case 'PENDING_PAYMENT':
        return 'Pendiente pago';
      case 'CONFIRMED':
        return 'Confirmada';
      case 'CANCELLED':
        return 'Cancelada';
      case 'COMPLETED':
        return 'Completada';
      default:
        return status;
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'PENDING_PAYMENT':
        return AppColors.warning;
      case 'CONFIRMED':
        return AppColors.success;
      case 'CANCELLED':
        return AppColors.error;
      case 'COMPLETED':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Texto corto para chips de pago (API puede devolver inglés).
  static String paymentShortLabel(String paymentStatus) {
    final s = paymentStatus.toLowerCase().trim();
    switch (s) {
      case 'paid':
      case 'approved':
      case 'completed':
        return 'Pagado';
      case 'pending':
      case 'in_process':
        return 'Pago pendiente';
      case 'rejected':
      case 'cancelled':
        return 'Pago rechazado';
      case 'unpaid':
        return 'Sin pago';
      case 'refunded':
        return 'Reembolsado';
      case 'manual_review':
        return 'Pago en revisión';
      default:
        return paymentStatus.isEmpty ? '—' : paymentStatus;
    }
  }

  /// Nota breve bajo el estado de pago cuando aplica (evita copy técnico).
  static String? paymentDetailNote(String paymentStatus) {
    if (isManualReviewPayment(paymentStatus)) {
      return 'No requiere acción por ahora';
    }
    return null;
  }

  static bool isManualReviewPayment(String paymentStatus) {
    return paymentStatus.toLowerCase().trim() == 'manual_review';
  }

  static bool isPendingPaymentStatus(String paymentStatus) {
    final s = paymentStatus.toLowerCase().trim();
    return s == 'pending' || s == 'in_process' || s == 'unpaid';
  }

  /// Reserva que requiere atención del instructor (pago pendiente o en revisión).
  static bool instructorReservationNeedsAttention({
    required String status,
    required String paymentStatus,
  }) {
    if (isManualReviewPayment(paymentStatus)) return true;
    if (status == 'PENDING_PAYMENT') return true;
    return isPendingPaymentStatus(paymentStatus);
  }

  /// Orden en listas del instructor: manual_review → pago pendiente → confirmada → resto.
  static int instructorUpcomingSortKey({
    required String status,
    required String paymentStatus,
  }) {
    if (isManualReviewPayment(paymentStatus)) return 0;
    if (status == 'PENDING_PAYMENT' || isPendingPaymentStatus(paymentStatus)) {
      return 1;
    }
    if (status == 'CONFIRMED') return 2;
    return 3;
  }

  static Color paymentAccent(String paymentStatus) {
    final s = paymentStatus.toLowerCase().trim();
    if (s == 'paid' || s == 'approved' || s == 'completed') {
      return AppColors.success;
    }
    if (s == 'manual_review' ||
        s == 'pending' ||
        s == 'in_process' ||
        s == 'unpaid') {
      return AppColors.warning;
    }
    if (s == 'rejected' || s == 'cancelled') {
      return AppColors.error;
    }
    if (s == 'refunded') {
      return AppColors.textSecondary;
    }
    return AppColors.textSecondary;
  }

  /// Estado del slot en lenguaje natural (evita mostrar enums crudos).
  static String slotStatusLabel(String slotStatus) {
    final s = slotStatus.toUpperCase().trim();
    switch (s) {
      case 'BOOKED':
        return 'Reservado';
      case 'OPEN':
      case 'AVAILABLE':
        return 'Disponible';
      case 'BLOCKED':
        return 'Bloqueado';
      case 'CANCELLED':
        return 'Liberado';
      default:
        return slotStatus.isEmpty ? '—' : slotStatus;
    }
  }

  /// Texto único para bloques de plazo de cancelación en detalle.
  static String cancelDeadlineDetailText(DateTime? deadline) {
    if (deadline == null) {
      return 'Último momento para cancelar: dato no disponible';
    }
    return 'Último momento para cancelar: ${DateFormat('d MMM · HH:mm', 'es').format(deadline)}';
  }

  static String whatsappUnavailableExplanation(String? reason) {
    switch (reason?.toUpperCase().trim()) {
      case 'RESERVATION_NOT_CONFIRMED':
      case 'NOT_CONFIRMED':
        return 'WhatsApp se habilita cuando la reserva queda confirmada.';
      case 'MISSING_PHONE_NUMBER':
      case 'PHONE_NUMBER_UNAVAILABLE':
      case 'INVALID_PHONE_NUMBER':
        return 'No encontramos un WhatsApp válido de la otra persona.';
      case 'RESERVATION_CANCELLED':
      case 'RESERVATION_COMPLETED':
        return 'El contacto por WhatsApp solo está disponible mientras la reserva está activa.';
      default:
        return 'WhatsApp se habilita cuando la reserva queda confirmada y ambas cuentas tienen un número válido.';
    }
  }

  static String cancelUnavailableExplanation({
    required String status,
    DateTime? deadline,
  }) {
    switch (status.toUpperCase().trim()) {
      case 'CANCELLED':
        return 'Esta reserva ya fue cancelada.';
      case 'COMPLETED':
        return 'La clase ya fue completada y no se puede cancelar.';
    }
    if (deadline != null && DateTime.now().isAfter(deadline)) {
      return 'El plazo para cancelar terminó el ${DateFormat('d MMM · HH:mm', 'es').format(deadline)}.';
    }
    return 'Esta reserva no admite cancelación desde la app por su estado o política vigente.';
  }

  /// Línea en cards de listado (alumno).
  static String nextActionStudentCard(String action) {
    switch (action) {
      case 'COMPLETE_PAYMENT':
        return 'Completá el pago para confirmar tu lugar';
      case 'PREPARE_FOR_CLASS':
        return 'Revisá hora, lugar y datos del instructor';
      case 'VIEW_CLASS_DETAILS':
        return 'Reserva activa — tocá para ver el detalle';
      case 'BOOK_ANOTHER_CLASS':
        return 'Podés reservar otra clase cuando quieras';
      case 'LEAVE_FEEDBACK':
        return 'Contanos cómo fue la clase';
      case 'WAIT_FOR_PAYMENT_CONFIRMATION':
        return 'Esperando confirmación del pago';
      case 'CHECK_RESERVATION_STATUS':
        return 'Tocá para ver el estado más reciente';
      default:
        return 'Revisá el estado en el detalle';
    }
  }

  /// CTA principal en detalle (alumno).
  static String nextActionStudentPrimaryCta(String action) {
    switch (action) {
      case 'COMPLETE_PAYMENT':
        return 'Completar pago';
      case 'VIEW_CLASS_DETAILS':
        return 'Ver información de la clase';
      case 'PREPARE_FOR_CLASS':
        return 'Actualizar estado';
      case 'BOOK_ANOTHER_CLASS':
        return 'Buscar otra clase';
      case 'LEAVE_FEEDBACK':
        return 'Dejar comentarios';
      case 'CHECK_RESERVATION_STATUS':
        return 'Actualizar estado';
      case 'WAIT_FOR_PAYMENT_CONFIRMATION':
        return 'Actualizar';
      default:
        return 'Actualizar';
    }
  }

  /// Línea en cards de listado (instructor).
  static String nextActionInstructorCard(String action) {
    switch (action) {
      case 'WAIT_FOR_PAYMENT_CONFIRMATION':
        return 'Esperando el pago del alumno';
      case 'VIEW_CLASS_DETAILS':
        return 'Revisá alumno, hora y ubicación';
      case 'PREPARE_FOR_CLASS':
        return 'Preparate para la clase';
      case 'OPEN_NEW_AVAILABILITY_SLOT':
        return 'Sumá franjas en tu agenda';
      case 'REVIEW_CLASS_HISTORY':
        return 'Clase finalizada — ver registro';
      case 'CHECK_RESERVATION_STATUS':
        return 'Actualizá para ver el estado más reciente';
      case 'NO_ACTION':
        return 'Sin acción pendiente';
      default:
        return 'Revisá el estado en el detalle';
    }
  }

  /// CTA principal en detalle (instructor).
  static String nextActionInstructorPrimaryCta(String action) {
    switch (action) {
      case 'WAIT_FOR_PAYMENT_CONFIRMATION':
        return 'Actualizar estado';
      case 'VIEW_CLASS_DETAILS':
      case 'PREPARE_FOR_CLASS':
      case 'CHECK_RESERVATION_STATUS':
        return 'Actualizar información';
      case 'OPEN_NEW_AVAILABILITY_SLOT':
        return 'Ir a mi agenda';
      case 'REVIEW_CLASS_HISTORY':
        return 'Actualizar';
      default:
        return 'Actualizar';
    }
  }

  static String policyHeadline() => 'Política y plazos';

  static String policyFooterHint({required bool canCancel}) {
    if (canCancel) {
      return 'Dentro del plazo podés cancelar desde esta pantalla. Fuera del plazo aplica lo indicado arriba.';
    }
    return 'Ya no podés cancelar desde la app: pasó el plazo o aplica una excepción de política.';
  }
}
