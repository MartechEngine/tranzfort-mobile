import type { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const getEnv = (key: string): string => {
  const val = process.env[key];
  if (!val) throw new Error(`${key} is not set`);
  return val;
};

export const adminLogin = async (req: Request, res: Response) => {
  try {
    const localMode = (process.env.LOCAL_ADMIN_MODE ?? 'false').toLowerCase() === 'true';
    if (!localMode) {
      return res.status(403).json({ error: 'LOCAL_ADMIN_MODE is disabled' });
    }

    const { username, password } = req.body ?? {};
    if (!username || !password) {
      return res.status(400).json({ error: 'username and password are required' });
    }

    const adminUser = getEnv('ADMIN_USERNAME');
    const adminPasswordHash = getEnv('ADMIN_PASSWORD_HASH');
    const jwtSecret = getEnv('ADMIN_JWT_SECRET');

    if (username !== adminUser) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const ok = await bcrypt.compare(password, adminPasswordHash);
    if (!ok) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      {
        sub: 'local-admin',
        role: 'ADMIN',
        username,
      },
      jwtSecret,
      {
        expiresIn: '12h',
      },
    );

    return res.status(200).json({ token });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown error';
    return res.status(500).json({ error: message });
  }
};
