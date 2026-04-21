<script setup lang="ts">
import { ref, computed, watch, onMounted } from 'vue'
import { Chart as ChartJS, ArcElement, Tooltip, Legend } from 'chart.js'
import { Doughnut } from 'vue-chartjs'
import type { MonthlyStatistics, CategoryBreakdown } from '@/types/api'
import { getMonthlyStatistics, getCategoryBreakdown } from '@/api/statistics'
import { centsToYuan } from '@/utils/format'
import { ApiError } from '@/utils/http'

ChartJS.register(ArcElement, Tooltip, Legend)

const CHART_COLORS = [
  '#f87171', '#fb923c', '#fbbf24', '#a78bfa',
  '#34d399', '#60a5fa', '#f472b6', '#818cf8',
]

const currentMonth = ref(getCurrentMonth())
const monthlySummary = ref<MonthlyStatistics | null>(null)
const categoryBreakdown = ref<CategoryBreakdown | null>(null)
const isIncomeTab = ref(false)
const loading = ref(false)
const error = ref('')

function getCurrentMonth(): string {
  const d = new Date()
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
}

const displayMonth = computed(() => {
  const [y, m] = currentMonth.value.split('-')
  return `${y}年${parseInt(m)}月`
})

const isCurrentMonth = computed(() => currentMonth.value === getCurrentMonth())

