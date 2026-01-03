import { Router } from 'express';
import { 
  getAdminStats, 
  getPendingVerifications, 
  approveVerification, 
  rejectVerification, 
  getAllLoads,
  deleteLoad
} from '../controllers/adminController.js';
import { adminGuard } from '../middleware/authMiddleware.js';

const router = Router();

router.get('/stats', adminGuard, getAdminStats);
router.get('/verifications', adminGuard, getPendingVerifications);
router.post('/verifications/:id/approve', adminGuard, approveVerification);
router.post('/verifications/:id/reject', adminGuard, rejectVerification);

router.get('/loads', adminGuard, getAllLoads);
router.delete('/loads/:id', adminGuard, deleteLoad);

export default router;
