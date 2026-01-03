import { Router } from 'express';
import { createLoad, getMyLoads, searchLoads, getLoadById } from '../controllers/loadController.js';
import { authMiddleware } from '../middleware/authMiddleware.js';

const router = Router();

router.post('/', authMiddleware, createLoad);
router.get('/my', authMiddleware, getMyLoads);
router.get('/', authMiddleware, searchLoads);
router.get('/:id', authMiddleware, getLoadById);

export default router;
