import { Router } from "express";
import MessageController from "./messages.controller";
import MessageService from "./messages.services";
import PrismaMessageRepository from "./repositories/PrismaMessageRepository";
import { authenticate } from "@auth/auth.middlewares";
import { validateZodSchema } from "@shared/middlewares/validation";
import { validateParams } from "@shared/middlewares/zod/validateParams";
import { sendMessageSchema, conversationIdParamSchema } from "./messages.schemas";

const router = Router();

// Initialize dependencies
const messageRepository = new PrismaMessageRepository();
const messageService = new MessageService(messageRepository);
const messageController = new MessageController(messageService);

// Apply authentication middleware to all routes
router.use(authenticate);

const c = messageController;
// bind: Express pasa los handlers sin `this` (evita undefined messageService).
router.post("/send", validateZodSchema(sendMessageSchema), c.sendMessage.bind(c));
router.get("/conversations", c.getUserConversations.bind(c));
router.get(
  "/conversations/:conversationId/messages",
  validateParams(conversationIdParamSchema),
  c.getConversationMessages.bind(c)
);
router.get("/unread-count", c.getUnreadCount.bind(c));
router.put(
  "/conversations/:conversationId/read",
  validateParams(conversationIdParamSchema),
  c.markConversationAsRead.bind(c)
);

export default router;