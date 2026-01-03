import { Router } from 'express';
import {
  createVerificationPayment,
  confirmVerificationPayment,
  getVerificationPaymentStatus,
} from '../controllers/paymentController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = Router();

router.post('/verification/create', authMiddleware, createVerificationPayment);
router.post('/verification/confirm', authMiddleware, confirmVerificationPayment);
router.get('/verification/status', authMiddleware, getVerificationPaymentStatus);

export default router;
