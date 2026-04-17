import { Router } from 'express';
import { z } from 'zod';
import { eq, desc } from 'drizzle-orm';
import { db } from '../db';
import { records } from '../db/schema';
import { authMiddleware, type AuthRequest } from '../middleware/auth';
import { validate } from '../middleware/validate';

const router = Router();

// 所有记录路由都需要鉴权
router.use(authMiddleware);

const createRecordSchema = z.object({
  amount: z.number().int().positive(),
  isIncome: z.union([z.literal(0), z.literal(1)]),
  categoryId: z.number().int().positive(),
  note: z.string().max(200).optional(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be YYYY-MM-DD').optional(),
});

const updateRecordSchema = z.object({
  amount: z.number().int().positive().optional(),
  isIncome: z.union([z.literal(0), z.literal(1)]).optional(),
  categoryId: z.number().int().positive().optional(),
  note: z.string().max(200).optional(),
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be YYYY-MM-DD').optional(),
});

function today(): string {
  return new Date().toISOString().slice(0, 10);
}

// POST /api/records
router.post('/', validate(createRecordSchema), (req, res, next) => {
  try {
    const { userId } = (req as AuthRequest).user;
    const { amount, isIncome, categoryId, note, date } = req.body;

    const record = db.insert(records).values({
      userId,
      amount,
      isIncome,
      categoryId,
      note: note ?? null,
      date: date ?? today(),
      createdAt: new Date().toISOString(),
    }).returning().get();

    res.json({ data: record });
  } catch (err) {
    next(err);
  }
});

// GET /api/records
router.get('/', (req, res, next) => {
  try {
    const { userId } = (req as AuthRequest).user;
    const result = db.select().from(records)
      .where(eq(records.userId, userId))
      .orderBy(desc(records.date))
      .all();

    res.json({ data: result });
  } catch (err) {
    next(err);
  }
});

// GET /api/records/:id
router.get('/:id', (req, res, next) => {
  try {
    const { userId } = (req as AuthRequest).user;
    const id = parseInt(req.params.id, 10);
    if (isNaN(id)) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid record id' } });
      return;
    }

    const record = db.select().from(records).where(eq(records.id, id)).get();
    if (!record) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Record not found' } });
      return;
    }
    if (record.userId !== userId) {
      res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
      return;
    }

    res.json({ data: record });
  } catch (err) {
    next(err);
  }
});

// PUT /api/records/:id
router.put('/:id', validate(updateRecordSchema), (req, res, next) => {
  try {
    const { userId } = (req as AuthRequest).user;
    const id = parseInt(req.params.id, 10);
    if (isNaN(id)) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid record id' } });
      return;
    }

    const existing = db.select().from(records).where(eq(records.id, id)).get();
    if (!existing) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Record not found' } });
      return;
    }
    if (existing.userId !== userId) {
      res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
      return;
    }

    const updated = db.update(records)
      .set(req.body)
      .where(eq(records.id, id))
      .returning().get();

    res.json({ data: updated });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/records/:id
router.delete('/:id', (req, res, next) => {
  try {
    const { userId } = (req as AuthRequest).user;
    const id = parseInt(req.params.id, 10);
    if (isNaN(id)) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Invalid record id' } });
      return;
    }

    const existing = db.select().from(records).where(eq(records.id, id)).get();
    if (!existing) {
      res.status(404).json({ error: { code: 'NOT_FOUND', message: 'Record not found' } });
      return;
    }
    if (existing.userId !== userId) {
      res.status(403).json({ error: { code: 'FORBIDDEN', message: 'Access denied' } });
      return;
    }

    db.delete(records).where(eq(records.id, id)).run();
    res.json({ data: { message: 'deleted' } });
  } catch (err) {
    next(err);
  }
});

export default router;
