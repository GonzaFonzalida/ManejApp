import {
  Message,
  Conversation,
  ConversationWithMessages,
  CreateMessageData,
  CreateConversationData,
  MessageWithSender
} from '../messages.types';

export interface MessageRepository {
  // Conversations
  createConversation(data: CreateConversationData): Promise<Conversation>;
  findConversationByParticipants(participant1Id: number, participant2Id: number): Promise<Conversation | null>;
  getUserConversations(userId: number): Promise<ConversationWithMessages[]>;

  // Messages
  createMessage(data: CreateMessageData): Promise<Message>;
  getConversationMessages(conversationId: number, userId: number): Promise<MessageWithSender[]>;
  markMessagesAsRead(conversationId: number, userId: number): Promise<void>;
  getUnreadCount(userId: number): Promise<number>;
}