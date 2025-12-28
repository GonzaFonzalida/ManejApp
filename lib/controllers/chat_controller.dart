import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/message.dart';
import 'dart:developer' as developer;

class ChatController extends ChangeNotifier {
  List<Conversation> _conversations = [];
  List<Message> _messages = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  List<Conversation> get conversations => _conversations;
  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getConversations();
      _conversations = data.map((json) => Conversation.fromJson(json)).toList();
      await loadUnreadCount();
    } catch (e) {
      developer.log('Error loading conversations: $e', name: 'ChatController');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(int conversationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.getConversationMessages(conversationId);
      _messages = data.map((json) => Message.fromJson(json)).toList();
      await ApiService.markConversationAsRead(conversationId);
      await loadUnreadCount();
    } catch (e) {
      developer.log('Error loading messages: $e', name: 'ChatController');
      rethrow;
    } finally {
      _isLoading = false;
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
