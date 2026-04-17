import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';

export const users = sqliteTable('users', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  username: text('username').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  createdAt: text('created_at').notNull(),
});

export const categories = sqliteTable('categories', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  name: text('name').notNull().unique(),
  isIncome: integer('is_income').notNull(), // 0=支出, 1=收入
});

export const records = sqliteTable('records', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  userId: integer('user_id').notNull().references(() => users.id),
  categoryId: integer('category_id').notNull().references(() => categories.id),
  isIncome: integer('is_income').notNull(), // 0=支出, 1=收入
  amount: integer('amount').notNull(), // 金额，分为单位
  note: text('note'),
  date: text('date').notNull(), // YYYY-MM-DD
  createdAt: text('created_at').notNull(),
});
