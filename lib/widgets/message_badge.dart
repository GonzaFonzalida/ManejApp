import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manejapp/config/design_system.dart';
import '../controllers/chat_controller.dart';

class MessageBadge extends StatelessWidget {
  final Widget child;

  const MessageBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatController>(
      builder: (context, controller, _) {
        final count = controller.unreadCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Semantics(
                  label: count == 1
                      ? '1 mensaje sin leer'
                      : '$count mensajes sin leer',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
