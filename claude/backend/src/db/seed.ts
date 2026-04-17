import type { BetterSQLite3Database } from 'drizzle-orm/better-sqlite3';
import { categories } from './schema';
import type * as schema from './schema';

const presetCategories = [
  // 支出
  { name: '餐饮', isIncome: 0 },
  { name: '交通', isIncome: 0 },
  { name: '购物', isIncome: 0 },
  { name: '娱乐', isIncome: 0 },
  { name: '居住', isIncome: 0 },
  { name: '医疗', isIncome: 0 },
  { name: '教育', isIncome: 0 },
  { name: '其他支出', isIncome: 0 },
  // 收入
  { name: '工资', isIncome: 1 },
  { name: '兼职', isIncome: 1 },
  { name: '理财', isIncome: 1 },
  { name: '其他收入', isIncome: 1 },
];

export function seedCategories(db: BetterSQLite3Database<typeof schema>) {
  const existing = db.select().from(categories).all();
  if (existing.length > 0) return; // 已有数据则跳过

  db.insert(categories).values(presetCategories).run();
}
