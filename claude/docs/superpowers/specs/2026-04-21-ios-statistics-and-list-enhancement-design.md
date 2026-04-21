# iOS Statistics Display & List Enhancement Design

## Overview

Add statistics visualization and list enhancement features to the existing iOS bookkeeping app (`Bookkeeping.xcodeproj`). All backend APIs are already implemented — this is an iOS client-only change. Design mirrors the Vue 3 frontend spec, adapted to UIKit/MVC conventions.

## Scope

Three feature areas:

1. **Category selection in record form** — already implemented (`RecordFormViewController` has horizontal `UICollectionView` category picker filtered by income/expense toggle)
2. **Statistics page** — new page showing monthly income/expense/balance summary and category breakdown donut chart
3. **List enhancement** — infinite scroll pagination + persistent filter bar (type/category/date range)

## Tech Stack Additions

| Item | Choice | Rationale |
|---|---|---|
| Donut chart | CoreGraphics (`UIBezierPath` + `CAShapeLayer`) | Zero dependency, ~150 lines. Project has zero third-party deps — a full charting library is overkill for one donut chart |
| Bottom navigation | Custom `UITabBarController` subclass | Native iOS tab pattern + custom elevated center "+" button |
| Filter dropdowns | `UIMenu` (iOS 14+) | Native dropdown menu, lighter than UIPickerView, modern feel |
| Date pickers | `UIDatePicker` (compact style) | Already used in RecordFormViewController |
| Infinite scroll | `UITableViewDelegate.willDisplay` | Simple threshold check, no extra API needed |

No new third-party dependencies added.

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
| `Controllers/MainTabBarController.swift` | Custom UITabBarController with "records" tab, center "+" button, "statistics" tab |
| `Controllers/StatisticsViewController.swift` | Statistics page: month selector, summary cards, segment control, donut chart, category list |
| `Views/DonutChartView.swift` | Reusable CoreGraphics donut chart component |
| `Services/StatisticsService.swift` | API functions for monthly summary and category breakdown |
| `Models/StatisticsModels.swift` | `MonthlyStatistics`, `CategoryBreakdownItem`, `CategoryBreakdown`, `PaginatedResponse<T>`, `Pagination` types |

### Modified Files

| File | Change |
|---|---|
| `SceneDelegate.swift` | Root view controller changes from `UINavigationController(RecordListVC)` to `MainTabBarController` when authenticated |
| `RecordListViewController.swift` | Remove summary cards (moved to statistics page), remove FAB button (moved to tab bar), add filter bar as tableHeaderView, add infinite scroll pagination logic |
| `RecordService.swift` | Update `getRecords()` to accept pagination and filter params, return `PaginatedResponse<BookRecord>` |
| `RecordFormViewController.swift` | No functional changes; trigger mechanism changes (created from TabBar "+" as modal for new records; edit still pushes from list) |

### Unchanged Files

| File | Reason |
|---|---|
| `LoginViewController.swift` | No changes needed |
| `RegisterViewController.swift` | No changes needed |
| `AuthService.swift` | No changes needed |
| `CategoryService.swift` | No changes needed |
| `APIClient.swift` | No changes needed |
| `KeychainHelper.swift` | No changes needed |
| `AuthManager.swift` | No changes needed |
| `AmountFormatter.swift` | No changes needed |
| `DateHelper.swift` | No changes needed |
| `UIHelpers.swift` | No changes needed |
| `KeyboardHelper.swift` | No changes needed |

## Data Models

### New Types (`Models/StatisticsModels.swift`)

