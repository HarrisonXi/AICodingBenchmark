/** 分转元，返回格式化字符串 */
export function centsToYuan(cents: number): string {
  return (cents / 100).toFixed(2)
}

/** 元转分，四舍五入为整数 */
export function yuanToCents(yuan: string): number {
  return Math.round(parseFloat(yuan) * 100)
}

/** 格式化日期为 YYYY-MM-DD */
export function formatDate(date: Date): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}

/** 获取今天的日期字符串 */
export function today(): string {
  return formatDate(new Date())
}
