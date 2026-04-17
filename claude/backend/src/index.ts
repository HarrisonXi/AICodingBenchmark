import app from './app';
import { config } from './config';
import { initDatabase } from './db';

// 初始化数据库（建表 + 种子数据）
initDatabase();

app.listen(config.port, () => {
  console.log(`Server running on http://localhost:${config.port}`);
});