```swift
struct MonthlyStatistics: Decodable {
    let month: String
    let income: Int    // cents
    let expense: Int   // cents
    let balance: Int   // cents
}

struct CategoryBreakdownItem: Decodable {
    let categoryId: Int
    let categoryName: String
    let amount: Int       // cents
    let percentage: Double // 0-100, 2 decimal places
}

struct CategoryBreakdown: Decodable {
    let month: String
    let isIncome: Int
    let total: Int  // cents
    let items: [CategoryBreakdownItem]
}

struct Pagination: Decodable {
    let page: Int
    let pageSize: Int
    let total: Int
    let totalPages: Int
}

struct PaginatedResponse<T: Decodable>: Decodable {
    let items: [T]
    let pagination: Pagination
}
```

Note: `PaginatedResponse` needs a custom `Decodable` init because the backend wraps it in `{ data: { items, pagination } }` which is already unwrapped by `APIClient`. The struct decodes from the inner `{ items, pagination }` object directly.

## API Functions

### `Services/StatisticsService.swift`

```swift
enum StatisticsService {
    static func getMonthlyStatistics(month: String) async throws -> MonthlyStatistics
    // GET /api/statistics/monthly?month=YYYY-MM

    static func getCategoryBreakdown(month: String, isIncome: Int = 0) async throws -> CategoryBreakdown
    // GET /api/statistics/by-category?month=YYYY-MM&isIncome=0|1
}
```

### `Services/RecordService.swift` — Updated

```swift
// Current signature:
static func getRecords() async throws -> [BookRecord]

// New signature:
static func getRecords(
    page: Int = 1,
    pageSize: Int = 20,
    isIncome: Int? = nil,
    categoryId: Int? = nil,
    startDate: String? = nil,
    endDate: String? = nil
) async throws -> PaginatedResponse<BookRecord>
```

This is a breaking change to the return type. `RecordListViewController` must be updated to handle `PaginatedResponse<BookRecord>` instead of `[BookRecord]`.

## Component Design

### MainTabBarController

- Subclass of `UITabBarController`
- Two real tabs:
  - Tab 0: `RecordListViewController` wrapped in `UINavigationController`, title "明细", system icon `list.bullet`
  - Tab 1: `StatisticsViewController` wrapped in `UINavigationController`, title "统计", system icon `chart.pie`
- Center "+" button: `UIButton` positioned above the tab bar, elevated with circular gradient background (matching frontend design: gradient from `#7c8aff` to `#6366f1`, drop shadow)
- "+" button tap: present `RecordFormViewController` wrapped in `UINavigationController` as `.formSheet` modal
- After record creation: post `Notification.Name("RecordDidChange")` so the active tab can refresh
- Both RecordListVC and StatisticsVC observe this notification to reload data

### StatisticsViewController

Layout: `UIScrollView` > `UIStackView` (vertical, spacing 16):

1. **Month selector** — horizontal stack: left arrow button + month label ("2026年4月") + right arrow button
   - Default to current month
   - Right arrow disabled when showing current month
   - No lower bound restriction
   - Arrow buttons disabled during loading

2. **Summary cards** — horizontal stack of 3 cards:
   - Income card: light green background, "收入" label, green amount
   - Expense card: light red background, "支出" label, red amount
   - Balance card: light blue background, "结余" label, blue amount
   - Amounts formatted with `AmountFormatter.centsToYuan()`

3. **Income/Expense toggle** — `UISegmentedControl` with two segments: "支出" (default, index 0) and "收入" (index 1)

4. **Donut chart** — `DonutChartView` (custom view, see below)
   - Fixed height: 200pt (chart 160pt + padding)
   - Center text: total amount + "总支出"/"总收入" label
   - Empty state: "暂无数据" centered text

5. **Category list** — vertical stack of category rows, each row:
   - Color dot (8pt circle) + category name label + spacer + amount label + percentage label
   - Colors from a fixed palette array matching the donut segments
   - Sorted by amount descending (server returns this order)

State:
- `currentMonth: String` — "YYYY-MM" format
- `monthlySummary: MonthlyStatistics?`
- `categoryBreakdown: CategoryBreakdown?`
- `isExpenseTab: Bool` — `true` (default) = expense, `false` = income
- `isLoading: Bool`

