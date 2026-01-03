import { Router } from 'express';
import { submitVerification, getMyVerificationStatus } from '../controllers/verificationController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = Router();

router.post('/submit', authMiddleware, submitVerification);
router.get('/status', authMiddleware, getMyVerificationStatus);

export default router;
