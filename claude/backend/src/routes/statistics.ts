import { Router } from 'express';
import { eq, and, like, sql } from 'drizzle-orm';
import { db } from '../db';
import { records, categories } from '../db/schema';
import { authMiddleware, type AuthRequest } from '../middleware/auth';

const router = Router();

router.use(authMiddleware);

const monthRegex = /^\d{4}-\d{2}$/;

// GET /api/statistics/monthly?month=2026-04 — 月度收支汇总
router.get('/monthly', (req, res, next) => {
  try {
    const { userId } = (req as AuthRequest).user;
    const month = req.query.month as string;

    if (!month || !monthRegex.test(month)) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'month is required, format: YYYY-MM' } });
      return;
    }

    // 按 is_income 分组求和
    const rows = db.select({
      isIncome: records.isIncome,
      total: sql<number>`COALESCE(SUM(${records.amount}), 0)`.as('total'),
    })
      .from(records)
      .where(and(
        eq(records.userId, userId),
        like(records.date, `${month}%`),
      ))
      .groupBy(records.isIncome)
      .all();

    let income = 0;
    let expense = 0;
    for (const row of rows) {
      if (row.isIncome === 1) income = row.total;
      else expense = row.total;
    }

    res.json({
      data: {
        month,
        income,
        expense,
        balance: income - expense,
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/statistics/by-category?month=2026-04&isIncome=0 — 分类占比
router.get('/by-category', (req, res, next) => {
  try {
    const { userId } = (req as AuthRequest).user;
    const month = req.query.month as string;

    if (!month || !monthRegex.test(month)) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'month is required, format: YYYY-MM' } });
      return;
    }

    // 默认查支出
    const isIncome = req.query.isIncome !== undefined
      ? parseInt(req.query.isIncome as string, 10)
      : 0;
    if (isIncome !== 0 && isIncome !== 1) {
      res.status(400).json({ error: { code: 'VALIDATION_ERROR', message: 'isIncome must be 0 or 1' } });
      return;
    }

    const rows = db.select({
      categoryId: records.categoryId,
      categoryName: categories.name,
      icon: categories.icon,
      amount: sql<number>`COALESCE(SUM(${records.amount}), 0)`.as('amount'),
    })
      .from(records)
      .innerJoin(categories, eq(records.categoryId, categories.id))
      .where(and(
        eq(records.userId, userId),
        eq(records.isIncome, isIncome),
        like(records.date, `${month}%`),
      ))
      .groupBy(records.categoryId)
      .orderBy(sql`amount DESC`)
      .all();

    const total = rows.reduce((sum, r) => sum + r.amount, 0);

    const items = rows.map(r => ({
      categoryId: r.categoryId,
      categoryName: r.categoryName,
      icon: r.icon,
      amount: r.amount,
      percentage: total > 0 ? Math.round(r.amount / total * 10000) / 100 : 0,
    }));

    res.json({
      data: {
        month,
        isIncome,
        total,
        items,
      },
    });
  } catch (err) {
    next(err);
  }
});

export default router;