Data fetching:
- On `viewWillAppear` and month change: fetch both monthly summary and category breakdown concurrently using `async let`
- On segment change: fetch category breakdown only
- On `RecordDidChange` notification: re-fetch with current month/tab

### DonutChartView

Custom `UIView` subclass using CoreGraphics:

- Input: `segments: [(value: Double, color: UIColor)]` + `centerText: String` + `centerSubtext: String`
- Drawing: `CAShapeLayer` arcs for each segment, calculated from proportional angles
- Center: two `UILabel` subviews for center text (amount) and subtext ("总支出")
- Empty state: single gray arc with "暂无数据" label
- Animation: optional `CABasicAnimation` on `strokeEnd` for initial draw

### RecordListViewController Changes

**Remove:**
- Summary header view (income/expense/balance cards) — moved to StatisticsViewController
- FAB "+" button — replaced by MainTabBarController center button

**Add: Filter bar** (as `tableHeaderView`, fixed at top of the table):
- Two-row layout in a container UIView:
  - Row 1: Type button (`UIButton` with `UIMenu`: 全部/收入/支出) + Category button (`UIButton` with `UIMenu`: 全部 + type-filtered categories)
  - Row 2: Start date (`UIDatePicker` compact) + End date (`UIDatePicker` compact)
- Category menu rebuilds when type changes; changing type resets category to "全部"
- Any filter change: reset to page 1, clear `records` array, fetch fresh

**Add: Infinite scroll pagination:**
- State: `records: [BookRecord]`, `currentPage: Int`, `totalPages: Int`, `isLoadingMore: Bool`, `filters: RecordFilters`
- `RecordFilters` struct: `isIncome: Int?`, `categoryId: Int?`, `startDate: String?`, `endDate: String?`
- Initial load: page 1, pageSize 20
- `tableView(_:willDisplay:forRowAt:)`: when indexPath.row >= records.count - 3, and not loading, and currentPage < totalPages → load next page
- Next page: increment currentPage, call `RecordService.getRecords(page:...)`, append results to `records` array
- `tableFooterView`: `UIActivityIndicatorView` shown during page loads
- After CRUD: reset to page 1 with current filters, re-fetch

**Keep:**
- `RecordCell` rendering
- Swipe-to-delete
- Tap-to-edit (push `RecordFormViewController`)
- Delete confirmation alert

### RecordFormViewController Changes

No functional changes. Two trigger paths:
1. **Create (new)**: Presented as modal from `MainTabBarController` "+" button. Has a "取消" left bar button to dismiss.
2. **Edit**: Pushed via navigation controller from `RecordListViewController` row tap. Existing back button behavior.

Both paths already exist conceptually. The modal presentation for "create" needs a cancel button and navigation bar, which is achieved by wrapping in `UINavigationController` before presenting.

### SceneDelegate Changes

```swift
// Current (authenticated):
let nav = UINavigationController(rootViewController: RecordListViewController())
window.rootViewController = nav

// New (authenticated):
let tabBar = MainTabBarController()
window.rootViewController = tabBar
```

The `switchToMain()` and `switchToLogin()` methods update accordingly.

## Edge Cases

- **No records in a month**: Statistics shows ¥0.00 for all summary cards; donut chart shows "暂无数据"
- **Month navigation**: Right arrow disabled when showing current month. No lower bound.
- **Filter + pagination**: Any filter change resets to page 1 and clears the record list
- **CRUD + filters**: After create/edit/delete, re-fetch from page 1 with current filters
- **Record creation from any tab**: "+" button works on both tabs. After creation, post notification so active tab refreshes.
- **Loading states**: Disable month arrows during loading. Show footer spinner during page loads. Disable filter controls during loading.
- **Empty filtered results**: Show "暂无记录" centered in the table view (using `backgroundView`)
- **Category breakdown empty**: When a month has no expense/income records for the selected tab, show donut empty state
