import { Request, Response, NextFunction } from 'express';
import { supabase, isSupabaseConfigured } from '../config/supabase.js';
import { verifyToken, TokenPayload } from '../services/tokenService.js';

// Extend Express Request type to include user and role
declare global {
  namespace Express {
    interface Request {
      user?: TokenPayload;
      supabaseUser?: any; // Original Supabase user if needed
    }
  }
}

export const authMiddleware = async (req: Request, res: Response, next: NextFunction) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'No token provided' });
  }

  const token = authHeader.split(' ')[1];

  try {
    const payload = verifyToken(token);
    req.user = payload;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
};

export const roleGuard = (allowedRoles: ('ADMIN' | 'SUPPLIER' | 'TRUCKER')[]) => {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ error: `Forbidden: Requires one of roles: ${allowedRoles.join(', ')}` });
    }

    next();
  };
};

export const adminOnly = roleGuard(['ADMIN']);

export const adminGuard = async (req: Request, res: Response, next: NextFunction) => {
  const localMode = (process.env.LOCAL_ADMIN_MODE ?? 'false').toLowerCase() === 'true';
  if (localMode) {
    // Legacy support for local mode if needed, otherwise rely on custom JWT
    return next();
  }

  return authMiddleware(req, res, () => adminOnly(req, res, next));
};

