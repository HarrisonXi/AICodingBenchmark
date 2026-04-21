# Statistics Display & List Enhancement Design

## Overview

Add statistics visualization and list enhancement features to the existing bookkeeping frontend app. All backend APIs are already implemented — this is a frontend-only change.

## Scope

Three feature areas:

1. **Category selection in record form** — already implemented (RecordForm.vue has category dropdown filtered by income/expense type)
2. **Statistics page** — new page showing monthly income/expense/balance summary and category breakdown donut chart
3. **List enhancement** — infinite scroll pagination + persistent filter bar (type/category/date range)

## Tech Stack Additions

| Library | Version | Purpose | Rationale |
|---|---|---|---|
| `chart.js` | ^4.x | Chart rendering (Canvas) | Lightweight (~60KB gzip), simple API, donut chart out of box. Matches project's "minimal dependencies" philosophy |
| `vue-chartjs` | ^5.x | Vue 3 wrapper for Chart.js | Provides reactive Vue components for Chart.js |

No other new dependencies.

## Backend APIs (Already Implemented)

### Pagination & Filtering — `GET /api/records`

| Parameter | Type | Default | Description |
|---|---|---|---|
| `page` | integer | `1` | Page number (min 1) |
| `pageSize` | integer | `20` | Items per page (1-100) |
| `isIncome` | `0` \| `1` | — | Filter by type |
| `categoryId` | integer | — | Filter by category |
| `startDate` | `YYYY-MM-DD` | — | Records on or after |
| `endDate` | `YYYY-MM-DD` | — | Records on or before |

Response: `{ data: { items: BookRecord[], pagination: { page, pageSize, total, totalPages } } }`

### Monthly Summary — `GET /api/statistics/monthly`

| Parameter | Type | Required | Description |
|---|---|---|---|
| `month` | `YYYY-MM` | Yes | Month to summarize |

Response: `{ data: { month, income, expense, balance } }` (amounts in cents)

### Category Breakdown — `GET /api/statistics/by-category`

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `month` | `YYYY-MM` | Yes | — | Month |
| `isIncome` | `0` \| `1` | No | `0` | Income or expense breakdown |

Response: `{ data: { month, isIncome, total, items: [{ categoryId, categoryName, icon, amount, percentage }] } }` (amounts in cents, percentage to 2 decimal places, ordered by amount DESC)

## Architecture

### New Files

| File | Purpose |
|---|---|
| `src/pages/StatisticsPage.vue` | Statistics page with month selector, summary cards, donut chart, category list |
| `src/components/BottomNav.vue` | Bottom navigation bar (3 items: records, add, statistics) |
| `src/components/RecordFilter.vue` | Persistent filter bar component (type, category, date range) |
| `src/api/statistics.ts` | API functions for `getMonthlyStatistics()` and `getCategoryBreakdown()` |

### Modified Files

| File | Change |
|---|---|
| `src/types/api.ts` | Add `MonthlyStatistics`, `CategoryBreakdownItem`, `CategoryBreakdown`, `PaginatedResponse<T>` types |
| `src/api/records.ts` | Update `getRecords()` to accept pagination and filter params, return paginated response |
| `src/pages/HomePage.vue` | Remove summary cards (moved to statistics), remove FAB, integrate filter bar, implement infinite scroll, adapt to paginated API |
| `src/components/RecordForm.vue` | No functional changes, but trigger mechanism changes (opened from BottomNav center button instead of FAB) |
| `src/App.vue` | Add `BottomNav` component, manage record creation modal at app level |
| `src/router/index.ts` | Add `/statistics` route |

### Unchanged Files

| File | Reason |
|---|---|
| `src/components/AppHeader.vue` | No changes needed |
| `src/components/RecordItem.vue` | No changes needed |
| `src/components/ConfirmDialog.vue` | No changes needed |
| `src/stores/auth.ts` | No changes needed |
| `src/stores/categories.ts` | No changes needed |
| `src/utils/http.ts` | No changes needed |
| `src/utils/format.ts` | No changes needed |
| `src/composables/useFormValidation.ts` | No changes needed |

## Component Design

### BottomNav.vue

- Fixed to bottom of viewport
- Three items: "明细" (records, links to `/`), center "+" button (opens RecordForm modal), "统计" (links to `/statistics`)
- Center button uses elevated circular design with gradient background
- Active tab highlighted with primary color
- Uses `router-link` or click handlers for navigation
- The "+" button emits an event to App.vue to open the RecordForm modal

### StatisticsPage.vue

Layout (top to bottom):
1. **Month selector** — left/right arrows + current month display (format: "2026年4月"). Default to current month. Cannot navigate beyond current month.
2. **Summary cards** — 3 cards in a row: income (green), expense (red), balance (blue). Data from `GET /api/statistics/monthly`.
3. **Income/Expense tab** — toggle between expense (default) and income breakdown
4. **Donut chart** — Chart.js doughnut chart showing category proportions. Center text shows total amount. Uses chart colors matching the category list below.
5. **Category list** — sorted by amount DESC. Each row: color dot, category name, amount, percentage.

State management:
- `currentMonth: string` — "YYYY-MM" format, reactive
- `monthlySummary: MonthlyStatistics | null` — from monthly API
- `categoryBreakdown: CategoryBreakdown | null` — from by-category API
- `isIncomeTab: boolean` — false = expense (default), true = income
- Loading states for each API call

Data fetching:
- On mount and when `currentMonth` changes: fetch both monthly summary and category breakdown
- On income/expense tab switch: fetch category breakdown only
- Use `watch` for reactive re-fetching

