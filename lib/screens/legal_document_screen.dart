import 'package:flutter/material.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/utils/support_launcher.dart';
import 'package:manejapp/widgets/design/app_button.dart';

/// Sección de un documento legal/informativo: un título y uno o más párrafos.
class LegalSection {
  final String heading;
  final List<String> paragraphs;

  const LegalSection({required this.heading, required this.paragraphs});
}

/// Pantalla genérica para mostrar documentos de texto largo:
/// Términos y Condiciones, Política de Privacidad y Centro de Ayuda.
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String? lastUpdated;
  final List<LegalSection> sections;
  final bool showSupportAction;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.sections,
    this.lastUpdated,
    this.showSupportAction = false,
  });

  /// Términos y Condiciones de uso de ManejApp.
  factory LegalDocumentScreen.terms() {
    return const LegalDocumentScreen(
      title: 'Términos y condiciones',
      lastUpdated: 'Última actualización: julio 2026',
      showSupportAction: true,
      sections: [
        LegalSection(
          heading: '1. Aceptación de los términos',
          paragraphs: [
            'Al crear una cuenta y usar ManejApp aceptás estos Términos y Condiciones. '
                'Si no estás de acuerdo, no utilices la aplicación.',
          ],
        ),
        LegalSection(
          heading: '2. Qué es ManejApp',
          paragraphs: [
            'ManejApp es una plataforma que conecta alumnos con instructores de manejo. '
                'ManejApp facilita la reserva y el pago de clases, pero la clase es prestada por el instructor, '
                'no por ManejApp.',
          ],
        ),
        LegalSection(
          heading: '3. Cuentas de usuario',
          paragraphs: [
            'Sos responsable de la veracidad de los datos que cargás y de mantener la confidencialidad de tu contraseña.',
            'Debés verificar tu correo electrónico para activar tu cuenta. Los instructores deben completar su perfil '
                'y presentar la documentación requerida para poder ofrecer clases.',
          ],
        ),
        LegalSection(
          heading: '4. Reservas y pagos',
          paragraphs: [
            'Los pagos se procesan a través de Mercado Pago. ManejApp retiene una comisión sobre el valor de cada clase; '
                'el resto se acredita al instructor.',
            'Una reserva queda confirmada únicamente cuando el pago es aprobado. '
                'Si el pago no se completa dentro del tiempo de reserva, el horario vuelve a quedar disponible.',
          ],
        ),
        LegalSection(
          heading: '5. Cancelaciones',
          paragraphs: [
            'Las políticas de cancelación y los plazos aplicables se muestran al momento de reservar. '
                'Los reembolsos, cuando correspondan, se gestionan según las condiciones de Mercado Pago.',
          ],
        ),
        LegalSection(
          heading: '6. Responsabilidad',
          paragraphs: [
            'ManejApp no es responsable por la calidad de la clase, el estado del vehículo ni por daños ocurridos '
                'durante la misma. La relación de la clase es entre alumno e instructor.',
          ],
        ),
        LegalSection(
          heading: '7. Cambios en los términos',
          paragraphs: [
            'Podemos actualizar estos términos. Te avisaremos de cambios relevantes dentro de la aplicación. '
                'El uso continuado implica la aceptación de la versión vigente.',
          ],
        ),
        LegalSection(
          heading: '8. Contacto',
          paragraphs: [
            'Ante cualquier duda escribinos a soporte@manejapp.app.',
          ],
        ),
      ],
    );
  }

  /// Política de Privacidad de ManejApp.
  factory LegalDocumentScreen.privacy() {
    return const LegalDocumentScreen(
      title: 'Política de privacidad',
      lastUpdated: 'Última actualización: julio 2026',
      showSupportAction: true,
      sections: [
        LegalSection(
          heading: '1. Datos que recopilamos',
          paragraphs: [
            'Recopilamos los datos que nos proporcionás al registrarte (nombre, apellido, correo electrónico, DNI, fecha de nacimiento, '
                'teléfono y ubicación) y la información necesaria para gestionar reservas, pagos y clases.',
            'Los instructores además cargan documentación de habilitación y datos profesionales.',
          ],
        ),
        LegalSection(
          heading: '2. Cómo usamos tus datos',
          paragraphs: [
            'Usamos tus datos para crear y administrar tu cuenta, procesar reservas y pagos, conectarte con instructores '
                'o alumnos, enviarte notificaciones relacionadas con el servicio y mejorar la aplicación.',
          ],
        ),
        LegalSection(
          heading: '3. Pagos',
          paragraphs: [
            'Los pagos se procesan mediante Mercado Pago. No almacenamos los datos completos de tus tarjetas; '
                'esa información es gestionada por Mercado Pago según sus propias políticas.',
          ],
        ),
        LegalSection(
          heading: '4. Compartir información',
          paragraphs: [
            'Compartimos los datos mínimos necesarios entre alumno e instructor para concretar una clase. '
                'No vendemos tus datos personales a terceros.',
            'Podemos usar servicios de terceros (por ejemplo, Mercado Pago para pagos y Google para inicio de sesión) '
                'que tratan datos según sus propias políticas.',
          ],
        ),
        LegalSection(
          heading: '5. Notificaciones',
          paragraphs: [
            'Podemos enviarte avisos por correo electrónico y notificaciones push sobre reservas, pagos, recordatorios de clase '
                'y aprobación de documentación. Podés ajustar tus preferencias desde la configuración de la app.',
          ],
        ),
        LegalSection(
          heading: '6. Tus derechos',
          paragraphs: [
            'Podés acceder, corregir o eliminar tus datos personales. La opción "Eliminar cuenta" anonimiza tus datos '
                'personales. Cierta información puede conservarse de forma agregada por obligaciones legales o contables.',
          ],
        ),
        LegalSection(
          heading: '7. Seguridad',
          paragraphs: [
            'Aplicamos medidas razonables para proteger tu información. Las contraseñas se protegen mediante técnicas de hashing seguro y las '
                'comunicaciones con nuestros servidores se realizan sobre canales seguros.',
          ],
        ),
        LegalSection(
          heading: '8. Contacto',
          paragraphs: [
            'Por consultas sobre privacidad o tus datos, escribinos a soporte@manejapp.app.',
          ],
        ),
      ],
    );
  }

  /// Centro de Ayuda con preguntas frecuentes y contacto.
  factory LegalDocumentScreen.help() {
    return const LegalDocumentScreen(
      title: 'Centro de ayuda',
      showSupportAction: true,
      sections: [
        LegalSection(
          heading: '¿Cómo reservo una clase?',
          paragraphs: [
            'Buscá un instructor, elegí un horario disponible, revisá el resumen y completá el pago. '
                'Tu reserva queda confirmada cuando el pago se aprueba.',
          ],
        ),
        LegalSection(
          heading: '¿Cómo pago?',
          paragraphs: [
            'Los pagos se realizan con Mercado Pago. Podés pagar con dinero en cuenta, tarjeta u otros medios disponibles.',
          ],
        ),
        LegalSection(
          heading: 'No recibí el correo de verificación',
          paragraphs: [
            'Revisá la carpeta de spam o correo no deseado. También podés solicitar el reenvío del correo desde la '
                'pantalla de verificación. Si el problema persiste, escribinos.',
          ],
        ),
        LegalSection(
          heading: 'Soy instructor, ¿cómo empiezo a recibir alumnos?',
          paragraphs: [
            'Completá tu perfil profesional, cargá la documentación requerida y conectá tu cuenta de Mercado Pago. '
                'Cuando tu cuenta esté verificada y publicable, vas a aparecer en las búsquedas.',
          ],
        ),
        LegalSection(
          heading: '¿Necesitás más ayuda?',
          paragraphs: [
            'Escribinos a soporte@manejapp.app y te respondemos a la brevedad.',
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title, style: AppTextStyles.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.background,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (lastUpdated != null) ...[
              Text(
                lastUpdated!,
                style: AppTextStyles.bodyNormal.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),
            ],
            for (final section in sections) ...[
              Text(
                section.heading,
                style: AppTextStyles.bodyLarge
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (final paragraph in section.paragraphs) ...[
                Text(
                  paragraph,
                  style: AppTextStyles.bodyNormal.copyWith(height: 1.5),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 16),
            ],
            if (showSupportAction) ...[
              AppButton(
                text: 'Escribir a soporte',
                icon: Icons.mail_outline_rounded,
                onPressed: () => openSupportEmail(context),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
