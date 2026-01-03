import type { NextFunction, Request, Response } from 'express';
import jwt from 'jsonwebtoken';

declare global {
  namespace Express {
    interface Request {
      admin?: {
        username: string;
        role: 'ADMIN';
      };
    }
  }
}

export const adminJwtMiddleware = (req: Request, _res: Response, next: NextFunction) => {
  const localMode = (process.env.LOCAL_ADMIN_MODE ?? 'false').toLowerCase() === 'true';
  if (!localMode) return next();

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  const token = authHeader.split(' ')[1];
  const secret = process.env.ADMIN_JWT_SECRET;
  if (!secret) {
    return next();
  }

  try {
    const decoded = jwt.verify(token, secret) as any;
    if (decoded?.role === 'ADMIN' && typeof decoded?.username === 'string') {
      req.admin = { username: decoded.username, role: 'ADMIN' };
    }
  } catch {
    // ignore; adminOnly will enforce
  }

  return next();
};