Empty state: when no data for the month, show a centered message "暂无数据"

### RecordFilter.vue

Layout: persistent two-row filter bar above the record list.
- Row 1: Type dropdown (全部/收入/支出) + Category dropdown (全部 + filtered by selected type)
- Row 2: Start date picker + End date picker

Props: none (manages its own state)
Emits: `filter-change(filters)` with `{ isIncome?: 0|1, categoryId?: number, startDate?: string, endDate?: string }`

Behavior:
- Category dropdown shows all categories when type is "全部", filtered by type when income/expense selected
- Changing type resets category to "全部"
- Date pickers use native `<input type="date">`
- Emits on every change (not on a "search" button click)

### HomePage.vue Changes

Remove:
- Summary cards (income/expense/balance) — now on StatisticsPage
- FAB button — replaced by BottomNav center button

Add:
- `RecordFilter` component at top of record list
- Infinite scroll logic:
  - Start with page 1, pageSize 20
  - `IntersectionObserver` on a sentinel element at bottom of list
  - When sentinel enters viewport and not already loading and `page < totalPages`: fetch next page, append items
  - Track: `records[]`, `page`, `totalPages`, `isLoading`, `filters`
  - On filter change: reset to page 1, clear records, fetch fresh

Keep:
- Record list rendering (RecordItem components)
- Edit/delete functionality (RecordForm modal, ConfirmDialog)
- After CRUD operations: reset list and re-fetch from page 1 with current filters

### App.vue Changes

- Add `BottomNav` component (shown only when authenticated)
- Lift RecordForm modal state to App.vue level (so the center "+" button in BottomNav can open it for **creating** new records)
- **Edit flow stays in HomePage**: HomePage still manages its own edit modal state. When user clicks edit on a RecordItem, HomePage opens RecordForm with `editRecord` prop. This avoids complex cross-component state for edits.
- Two separate modal triggers: App.vue controls "new record" modal (from BottomNav "+"), HomePage controls "edit record" modal (from RecordItem edit button)
- Add bottom padding to main content area to account for fixed BottomNav height

## Type Definitions

```typescript
// New types to add to types/api.ts

interface MonthlyStatistics {
  month: string
  income: number   // cents
  expense: number  // cents
  balance: number  // cents
}

interface CategoryBreakdownItem {
  categoryId: number
  categoryName: string
  icon: string
  amount: number      // cents
  percentage: number  // 0-100, 2 decimal places
}

interface CategoryBreakdown {
  month: string
  isIncome: number
  total: number  // cents
  items: CategoryBreakdownItem[]
}

interface Pagination {
  page: number
  pageSize: number
  total: number
  totalPages: number
}

interface PaginatedResponse<T> {
  items: T[]
  pagination: Pagination
}

interface RecordFilters {
  isIncome?: 0 | 1
  categoryId?: number
  startDate?: string
  endDate?: string
}
```

## API Functions

### `api/statistics.ts`

```typescript
getMonthlyStatistics(month: string): Promise<MonthlyStatistics>
// GET /api/statistics/monthly?month=YYYY-MM

getCategoryBreakdown(month: string, isIncome?: 0 | 1): Promise<CategoryBreakdown>
// GET /api/statistics/by-category?month=YYYY-MM&isIncome=0|1
```

### `api/records.ts` — Updated

```typescript
getRecords(params?: {
  page?: number
  pageSize?: number
  isIncome?: 0 | 1
  categoryId?: number
  startDate?: string
  endDate?: string
}): Promise<PaginatedResponse<BookRecord>>
// GET /api/records?page=1&pageSize=20&...
```

Note: The current `getRecords()` returns `BookRecord[]`. The updated version returns `PaginatedResponse<BookRecord>`. This is a breaking change to the return type — HomePage.vue must be updated accordingly.

## Routing

Add to `router/index.ts`:

```typescript
{
  path: '/statistics',
  name: 'statistics',
  component: () => import('../pages/StatisticsPage.vue'),
  meta: { requiresAuth: true }
}
```

## Styling

Follow existing conventions:
- All colors/spacing via CSS custom properties from `variables.css`
- Scoped `<style scoped>` in every component
- Income = green (`--color-income` / `var(--color-success)`), expense = red (`--color-expense` / `var(--color-danger)`)
- Max width 640px centered layout
- Mobile-first, touch-friendly targets

New CSS variables needed (add to `variables.css`):
- `--color-balance`: blue tone for balance display (e.g., `#60a5fa`)
- `--bottom-nav-height`: height of bottom nav bar (e.g., `56px`) for content padding

Chart colors: define a fixed palette array in StatisticsPage for category donut segments. Use warm/distinguishable colors.

## Edge Cases

- **No records in a month**: Statistics page shows ¥0 for all summary cards, donut chart shows empty state message "暂无数据"
- **Month navigation**: Cannot go beyond current month (right arrow disabled). No lower bound restriction.
- **Filter + infinite scroll**: Changing any filter resets pagination to page 1 and clears the record list
- **CRUD + filters**: After create/edit/delete, re-fetch from page 1 with current filters applied
- **Record form from BottomNav**: The "+" button opens RecordForm. After successful creation, if on HomePage, refresh the list. If on StatisticsPage, refresh statistics.
- **Loading states**: Show spinner/skeleton during API calls. Disable month navigation arrows during loading.
- **Empty filtered results**: Show "暂无记录" when filters produce no results
