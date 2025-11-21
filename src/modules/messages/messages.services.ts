import { MessageRepository } from "./repositories/MessageRepository";
import CustomizedError from "@shared/classes/CustomizedError";
import {
  Message,
  ConversationWithMessages,
  CreateMessageData,
  MessageWithSender
} from "./messages.types";

export default class MessageService {
  constructor(private messageRepository: MessageRepository) {}

  async sendMessage(
    senderId: number,
    receiverId: number,
    content: string
  ): Promise<Message> {
    try {
      // Validate input
      if (!content || content.trim().length === 0) {
        throw new CustomizedError("El contenido del mensaje no puede estar vacío", 400);
      }

      if (content.length > 1000) {
        throw new CustomizedError("El mensaje no puede exceder 1000 caracteres", 400);
      }

      // Find or create conversation
      let conversation = await this.messageRepository.findConversationByParticipants(
        senderId,
        receiverId
      );

      if (!conversation) {
        conversation = await this.messageRepository.createConversation({
          participant1Id: senderId,
          participant2Id: receiverId,
        });
      }

      // Create message
      const messageData: CreateMessageData = {
        conversationId: conversation.id,
        senderId,
        content: content.trim(),
      };

      return await this.messageRepository.createMessage(messageData);
    } catch (error) {
      if (error instanceof CustomizedError) {
        throw error;
      }
      throw new CustomizedError("Error al enviar el mensaje", 500);
    }
  }

  async getUserConversations(userId: number): Promise<ConversationWithMessages[]> {
    try {
      return await this.messageRepository.getUserConversations(userId);
    } catch (error) {
      throw new CustomizedError("Error al obtener las conversaciones", 500);
    }
  }

  async getConversationMessages(
    conversationId: number,
    userId: number
  ): Promise<MessageWithSender[]> {
    try {
      const messages = await this.messageRepository.getConversationMessages(
        conversationId,
        userId
      );

      // Mark messages as read
      await this.messageRepository.markMessagesAsRead(conversationId, userId);

      return messages;
    } catch (error) {
      if (error instanceof CustomizedError) {
        throw error;
      }
      throw new CustomizedError("Error al obtener los mensajes", 500);
    }
  }

  async getUnreadCount(userId: number): Promise<number> {
    try {
      return await this.messageRepository.getUnreadCount(userId);
    } catch (error) {
      throw new CustomizedError("Error al obtener el conteo de mensajes no leídos", 500);
    }
  }

  async markConversationAsRead(conversationId: number, userId: number): Promise<void> {
    try {
      await this.messageRepository.markMessagesAsRead(conversationId, userId);
    } catch (error) {
      throw new CustomizedError("Error al marcar los mensajes como leídos", 500);
    }
  }
}