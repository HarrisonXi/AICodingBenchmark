import type { BetterSQLite3Database } from 'drizzle-orm/better-sqlite3';
import { eq } from 'drizzle-orm';
import { categories } from './schema';
import type * as schema from './schema';

const presetCategories = [
  // 支出
  { name: '餐饮', icon: '🍽️', isIncome: 0 },
  { name: '交通', icon: '🚗', isIncome: 0 },
  { name: '购物', icon: '🛒', isIncome: 0 },
  { name: '娱乐', icon: '🎮', isIncome: 0 },
  { name: '居住', icon: '🏠', isIncome: 0 },
  { name: '医疗', icon: '💊', isIncome: 0 },
  { name: '教育', icon: '📚', isIncome: 0 },
  { name: '其他支出', icon: '📦', isIncome: 0 },
  // 收入
  { name: '工资', icon: '💰', isIncome: 1 },
  { name: '兼职', icon: '🤝', isIncome: 1 },
  { name: '理财', icon: '📈', isIncome: 1 },
  { name: '其他收入', icon: '💵', isIncome: 1 },
];

export function seedCategories(db: BetterSQLite3Database<typeof schema>) {
  const existing = db.select().from(categories).all();
  if (existing.length === 0) {
    db.insert(categories).values(presetCategories).run();
    return;
  }

  // 已有分类时，补充缺失的 icon
  for (const preset of presetCategories) {
    const row = existing.find(e => e.name === preset.name);
    if (row && !row.icon) {
      db.update(categories).set({ icon: preset.icon }).where(eq(categories.name, preset.name)).run();
    }
  }
}
