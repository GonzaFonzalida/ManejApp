import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../controllers/chat_controller.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import 'package:manejapp/services/secure_storage.dart';
import 'package:manejapp/config/design_system.dart';
import 'package:manejapp/utils/user_facing_error.dart';
import 'package:manejapp/widgets/design/app_empty_state.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/widgets/skeleton_loader.dart';

class ChatScreen extends StatefulWidget {
  static const routeName = '/chat';
  final String recipientName;
  final String recipientId;
  final int? conversationId;

  const ChatScreen({
    super.key,
    required this.recipientName,
    required this.recipientId,
    this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final storage = appSecureStorage;
  int? _currentUserId;
  bool _isSending = false;
  bool _canContact = false;
  bool _checkingAccess = true;
  String? _accessError;

  String get _displayName {
    final n = widget.recipientName.trim();
    return n.isEmpty ? 'Contacto' : n;
  }

  String get _initial {
    final n = _displayName;
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _checkingAccess = true;
      _accessError = null;
    });

    final userId = await storage.read(key: 'user_id');
    if (userId != null) {
      _currentUserId = int.tryParse(userId);
    }

    try {
      final receiverId = int.parse(widget.recipientId);
      final canContact = await ApiService.canContactInstructor(receiverId);
      if (!mounted) return;
      setState(() {
        _canContact = canContact;
        _checkingAccess = false;
        _accessError = null;
      });

      if (widget.conversationId != null && mounted) {
        await context.read<ChatController>().loadMessages(widget.conversationId!);
        _scrollToBottom();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkingAccess = false;
        _accessError = humanizeApiError(e);
        _canContact = false;
      });
    }
  }

  Future<void> _reloadMessages() async {
    final id = widget.conversationId;
    if (id == null) return;
    await context.read<ChatController>().loadMessages(id);
    if (mounted) _scrollToBottom();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _isSending) return;

    final content = _messageController.text.trim();
    _messageController.clear();

    setState(() => _isSending = true);

    try {
      final receiverId = int.parse(widget.recipientId);

      final canContact = await ApiService.canContactInstructor(receiverId);
      if (!canContact) {
        throw Exception(
          'Necesitás tener un pago confirmado para chatear con este instructor.',
        );
      }

      if (!mounted) return;
      await context.read<ChatController>().sendMessage(receiverId, content);

      if (widget.conversationId != null && mounted) {
        await context.read<ChatController>().loadMessages(widget.conversationId!);
      }
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _messageController.text = content;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(humanizeApiError(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: AppSpacing.sm,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.25),
              child: Text(
                _initial,
                style: AppTextStyles.buttonText.copyWith(
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _displayName,
                style: AppTextStyles.heading.copyWith(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: _checkingAccess
          ? const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SkeletonLoader(width: double.infinity, height: 18, borderRadius: BorderRadius.all(Radius.circular(6))),
                  SizedBox(height: AppSpacing.lg),
                  Expanded(child: ListSkeletonLoader(itemCount: 6)),
                ],
              ),
            )
          : _accessError != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  children: [
                    AppErrorState(
                      title: 'No pudimos abrir el chat',
                      message: _accessError,
                      onRetry: _loadData,
                      retryLabel: 'Reintentar',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
                      label: Text(
                        'Volver a mensajes',
                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary),
                      ),
                    ),
                  ],
                )
              : !_canContact
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: [
                        AppEmptyState(
                          icon: Icons.lock_outline_rounded,
                          title: 'Chat no disponible todavía',
                          subtitle:
                              'Para escribirle a este instructor necesitás tener una reserva con pago confirmado.',
                          actionLabel: 'Volver',
                          onAction: () => Navigator.of(context).pop(),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: Consumer<ChatController>(
                            builder: (context, controller, _) {
                              if (widget.conversationId != null && controller.loadingMessages) {
                                return const ListSkeletonLoader(itemCount: 8);
                              }

                              if (widget.conversationId != null &&
                                  controller.messagesError != null &&
                                  controller.messages.isEmpty) {
                                return ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                                  children: [
                                    AppErrorState(
                                      title: 'No pudimos cargar los mensajes',
                                      message: controller.messagesError,
                                      onRetry: _reloadMessages,
                                      retryLabel: 'Reintentar',
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    TextButton.icon(
                                      onPressed: () => Navigator.of(context).pop(),
                                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textSecondary),
                                      label: Text(
                                        'Volver a conversaciones',
                                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.primary),
                                      ),
                                    ),
                                  ],
                                );
                              }

                              if (controller.messages.isEmpty) {
                                return ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(AppSpacing.lg),
                                  children: [
                                    AppEmptyState(
                                      icon: Icons.waving_hand_rounded,
                                      title: 'Arrancá la conversación',
                                      subtitle:
                                          'Escribí un mensaje abajo. Mantené el trato respetuoso y claro.',
                                    ),
                                  ],
                                );
                              }

                              return RefreshIndicator(
                                color: AppColors.primary,
                                backgroundColor: AppColors.surfaceLight,
                                onRefresh: _reloadMessages,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  itemCount: controller.messages.length,
                                  itemBuilder: (context, index) {
                                    final message = controller.messages[index];
                                    return _buildMessageBubble(message);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        Material(
                          color: AppColors.surfaceLight,
                          elevation: 8,
                          shadowColor: Colors.black.withValues(alpha: 0.2),
                          child: SafeArea(
                            top: false,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.sm,
                                AppSpacing.sm,
                                AppSpacing.sm,
                                AppSpacing.sm,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: Semantics(
                                      label: 'Escribir mensaje',
                                      textField: true,
                                      child: TextField(
                                        controller: _messageController,
                                        enabled: !_isSending,
                                        minLines: 1,
                                        maxLines: 5,
                                        style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textPrimary),
                                        decoration: InputDecoration(
                                          hintText: 'Escribí un mensaje…',
                                          hintStyle: AppTextStyles.bodyNormal.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(AppRadius.pill),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: AppColors.surfaceLighter,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: AppSpacing.md,
                                            vertical: AppSpacing.sm,
                                          ),
                                        ),
                                        textInputAction: TextInputAction.send,
                                        onSubmitted: (_) => _sendMessage(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Semantics(
                                    label: _isSending ? 'Enviando mensaje' : 'Enviar mensaje',
                                    button: true,
                                    child: Tooltip(
                                      message: 'Enviar',
                                      child: Material(
                                        color: AppColors.primary,
                                        shape: const CircleBorder(),
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: _isSending ? null : _sendMessage,
                                          child: Padding(
                                            padding: const EdgeInsets.all(AppSpacing.sm),
                                            child: _isSending
                                                ? const SizedBox(
                                                    width: 24,
                                                    height: 24,
                                                    child: CircularProgressIndicator(
                                                      color: AppColors.onPrimary,
                                                      strokeWidth: 2,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.send_rounded,
                                                    color: AppColors.onPrimary,
                                                    size: 22,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isSent = message.senderId == _currentUserId;

    final bubbleBg = isSent ? AppColors.primary : AppColors.surfaceLighter;
    final textColor = isSent ? AppColors.onPrimary : AppColors.textPrimary;
    final metaColor = isSent
        ? AppColors.onPrimary.withValues(alpha: 0.75)
        : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            CircleAvatar(
              backgroundColor: AppColors.surfaceLighter,
              radius: 16,
              child: Text(
                _initial,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bubbleBg,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(isSent ? AppRadius.lg : AppRadius.sm),
                  bottomRight: Radius.circular(isSent ? AppRadius.sm : AppRadius.lg),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: textColor,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.sentAt.toLocal()),
                          style: AppTextStyles.caption.copyWith(color: metaColor, fontSize: 11),
                        ),
                        if (isSent) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.readAt != null ? Icons.done_all_rounded : Icons.done_rounded,
                            size: 14,
                            color: message.readAt != null
                                ? AppColors.secondary.withValues(alpha: 0.95)
                                : metaColor,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
