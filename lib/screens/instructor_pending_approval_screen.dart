import 'dart:async';

import 'package:flutter/material.dart';
import '../config/design_system.dart';
import '../widgets/design/app_button.dart';
import '../services/api_service.dart';
import '../utils/role_router.dart';
import '../services/secure_storage.dart';
import 'login_screen.dart';
import '../widgets/responsive_scroll_body.dart';

const _storage = appSecureStorage;

/// Intervalo de polling para detectar aprobación del admin (sin interacción del usuario).
const _pollIntervalSeconds = 12;

@Deprecated('V1: reemplazado por InstructorOnboardingHubScreen.')
class InstructorPendingApprovalScreen extends StatefulWidget {
  static const routeName = '/instructor_pending_approval';

  const InstructorPendingApprovalScreen({super.key});

  @override
  State<InstructorPendingApprovalScreen> createState() =>
      _InstructorPendingApprovalScreenState();
}

class _InstructorPendingApprovalScreenState
    extends State<InstructorPendingApprovalScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Primera verificación tras 2s para no saturar al montar; luego cada [_pollIntervalSeconds]s.
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _checkApprovalStatus();
    });
    _pollTimer = Timer.periodic(
      const Duration(seconds: _pollIntervalSeconds),
      (_) {
        if (mounted) _checkApprovalStatus();
      },
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkApprovalStatus() async {
    if (!mounted) return;
    try {
      final profile = await ApiService.getInstructorMeOrNull();
      if (!mounted) return;
      final isValid = profile?['isValid'] == true;
      if (isValid) {
        final route = await RoleRouter.resolveRouteForCurrentUser(
          context: 'pending_approval(auto)',
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed(route);
      }
    } catch (_) {
      // Polling silencioso: no mostrar error al usuario
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Cuenta en Revisión',
          style: AppTextStyles.heading.copyWith(fontSize: 20),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textPrimary),
            onPressed: () async {
              await _storage.deleteAll();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed(LoginScreen.routeName);
              }
            },
          )
        ],
      ),
      body: ResponsiveScrollBody(
        padding: const EdgeInsets.all(24),
        centerWhenShort: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              const Icon(
                Icons.hourglass_empty,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Estamos revisando tus documentos',
                style: AppTextStyles.displayLarge.copyWith(fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Un administrador está validando los documentos que enviaste. Este proceso puede tardar hasta 48 horas hábiles. Cuando tu perfil sea aprobado, esta pantalla se actualizará sola.',
                style: AppTextStyles.bodyNormal.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              AppButton(
                text: 'Cerrar sesión y salir',
                type: AppButtonType.outline,
                onPressed: () async {
                  await _storage.deleteAll();
                  if (context.mounted) {
                    Navigator.of(context)
                        .pushReplacementNamed(LoginScreen.routeName);
                  }
                },
              ),
            ],
          ),
      ),
    );
  }
}
