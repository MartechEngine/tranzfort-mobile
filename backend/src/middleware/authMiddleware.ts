import { Request, Response, NextFunction } from 'express';
import { supabase, isSupabaseConfigured } from '../config/supabase.js';

// Extend Express Request type to include user
declare global {
  namespace Express {
    interface Request {
      user?: any;
    }
  }
}

export const authMiddleware = async (req: Request, res: Response, next: NextFunction) => {
  if (!isSupabaseConfigured) {
    return res.status(503).json({ error: 'Supabase is not configured on this server' });
  }

  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const { data: { user }, error } = await supabase.auth.getUser(token);

    if (error || !user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    req.user = user;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Unauthorized' });
  }
};

export const adminOnly = async (req: Request, res: Response, next: NextFunction) => {
  const localMode = (process.env.LOCAL_ADMIN_MODE ?? 'false').toLowerCase() === 'true';
  if (localMode) {
    if (req.admin?.role === 'ADMIN') {
      return next();
    }
    return res.status(401).json({ error: 'Unauthorized (admin token required)' });
  }

  if (!isSupabaseConfigured) {
    return res.status(503).json({ error: 'Supabase is not configured on this server' });
  }

  const userId = req.user?.id;

  if (!userId) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const { data: user, error } = await supabase
      .from('users')
      .select('role')
      .eq('id', userId)
      .single();

    if (error || !user || user.role !== 'ADMIN') {
      return res.status(403).json({ error: 'Forbidden: Admin access required' });
    }

    next();
  } catch (error) {
    res.status(500).json({ error: 'Internal server error' });
  }
};

export const adminGuard = async (req: Request, res: Response, next: NextFunction) => {
  const localMode = (process.env.LOCAL_ADMIN_MODE ?? 'false').toLowerCase() === 'true';
  if (localMode) {
    return adminOnly(req, res, next);
  }

  return authMiddleware(req, res, () => adminOnly(req, res, next));
};

