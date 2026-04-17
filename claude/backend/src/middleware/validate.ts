import type { Request, Response, NextFunction } from 'express';
import type { ZodSchema } from 'zod';
import { ZodError } from 'zod';

// 对 req.body 做 Zod 校验的中间件工厂
export function validate(schema: ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (err) {
      if (err instanceof ZodError) {
        const message = err.errors.map((e) => `${e.path.join('.')}: ${e.message}`).join('; ');
        res.status(400).json({
          error: { code: 'VALIDATION_ERROR', message },
        });
        return;
      }
      next(err);
    }
  };
}
