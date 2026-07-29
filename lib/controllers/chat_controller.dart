import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/message.dart';
import '../utils/user_facing_error.dart';
import 'dart:developer' as developer;

class ChatController extends ChangeNotifier {
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  bool _loadingConversations = false;
  bool _loadingMessages = false;
  String? _conversationsError;
  String? _messagesError;
  int _unreadCount = 0;

  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  int get unreadCount => _unreadCount;

  bool get loadingConversations => _loadingConversations;
  bool get loadingMessages => _loadingMessages;
  String? get conversationsError => _conversationsError;
  String? get messagesError => _messagesError;

  Future<void> loadConversations() async {
    _conversationsError = null;
    _loadingConversations = true;
    notifyListeners();

    try {
      final data = await ApiService.getConversations();
      _conversations = data.map((json) => Conversation.fromJson(json)).toList();
      await loadUnreadCount();
    } catch (e) {
      developer.log('Error loading conversations: $e', name: 'ChatController');
      _conversationsError = humanizeApiError(e);
    } finally {
      _loadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(int conversationId) async {
    _messagesError = null;
    _loadingMessages = true;
    notifyListeners();

    try {
      final data = await ApiService.getConversationMessages(conversationId);
      _messages = data.map((json) => Message.fromJson(json)).toList();
      await ApiService.markConversationAsRead(conversationId);
      await loadUnreadCount();
    } catch (e) {
      developer.log('Error loading messages: $e', name: 'ChatController');
      _messages = [];
      _messagesError = humanizeApiError(e);
    } finally {
      _loadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(int receiverId, String content) async {
    try {
      await ApiService.sendMessage(receiverId, content);
    } catch (e) {
      developer.log('Error sending message: $e', name: 'ChatController');
      rethrow;
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await ApiService.getUnreadMessagesCount();
      notifyListeners();
    } catch (e) {
      developer.log('Error loading unread count: $e', name: 'ChatController');
    }
  }
}
