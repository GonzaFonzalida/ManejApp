import { prisma } from "@config/prismaClient";
import { MessageRepository } from "./MessageRepository";
import {
  Message,
  Conversation,
  ConversationWithMessages,
  CreateMessageData,
  CreateConversationData,
  MessageWithSender
} from "../messages.types";

export default class PrismaMessageRepository implements MessageRepository {
  async createConversation(data: CreateConversationData): Promise<Conversation> {
    // Ensure participants are ordered to avoid duplicates
    const [participant1Id, participant2Id] = data.participant1Id < data.participant2Id
      ? [data.participant1Id, data.participant2Id]
      : [data.participant2Id, data.participant1Id];

    return await prisma.conversation.create({
      data: {
        participant1Id,
        participant2Id,
      },
    });
  }

  async findConversationByParticipants(participant1Id: number, participant2Id: number): Promise<Conversation | null> {
    const [p1, p2] = participant1Id < participant2Id
      ? [participant1Id, participant2Id]
      : [participant2Id, participant1Id];

    return await prisma.conversation.findUnique({
      where: {
        participant1Id_participant2Id: {
          participant1Id: p1,
          participant2Id: p2,
        },
      },
    });
  }

  async getUserConversations(userId: number): Promise<ConversationWithMessages[]> {
    const conversations = await prisma.conversation.findMany({
      where: {
        OR: [
          { participant1Id: userId },
          { participant2Id: userId },
        ],
      },
      include: {
        messages: {
          include: {
            sender: {
              select: {
                id: true,
                name: true,
                surname: true,
              },
            },
          },
          orderBy: {
            sentAt: 'desc',
          },
          take: 1, // Only get the last message for preview
        },
      },
      orderBy: {
        updatedAt: 'desc',
      },
    });

    return conversations.map((conv: any) => ({
      ...conv,
      lastMessage: conv.messages[0],
      messages: [], // Don't include all messages in this query
    }));
  }

  async createMessage(data: CreateMessageData): Promise<Message> {
    // Update conversation updatedAt
    await prisma.conversation.update({
      where: { id: data.conversationId },
      data: { updatedAt: new Date() },
    });

    return await prisma.message.create({
      data,
    });
  }

  async getConversationMessages(conversationId: number, userId: number): Promise<MessageWithSender[]> {
    // Verify user is participant in conversation
    const conversation = await prisma.conversation.findFirst({
      where: {
        id: conversationId,
        OR: [
          { participant1Id: userId },
          { participant2Id: userId },
        ],
      },
    });

    if (!conversation) {
      throw new Error('Conversation not found or access denied');
    }

    return await prisma.message.findMany({
      where: { conversationId },
      include: {
        sender: {
          select: {
            id: true,
            name: true,
            surname: true,
          },
        },
      },
      orderBy: {
        sentAt: 'asc',
      },
    });
  }

  async markMessagesAsRead(conversationId: number, userId: number): Promise<void> {
    // Only mark messages as read if user is not the sender
    await prisma.message.updateMany({
      where: {
        conversationId,
        senderId: { not: userId },
        readAt: null,
      },
      data: {
        readAt: new Date(),
      },
    });
  }

  async getUnreadCount(userId: number): Promise<number> {
    const result = await prisma.message.groupBy({
      by: ['conversationId'],
      where: {
        readAt: null,
        conversation: {
          OR: [
            { participant1Id: userId },
            { participant2Id: userId },
          ],
        },
        senderId: { not: userId },
      },
      _count: {
        id: true,
      },
    });

    return result.reduce((total: number, group: any) => total + group._count.id, 0);
  }
}