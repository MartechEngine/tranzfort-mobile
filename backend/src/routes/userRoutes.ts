import { Router } from 'express';
import { getProfile, updateProfile, getAllUsers, updateUser } from '../controllers/userController.js';
import { authMiddleware, adminGuard } from '../middleware/authMiddleware.js';

const router = Router();

router.get('/me', authMiddleware, getProfile);
router.patch('/me', authMiddleware, updateProfile);

// Admin routes
router.get('/', adminGuard, getAllUsers);
router.patch('/:id', adminGuard, updateUser);

export default router;
