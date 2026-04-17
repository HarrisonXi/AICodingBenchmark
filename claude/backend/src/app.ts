import express from 'express';
import authRoutes from './routes/auth';
import recordsRoutes from './routes/records';
import categoriesRoutes from './routes/categories';
import { errorHandler } from './utils/errors';

const app = express();

app.use(express.json());

// 路由
app.use('/api/auth', authRoutes);
app.use('/api/records', recordsRoutes);
app.use('/api/categories', categoriesRoutes);

// 全局错误处理（必须在路由之后）
app.use(errorHandler);

export default app;
