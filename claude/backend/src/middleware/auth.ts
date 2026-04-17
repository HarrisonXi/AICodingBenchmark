import type { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { eq } from 'drizzle-orm';
import { config } from '../config';
import { db } from '../db';
import { users } from '../db/schema';

// 扩展 Express Request 类型
export interface AuthRequest extends Request {
  user: { userId: number; username: string };
}

export function authMiddleware(req: Request, res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header || !header.startsWith('Bearer ')) {
    res.status(401).json({
      error: { code: 'UNAUTHORIZED', message: 'Missing or invalid token' },
    });
    return;
  }

  const token = header.slice(7);
  try {
    const payload = jwt.verify(token, config.jwtSecret) as { userId: number; username: string };
    // 检查用户是否仍存在于数据库
    const user = db.select({ id: users.id }).from(users).where(eq(users.id, payload.userId)).get();
    if (!user) {
      res.status(401).json({
        error: { code: 'UNAUTHORIZED', message: 'User no longer exists' },
      });
      return;
    }
    (req as AuthRequest).user = { userId: payload.userId, username: payload.username };
    next();
  } catch {
    res.status(401).json({
      error: { code: 'UNAUTHORIZED', message: 'Invalid or expired token' },
    });
  }
}
