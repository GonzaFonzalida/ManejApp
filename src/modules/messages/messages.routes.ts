import { Router } from "express";
import MessageController from "./messages.controller";
import MessageService from "./messages.services";
import PrismaMessageRepository from "./repositories/PrismaMessageRepository";
import { authenticate } from "@auth/auth.middlewares";
import { validateZodSchema } from "@shared/middlewares/validation";
import { sendMessageSchema, conversationIdSchema } from "./messages.schemas";

const router = Router();

// Initialize dependencies
const messageRepository = new PrismaMessageRepository();
const messageService = new MessageService(messageRepository);
const messageController = new MessageController(messageService);

// Apply authentication middleware to all routes
router.use(authenticate);

// Routes
router.post("/send", validateZodSchema(sendMessageSchema), messageController.sendMessage);
router.get("/conversations", messageController.getUserConversations);
router.get("/conversations/:conversationId/messages", validateZodSchema(conversationIdSchema), messageController.getConversationMessages);
router.get("/unread-count", messageController.getUnreadCount);
router.put("/conversations/:conversationId/read", validateZodSchema(conversationIdSchema), messageController.markConversationAsRead);

export default router;