import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/chat_controller.dart';
import '../models/message.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/skeleton_loader.dart';

class ConversationsScreen extends StatefulWidget {
  static const routeName = '/conversations';

  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final storage = const FlutterSecureStorage();
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

  String _getOtherParticipantName(Conversation conv) {
    if (conv.lastMessage?.sender != null) {
      final senderId = conv.lastMessage!.senderId;
      if (senderId == _currentUserId) {
        return 'Usuario';
      }
      return conv.lastMessage!.sender!.fullName;
    }
    return 'Usuario';
  }

  int _getOtherParticipantId(Conversation conv) {
    if (_currentUserId == null) return conv.participant1Id;
    return conv.participant1Id == _currentUserId ? conv.participant2Id : conv.participant1Id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        backgroundColor: const Color(0xFF003087),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar conversaciones...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
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
        if (controller.isLoading) {
          return const ListSkeletonLoader();
        }

        final filtered = controller.conversations.where((conv) {
          final name = _getOtherParticipantName(conv).toLowerCase();
          return name.contains(_searchQuery.toLowerCase());
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isEmpty ? 'No tienes conversaciones' : 'No se encontraron resultados',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadConversations(),
          child: ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final conv = filtered[index];
              final otherName = _getOtherParticipantName(conv);
              final otherId = _getOtherParticipantId(conv);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF003087),
                  child: Text(
                    otherName[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  otherName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  conv.lastMessage?.content ?? 'Sin mensajes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: conv.lastMessage != null
                    ? Text(
                        DateFormat('dd/MM HH:mm').format(conv.lastMessage!.sentAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      )
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        recipientName: otherName,
                        recipientId: otherId.toString(),
                        conversationId: conv.id,
                      ),
                    ),
                  ).then((_) => controller.loadConversations());
                },
              );
            },
          ),
        );
      },
    );
  }
}


