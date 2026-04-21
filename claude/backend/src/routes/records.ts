import { Router } from 'express';
import { z } from 'zod';
import { eq, desc, and, gte, lte, count, type SQL } from 'drizzle-orm';
import { db } from '../db';
import { records, categories } from '../db/schema';
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

    // 校验 categoryId 是否存在
    const category = db.select().from(categories).where(eq(categories.id, categoryId)).get();
    if (!category) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Category not found' } });
      return;
    }

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

const dateRegex = /^\d{4}-\d{2}-\d{2}$/;

// GET /api/records — 分页 + 筛选
router.get('/', (req, res, next) => {
  try {
    const { userId } = (req as AuthRequest).user;

    // 解析分页参数
    const page = Math.max(1, parseInt(req.query.page as string, 10) || 1);
    const pageSize = Math.min(100, Math.max(1, parseInt(req.query.pageSize as string, 10) || 20));

    // 构建筛选条件
    const conditions: SQL[] = [eq(records.userId, userId)];

    if (req.query.isIncome !== undefined) {
      const isIncome = parseInt(req.query.isIncome as string, 10);
      if (isIncome === 0 || isIncome === 1) {
        conditions.push(eq(records.isIncome, isIncome));
      }
    }

    if (req.query.categoryId !== undefined) {
      const categoryId = parseInt(req.query.categoryId as string, 10);
      if (!isNaN(categoryId) && categoryId > 0) {
        conditions.push(eq(records.categoryId, categoryId));
      }
    }

    if (req.query.startDate && dateRegex.test(req.query.startDate as string)) {
      conditions.push(gte(records.date, req.query.startDate as string));
    }

    if (req.query.endDate && dateRegex.test(req.query.endDate as string)) {
      conditions.push(lte(records.date, req.query.endDate as string));
    }

    const where = and(...conditions)!;

    // 查询总数
    const [{ total }] = db.select({ total: count() }).from(records).where(where).all();

    // 查询分页数据
    const offset = (page - 1) * pageSize;
    const items = db.select().from(records)
      .where(where)
      .orderBy(desc(records.date))
      .limit(pageSize)
      .offset(offset)
      .all();

    res.json({
      data: {
        items,
        pagination: {
          page,
          pageSize,
          total,
          totalPages: Math.ceil(total / pageSize),
        },
      },
    });
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

    // 若更新 categoryId，校验其是否存在
    if (req.body.categoryId !== undefined) {
      const category = db.select().from(categories).where(eq(categories.id, req.body.categoryId)).get();
      if (!category) {
        res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'Category not found' } });
        return;
      }
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
