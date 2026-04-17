import { Router } from 'express';
import { db } from '../db';
import { categories } from '../db/schema';

const router = Router();

// GET /api/categories — 公开接口，无需鉴权
router.get('/', (_req, res, next) => {
  try {
    const result = db.select().from(categories).all();
    res.json({ data: result });
  } catch (err) {
    next(err);
  }
});

export default router;
