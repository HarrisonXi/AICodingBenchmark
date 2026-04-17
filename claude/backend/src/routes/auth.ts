import { Router } from 'express';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { eq } from 'drizzle-orm';
import { db } from '../db';
import { users } from '../db/schema';
import { config } from '../config';
import { validate } from '../middleware/validate';

const router = Router();

const registerSchema = z.object({
  username: z.string().min(3).max(32),
  password: z.string().min(6).max(64),
});

const loginSchema = z.object({
  username: z.string().min(1),
  password: z.string().min(1),
});

function generateToken(userId: number, username: string): string {
  return jwt.sign({ userId, username }, config.jwtSecret, { expiresIn: config.jwtExpiresIn });
}

// POST /api/auth/register
router.post('/register', validate(registerSchema), (req, res, next) => {
  try {
    const { username, password } = req.body;

    // 检查用户名是否已存在
    const existing = db.select().from(users).where(eq(users.username, username)).get();
    if (existing) {
      res.status(409).json({
        error: { code: 'CONFLICT', message: 'Username already exists' },
      });
      return;
    }

    const passwordHash = bcrypt.hashSync(password, config.bcryptSaltRounds);
    const result = db.insert(users).values({
      username,
      passwordHash,
      createdAt: new Date().toISOString(),
    }).returning().get();

    const token = generateToken(result.id, result.username);
    res.json({ data: { id: result.id, username: result.username, token } });
  } catch (err) {
    next(err);
  }
});

// POST /api/auth/login
router.post('/login', validate(loginSchema), (req, res, next) => {
  try {
    const { username, password } = req.body;

    const user = db.select().from(users).where(eq(users.username, username)).get();
    if (!user || !bcrypt.compareSync(password, user.passwordHash)) {
      res.status(401).json({
        error: { code: 'UNAUTHORIZED', message: 'Invalid username or password' },
      });
      return;
    }

    const token = generateToken(user.id, user.username);
    res.json({ data: { id: user.id, username: user.username, token } });
  } catch (err) {
    next(err);
  }
});

export default router;
