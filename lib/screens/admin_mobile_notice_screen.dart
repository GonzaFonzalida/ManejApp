import 'package:flutter/material.dart';
import 'package:manejapp/config/app_environment.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/controllers/login_controller.dart';
import 'package:manejapp/utils/support_launcher.dart';
import 'package:manejapp/widgets/design/app_button.dart';
import 'package:manejapp/widgets/design/app_availability_hint.dart';
import 'package:manejapp/widgets/design/app_card.dart';

/// Pantalla V1 para usuarios ADMIN en la app móvil: el panel operativo es web.
class AdminMobileNoticeScreen extends StatelessWidget {
  static const routeName = '/admin_mobile_notice';

  const AdminMobileNoticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loginController = LoginController();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Administración',
          style: AppTextStyles.heading.copyWith(fontSize: 20),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.admin_panel_settings_outlined,
                size: 72,
                color: AppColors.primary.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 24),
              Text(
                'Panel de administración disponible en la web',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Para gestionar instructores, pagos y soporte, ingresá desde el panel web de ManejApp.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyNormal.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
              const Spacer(),
              AppButton(
                text: AppEnvironment.hasAdminPanelUrl
                    ? 'Abrir panel web'
                    : 'Panel web no configurado',
                icon: Icons.open_in_new_rounded,
                onPressed: AppEnvironment.hasAdminPanelUrl
                    ? () => openExternalUrl(
                          context,
                          AppEnvironment.adminPanelUrl,
                          failureMessage:
                              'No pudimos abrir el panel web. Intentá desde un navegador.',
                        )
                    : null,
              ),
              if (!AppEnvironment.hasAdminPanelUrl) ...[
                const SizedBox(height: 8),
                const AppAvailabilityHint(
                  message:
                      'El acceso web todavía no está disponible en esta versión. Podés contactar a soporte.',
                ),
              ],
              const SizedBox(height: 12),
              AppButton(
                text: 'Contactar soporte',
                icon: Icons.mail_outline_rounded,
                onPressed: () => openSupportEmail(context),
                type: AppButtonType.outline,
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'Cerrar sesión',
                onPressed: () => loginController.logout(context),
                type: AppButtonType.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
