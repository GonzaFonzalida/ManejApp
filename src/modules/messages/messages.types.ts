export interface Message {
  id: number;
  conversationId: number;
  senderId: number;
  content: string;
  sentAt: Date;
  readAt: Date | null;
}

export interface Conversation {
  id: number;
  participant1Id: number;
  participant2Id: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface ConversationWithMessages extends Conversation {
  messages: Message[];
  lastMessage?: Message;
}

export interface CreateMessageData {
  conversationId: number;
  senderId: number;
  content: string;
}

export interface CreateConversationData {
  participant1Id: number;
  participant2Id: number;
}

export interface MessageWithSender extends Omit<Message, 'readAt'> {
  readAt: Date | null;
  sender: {
    id: number;
    name: string;
    surname: string;
  };
}