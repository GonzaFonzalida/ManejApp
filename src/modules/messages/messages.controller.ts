import { Request, Response } from 'express';
import MessageService from './messages.services';
import { AuthenticatedRequest } from '@shared/types/AuthenticatedRequest';
import CustomizedError from '@shared/classes/CustomizedError';

export default class MessageController {
  constructor(private messageService: MessageService) {}

  /**
   * @swagger
   * /messages/send:
   *   post:
   *     summary: Send a message to another user
   *     tags: [Messages]
   *     security:
   *       - bearerAuth: []
   *     requestBody:
   *       required: true
   *       content:
   *         application/json:
   *           schema:
   *             type: object
   *             required:
   *               - receiverId
   *               - content
   *             properties:
   *               receiverId:
   *                 type: integer
   *                 minimum: 1
   *                 description: ID of the user to send the message to
   *               content:
   *                 type: string
   *                 minLength: 1
   *                 maxLength: 1000
   *                 description: Message content
   *     responses:
   *       201:
   *         description: Message sent successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 success:
   *                   type: boolean
   *                   example: true
   *                 message:
   *                   type: string
   *                   example: "Mensaje enviado exitosamente"
   *                 data:
   *                   type: object
   *                   properties:
   *                     id:
   *                       type: integer
   *                       description: Message ID
   *                     conversationId:
   *                       type: integer
   *                       description: Conversation ID
   *                     senderId:
   *                       type: integer
   *                       description: Sender user ID
   *                     content:
   *                       type: string
   *                       description: Message content
   *                     sentAt:
   *                       type: string
   *                       format: date-time
   *                       description: Message sent timestamp
   *                     readAt:
   *                       type: string
   *                       format: date-time
   *                       nullable: true
   *                       description: Message read timestamp
   *       400:
   *         description: Validation error
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 success:
   *                   type: boolean
   *                   example: false
   *                 error:
   *                   type: string
   *                   example: "receiverId y content son requeridos"
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  async sendMessage(req: AuthenticatedRequest, res: Response) {
    try {
      const { id: senderId } = req.user!;
      const { receiverId, content } = req.body;

      if (!receiverId || !content) {
        return res.status(400).json({
          success: false,
          error: "receiverId y content son requeridos"
        });
      }

      const message = await this.messageService.sendMessage(
        senderId,
        parseInt(receiverId),
        content
      );

      res.status(201).json({
        success: true,
        message: "Mensaje enviado exitosamente",
        data: message,
      });
    } catch (error) {
      if (error instanceof CustomizedError) {
        res.status(error.statusCode).json({
          success: false,
          error: error.message
        });
      } else {
        res.status(500).json({
          success: false,
          error: "Error interno del servidor"
        });
      }
    }
  }

  /**
   * @swagger
   * /messages/conversations:
   *   get:
   *     summary: Get user's conversations
   *     tags: [Messages]
   *     security:
   *       - bearerAuth: []
   *     responses:
   *       200:
   *         description: Conversations retrieved successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 success:
   *                   type: boolean
   *                   example: true
   *                 data:
   *                   type: array
   *                   items:
   *                     type: object
   *                     properties:
   *                       id:
   *                         type: integer
   *                         description: Conversation ID
   *                       participant1Id:
   *                         type: integer
   *                         description: First participant user ID
   *                       participant2Id:
   *                         type: integer
   *                         description: Second participant user ID
   *                       createdAt:
   *                         type: string
   *                         format: date-time
   *                         description: Conversation creation timestamp
   *                       updatedAt:
   *                         type: string
   *                         format: date-time
   *                         description: Conversation last update timestamp
   *                       lastMessage:
   *                         type: object
   *                         nullable: true
   *                         properties:
   *                           id:
   *                             type: integer
   *                             description: Last message ID
   *                           content:
   *                             type: string
   *                             description: Last message content
   *                           sentAt:
   *                             type: string
   *                             format: date-time
   *                             description: Last message timestamp
   *                           sender:
   *                             type: object
   *                             properties:
   *                               id:
   *                                 type: integer
   *                                 description: Sender user ID
   *                               name:
   *                                 type: string
   *                                 description: Sender first name
   *                               surname:
   *                                 type: string
   *                                 description: Sender last name
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  async getUserConversations(req: AuthenticatedRequest, res: Response) {
    try {
      const { id: userId } = req.user!;

      const conversations = await this.messageService.getUserConversations(userId);

      res.json({
        success: true,
        data: conversations,
      });
    } catch (error) {
      if (error instanceof CustomizedError) {
        res.status(error.statusCode).json({
          success: false,
          error: error.message
        });
      } else {
        res.status(500).json({
          success: false,
          error: "Error interno del servidor"
        });
      }
    }
  }

  /**
   * @swagger
   * /messages/conversations/{conversationId}/messages:
   *   get:
   *     summary: Get messages from a specific conversation
   *     tags: [Messages]
   *     security:
   *       - bearerAuth: []
   *     parameters:
   *       - in: path
   *         name: conversationId
   *         required: true
   *         schema:
   *           type: integer
   *           minimum: 1
   *         description: Conversation ID
   *     responses:
   *       200:
   *         description: Messages retrieved successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 success:
   *                   type: boolean
   *                   example: true
   *                 data:
   *                   type: array
   *                   items:
   *                     type: object
   *                     properties:
   *                       id:
   *                         type: integer
   *                         description: Message ID
   *                       conversationId:
   *                         type: integer
   *                         description: Conversation ID
   *                       senderId:
   *                         type: integer
   *                         description: Sender user ID
   *                       content:
   *                         type: string
   *                         description: Message content
   *                       sentAt:
   *                         type: string
   *                         format: date-time
   *                         description: Message sent timestamp
   *                       readAt:
   *                         type: string
   *                         format: date-time
   *                         nullable: true
   *                         description: Message read timestamp
   *                       sender:
   *                         type: object
   *                         properties:
   *                           id:
   *                             type: integer
   *                             description: Sender user ID
   *                           name:
   *                             type: string
   *                             description: Sender first name
   *                           surname:
   *                             type: string
   *                             description: Sender last name
   *       400:
   *         description: Validation error
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 success:
   *                   type: boolean
   *                   example: false
   *                 error:
   *                   type: string
   *                   example: "conversationId es requerido"
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  async getConversationMessages(req: AuthenticatedRequest, res: Response) {
    try {
      const { id: userId } = req.user!;
      const { conversationId } = req.params;

      if (!conversationId) {
        return res.status(400).json({
          success: false,
          error: "conversationId es requerido"
        });
      }

      const messages = await this.messageService.getConversationMessages(
        parseInt(conversationId),
        userId
      );

      res.json({
        success: true,
        data: messages,
      });
    } catch (error) {
      if (error instanceof CustomizedError) {
        res.status(error.statusCode).json({
          success: false,
          error: error.message
        });
      } else {
        res.status(500).json({
          success: false,
          error: "Error interno del servidor"
        });
      }
    }
  }

  /**
   * @swagger
   * /messages/unread-count:
   *   get:
   *     summary: Get unread messages count for user
   *     tags: [Messages]
   *     security:
   *       - bearerAuth: []
   *     responses:
   *       200:
   *         description: Unread count retrieved successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 success:
   *                   type: boolean
   *                   example: true
   *                 data:
   *                   type: object
   *                   properties:
   *                     unreadCount:
   *                       type: integer
   *                       minimum: 0
   *                       description: Number of unread messages
   *                       example: 5
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  async getUnreadCount(req: AuthenticatedRequest, res: Response) {
    try {
      const { id: userId } = req.user!;

      const count = await this.messageService.getUnreadCount(userId);

      res.json({
        success: true,
        data: { unreadCount: count },
      });
    } catch (error) {
      if (error instanceof CustomizedError) {
        res.status(error.statusCode).json({
          success: false,
          error: error.message
        });
      } else {
        res.status(500).json({
          success: false,
          error: "Error interno del servidor"
        });
      }
    }
  }

  /**
   * @swagger
   * /messages/conversations/{conversationId}/read:
   *   put:
   *     summary: Mark conversation messages as read
   *     tags: [Messages]
   *     security:
   *       - bearerAuth: []
   *     parameters:
   *       - in: path
   *         name: conversationId
   *         required: true
   *         schema:
   *           type: integer
   *           minimum: 1
   *         description: Conversation ID
   *     responses:
   *       200:
   *         description: Messages marked as read successfully
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 success:
   *                   type: boolean
   *                   example: true
   *                 message:
   *                   type: string
   *                   example: "Mensajes marcados como leídos"
   *       400:
   *         description: Validation error
   *         content:
   *           application/json:
   *             schema:
   *               type: object
   *               properties:
   *                 success:
   *                   type: boolean
   *                   example: false
   *                 error:
   *                   type: string
   *                   example: "conversationId es requerido"
   *       401:
   *         description: Unauthorized
   *       500:
   *         description: Internal server error
   */
  async markConversationAsRead(req: AuthenticatedRequest, res: Response) {
    try {
      const { id: userId } = req.user!;
      const { conversationId } = req.params;

      if (!conversationId) {
        return res.status(400).json({
          success: false,
          error: "conversationId es requerido"
        });
      }

      await this.messageService.markConversationAsRead(
        parseInt(conversationId),
        userId
      );

      res.json({
        success: true,
        message: "Mensajes marcados como leídos",
      });
    } catch (error) {
      if (error instanceof CustomizedError) {
        res.status(error.statusCode).json({
          success: false,
          error: error.message
        });
      } else {
        res.status(500).json({
          success: false,
          error: "Error interno del servidor"
        });
      }
    }
  }
}