import { Router } from 'express';
import { initiateChat, sendMessage, getChatMessages, getMyChats } from '../controllers/chatController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = Router();

router.post('/initiate', authMiddleware, initiateChat);
router.post('/message', authMiddleware, sendMessage);
router.get('/:id/messages', authMiddleware, getChatMessages);
router.get('/my', authMiddleware, getMyChats);

export default router;
