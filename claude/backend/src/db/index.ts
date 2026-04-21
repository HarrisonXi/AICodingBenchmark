import Database from 'better-sqlite3';
import { drizzle } from 'drizzle-orm/better-sqlite3';
import * as schema from './schema';
import { seedCategories } from './seed';

const sqlite = new Database('bookkeeping.db');
sqlite.pragma('journal_mode = WAL');
sqlite.pragma('foreign_keys = ON');

export const db = drizzle(sqlite, { schema });

// 建表（如果不存在）
export function initDatabase() {
  sqlite.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS categories (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      icon TEXT NOT NULL DEFAULT '',
      is_income INTEGER NOT NULL
    );

    CREATE TABLE IF NOT EXISTS records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id),
      category_id INTEGER NOT NULL REFERENCES categories(id),
      is_income INTEGER NOT NULL,
      amount INTEGER NOT NULL,
      note TEXT,
      date TEXT NOT NULL,
      created_at TEXT NOT NULL
    );
  `);

  // 兼容升级：已有数据库添加 icon 列
  const cols = sqlite.pragma('table_info(categories)') as { name: string }[];
  if (!cols.some(c => c.name === 'icon')) {
    sqlite.exec(`ALTER TABLE categories ADD COLUMN icon TEXT NOT NULL DEFAULT ''`);
  }

  seedCategories(db);
}
