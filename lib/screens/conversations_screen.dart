import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:manejapp/config/design_system.dart';
import '../controllers/chat_controller.dart';
import '../models/message.dart';
import 'chat_screen.dart';
import 'home_screen.dart';
import 'package:intl/intl.dart';
import 'package:manejapp/services/secure_storage.dart';
import 'package:manejapp/widgets/design/app_empty_state.dart';
import 'package:manejapp/widgets/design/app_error_state.dart';
import 'package:manejapp/keys/e2e_keys.dart';
import '../widgets/skeleton_loader.dart';

class ConversationsScreen extends StatefulWidget {
  static const routeName = '/conversations';

  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final storage = appSecureStorage;
  int? _currentUserId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = await storage.read(key: 'user_id');
    if (userId != null) {
      _currentUserId = int.tryParse(userId);
    }
    if (mounted) {
      await context.read<ChatController>().loadConversations();
    }
  }

  /// Nombre mostrado: prioriza el remitente del último mensaje si no sos vos; si no hay datos, copy neutro.
  String _conversationTitle(Conversation conv) {
    final lm = conv.lastMessage;
    if (lm?.sender != null && lm!.senderId != _currentUserId) {
      return lm.sender!.fullName;
    }
    if (lm != null && _currentUserId != null && lm.senderId == _currentUserId) {
      return 'Conversación';
    }
    return 'Conversación';
  }

  int _getOtherParticipantId(Conversation conv) {
    if (_currentUserId == null) return conv.participant1Id;
    return conv.participant1Id == _currentUserId
        ? conv.participant2Id
        : conv.participant1Id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mensajes',
            style: AppTextStyles.heading.copyWith(fontSize: 20)),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
            child: Semantics(
              label: 'Buscar conversaciones',
              textField: true,
              child: TextField(
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Buscar por nombre…',
                  hintStyle: AppTextStyles.bodyNormal
                      .copyWith(color: AppColors.textSecondary),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLighter,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<ChatController>(
      builder: (context, controller, _) {
        if (controller.loadingConversations &&
            controller.conversations.isEmpty) {
          return const ListSkeletonLoader(itemCount: 8);
        }

        if (controller.conversationsError != null &&
            controller.conversations.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            children: [
              AppErrorState(
                title: 'No pudimos cargar tus conversaciones',
                message: controller.conversationsError,
                onRetry: _loadData,
                retryLabel: 'Reintentar',
                retryButtonKey: E2eKeys.conversationsRetry,
              ),
            ],
          );
        }

        final filtered = controller.conversations.where((conv) {
          final name = _conversationTitle(conv).toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.lg),
            children: [
              if (_searchQuery.isNotEmpty)
                AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No hay resultados',
                  subtitle: 'Probá con otro nombre o limpiá la búsqueda.',
                  actionLabel: 'Limpiar búsqueda',
                  onAction: () => setState(() => _searchQuery = ''),
                )
              else
                AppEmptyState(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Todavía no tenés conversaciones',
                  subtitle:
                      'Cuando reserves con un instructor y tengas el pago en orden, podés escribirle desde acá.',
                  actionLabel: 'Explorar instructores',
                  onAction: () =>
                      Navigator.pushNamed(context, HomeScreen.routeName),
                ),
            ],
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surfaceLight,
          onRefresh: () => context.read<ChatController>().loadConversations(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final conv = filtered[index];
              final title = _conversationTitle(conv);
              final otherId = _getOtherParticipantId(conv);

              return Semantics(
                label: 'Conversación con $title',
                button: true,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    child: Text(
                      title.isNotEmpty ? title[0].toUpperCase() : '?',
                      style: AppTextStyles.buttonText.copyWith(
                        fontSize: 14,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    title,
                    style: AppTextStyles.bodyLarge
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    conv.lastMessage?.content ?? 'Todavía no hay mensajes',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodyNormal.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  trailing: conv.lastMessage != null
                      ? Text(
                          DateFormat('dd/MM HH:mm')
                              .format(conv.lastMessage!.sentAt.toLocal()),
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.textSecondary),
                        )
                      : null,
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => ChatScreen(
                          recipientName:
                              title == 'Conversación' ? 'Contacto' : title,
                          recipientId: otherId.toString(),
                          conversationId: conv.id,
                        ),
                      ),
                    ).then((_) => controller.loadConversations());
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}