function changeMonth(delta: number) {
  const [y, m] = currentMonth.value.split('-').map(Number)
  const d = new Date(y, m - 1 + delta, 1)
  currentMonth.value = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`
}

const chartData = computed(() => {
  const items = categoryBreakdown.value?.items ?? []
  return {
    labels: items.map((i) => i.categoryName),
    datasets: [
      {
        data: items.map((i) => i.amount / 100),
        backgroundColor: items.map((_, idx) => CHART_COLORS[idx % CHART_COLORS.length]),
        borderWidth: 0,
      },
    ],
  }
})

const chartOptions = computed(() => ({
  responsive: true,
  maintainAspectRatio: true,
  cutout: '60%',
  plugins: {
    legend: { display: false },
    tooltip: {
      callbacks: {
        label: (ctx: { label: string; parsed: number }) => `${ctx.label}: ¥${ctx.parsed.toFixed(2)}`,
      },
    },
  },
}))

async function fetchData() {
  loading.value = true
  error.value = ''
  try {
    const [summary, breakdown] = await Promise.all([
      getMonthlyStatistics(currentMonth.value),
      getCategoryBreakdown(currentMonth.value, isIncomeTab.value ? 1 : 0),
    ])
    monthlySummary.value = summary
    categoryBreakdown.value = breakdown
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : '加载统计数据失败'
  } finally {
    loading.value = false
  }
}

async function fetchBreakdown() {
  loading.value = true
  error.value = ''
  try {
    categoryBreakdown.value = await getCategoryBreakdown(
      currentMonth.value,
      isIncomeTab.value ? 1 : 0,
    )
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : '加载分类数据失败'
  } finally {
    loading.value = false
  }
}

watch(currentMonth, fetchData)
watch(isIncomeTab, fetchBreakdown)
onMounted(fetchData)
</script>

<template>
  <div class="statistics-page">
    <!-- 月份选择器 -->
    <div class="month-selector">
      <button class="month-btn" @click="changeMonth(-1)" :disabled="loading">◀</button>
      <span class="month-display">{{ displayMonth }}</span>
      <button class="month-btn" @click="changeMonth(1)" :disabled="loading || isCurrentMonth">▶</button>
    </div>

    <!-- 错误提示 -->
    <div v-if="error" class="error-bar">
      {{ error }}
      <button class="error-close" @click="error = ''">&times;</button>
    </div>

    <!-- 汇总卡片 -->
    <div class="summary-cards">
      <div class="stat-card stat-income">
        <span class="stat-label">收入</span>
        <span class="stat-value">¥{{ centsToYuan(monthlySummary?.income ?? 0) }}</span>
      </div>
      <div class="stat-card stat-expense">
        <span class="stat-label">支出</span>
        <span class="stat-value">¥{{ centsToYuan(monthlySummary?.expense ?? 0) }}</span>
      </div>
      <div class="stat-card stat-balance">
        <span class="stat-label">结余</span>
        <span class="stat-value">¥{{ centsToYuan(monthlySummary?.balance ?? 0) }}</span>
      </div>
    </div>

    <!-- 收入/支出 tab -->
    <div class="tab-group">
      <button class="tab-btn" :class="{ active: !isIncomeTab }" @click="isIncomeTab = false">支出</button>
      <button class="tab-btn" :class="{ active: isIncomeTab }" @click="isIncomeTab = true">收入</button>
    </div>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading">加载中...</div>

    <!-- 空态 -->
    <div v-else-if="!categoryBreakdown?.items?.length" class="empty-state">暂无数据</div>

    <!-- 环形图 + 分类列表 -->
    <template v-else>
      <div class="chart-container">
        <Doughnut :data="chartData" :options="chartOptions" />
        <div class="chart-center">
          <div class="chart-total">¥{{ centsToYuan(categoryBreakdown?.total ?? 0) }}</div>
          <div class="chart-label">{{ isIncomeTab ? '总收入' : '总支出' }}</div>
        </div>
      </div>

      <div class="category-list">
        <div
          v-for="(item, index) in categoryBreakdown!.items"
          :key="item.categoryId"
          class="category-item"
        >
          <div class="category-left">
            <span
              class="color-dot"
              :style="{ background: CHART_COLORS[index % CHART_COLORS.length] }"
            ></span>
            <span class="category-name">{{ item.categoryName }}</span>
          </div>
          <div class="category-right">
            <span class="category-amount" :style="{ color: CHART_COLORS[index % CHART_COLORS.length] }">
              ¥{{ centsToYuan(item.amount) }}
            </span>
            <span class="category-percent">{{ item.percentage }}%</span>
          </div>
        </div>
      </div>
    </template>
  </div>
</template>

<style scoped>
.statistics-page {
  max-width: var(--max-width);
  margin: 0 auto;
  padding: var(--space-md);
  padding-bottom: calc(var(--bottom-nav-height) + var(--space-lg));
}

.month-selector {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: var(--space-md);
}

.month-btn {
  background: none;
  border: none;
  color: var(--color-primary);
  font-size: 18px;
  cursor: pointer;
  padding: var(--space-sm);
  transition: opacity 0.2s;
}

.month-btn:disabled {
  opacity: 0.3;
  cursor: not-allowed;
}

.month-display {
  font-size: var(--font-size-lg);
  font-weight: 600;
}

.error-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: var(--space-sm) var(--space-md);
  background: #fef2f2;
  color: var(--color-danger);
  border-radius: var(--radius-sm);
  font-size: var(--font-size-sm);
  margin-bottom: var(--space-md);
}

.error-close {
  background: none;
  border: none;
  color: var(--color-danger);
  font-size: 18px;
  cursor: pointer;
}

.summary-cards {
  display: flex;
  gap: var(--space-sm);
  margin-bottom: var(--space-md);
}

.stat-card {
  flex: 1;
  border-radius: var(--radius-md);
  padding: var(--space-sm) var(--space-md);
  text-align: center;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.stat-income {
  background: #f0fdf4;
}

.stat-expense {
  background: #fef2f2;
}

.stat-balance {
  background: #eff6ff;
}

.stat-label {
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
}

.stat-income .stat-value {
  font-size: var(--font-size-lg);
  font-weight: 600;
  color: var(--color-income);
}

.stat-expense .stat-value {
  font-size: var(--font-size-lg);
  font-weight: 600;
  color: var(--color-expense);
}

.stat-balance .stat-value {
  font-size: var(--font-size-lg);
  font-weight: 600;
  color: var(--color-balance);
}

.tab-group {
  display: flex;
  background: var(--color-bg);
  border-radius: var(--radius-sm);
  overflow: hidden;
  margin-bottom: var(--space-md);
}

.tab-btn {
  flex: 1;
  padding: 8px;
  border: none;
  background: transparent;
  cursor: pointer;
  font-size: var(--font-size-base);
  font-weight: 500;
  color: var(--color-text-muted);
  transition: all 0.2s;
}

.tab-btn.active {
  background: var(--color-primary);
  color: white;
  border-radius: var(--radius-sm);
}

.loading {
  text-align: center;
  padding: var(--space-xl);
  color: var(--color-text-muted);
}

.empty-state {
  text-align: center;
  padding: var(--space-xl);
  color: var(--color-text-muted);
}

.chart-container {
  position: relative;
  width: 200px;
  height: 200px;
  margin: 0 auto var(--space-md);
}

.chart-center {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  text-align: center;
  pointer-events: none;
}

.chart-total {
  font-size: var(--font-size-lg);
  font-weight: 700;
}

.chart-label {
  font-size: var(--font-size-sm);
  color: var(--color-text-muted);
}

.category-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
}

.category-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: var(--space-sm) var(--space-md);
  background: var(--color-bg-white);
  border-radius: var(--radius-md);
  box-shadow: var(--shadow-sm);
}

.category-left {
  display: flex;
  align-items: center;
  gap: var(--space-sm);
}

.color-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

.category-name {
  font-size: var(--font-size-base);
}

.category-right {
  display: flex;
  align-items: center;
  gap: var(--space-sm);
}

.category-amount {
  font-weight: 600;
  font-size: var(--font-size-base);
}

.category-percent {
  font-size: var(--font-size-sm);
  color: var(--color-text-muted);
  min-width: 44px;
  text-align: right;
}
</style>
