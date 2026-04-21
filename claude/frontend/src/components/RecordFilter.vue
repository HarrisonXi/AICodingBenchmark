<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import { useCategoriesStore } from '@/stores/categories'
import type { RecordFilters } from '@/types/api'

const emit = defineEmits<{
  'filter-change': [filters: RecordFilters]
}>()

const categories = useCategoriesStore()

const typeFilter = ref<'' | '0' | '1'>('')
const categoryFilter = ref<string>('')
const startDate = ref('')
const endDate = ref('')

const filteredCategories = computed(() => {
  if (typeFilter.value === '1') return categories.incomeCategories
  if (typeFilter.value === '0') return categories.expenseCategories
  return categories.list
})

// 切换类型时重置分类
watch(typeFilter, () => {
  categoryFilter.value = ''
})

// 任何筛选条件变化时触发
watch([typeFilter, categoryFilter, startDate, endDate], () => {
  const filters: RecordFilters = {}
  if (typeFilter.value !== '') filters.isIncome = Number(typeFilter.value) as 0 | 1
  if (categoryFilter.value !== '') filters.categoryId = Number(categoryFilter.value)
  if (startDate.value) filters.startDate = startDate.value
  if (endDate.value) filters.endDate = endDate.value
  emit('filter-change', filters)
})
</script>

<template>
  <div class="record-filter">
    <div class="filter-row">
      <select v-model="typeFilter" class="filter-select">
        <option value="">全部类型</option>
        <option value="0">支出</option>
        <option value="1">收入</option>
      </select>
      <select v-model="categoryFilter" class="filter-select">
        <option value="">全部分类</option>
        <option v-for="cat in filteredCategories" :key="cat.id" :value="String(cat.id)">
          {{ cat.name }}
        </option>
      </select>
    </div>
    <div class="filter-row">
      <input v-model="startDate" type="date" class="filter-date" placeholder="开始日期" />
      <input v-model="endDate" type="date" class="filter-date" placeholder="结束日期" />
    </div>
  </div>
</template>

<style scoped>
.record-filter {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
  margin-bottom: var(--space-md);
}

.filter-row {
  display: flex;
  gap: var(--space-sm);
}

.filter-select,
.filter-date {
  flex: 1;
  padding: 8px 10px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  font-size: var(--font-size-sm);
  background: var(--color-bg-white);
  color: var(--color-text);
  transition: border-color 0.2s;
}

.filter-select:focus,
.filter-date:focus {
  outline: none;
  border-color: var(--color-border-focus);
  box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
}
</style>
