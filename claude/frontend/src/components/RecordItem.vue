<script setup lang="ts">
import type { BookRecord } from '@/types/api'
import { useCategoriesStore } from '@/stores/categories'
import { centsToYuan } from '@/utils/format'

const props = defineProps<{
  record: BookRecord
}>()

const emit = defineEmits<{
  edit: [record: BookRecord]
  delete: [record: BookRecord]
}>()

const categories = useCategoriesStore()
</script>

<template>
  <div class="record-item">
    <div class="record-main">
      <div class="record-left">
        <span class="record-category">{{ categories.getCategoryName(props.record.categoryId) }}</span>
        <span v-if="props.record.note" class="record-note">{{ props.record.note }}</span>
      </div>
      <span class="record-amount" :class="props.record.isIncome ? 'income' : 'expense'">
        {{ props.record.isIncome ? '+' : '-' }}{{ centsToYuan(props.record.amount) }}
      </span>
    </div>
    <div class="record-footer">
      <span class="record-date">{{ props.record.date }}</span>
      <div class="record-actions">
        <button class="btn-action" @click="emit('edit', props.record)">编辑</button>
        <button class="btn-action btn-delete" @click="emit('delete', props.record)">删除</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.record-item {
  background: var(--color-bg-white);
  border-radius: var(--radius-md);
  padding: var(--space-md);
  box-shadow: var(--shadow-sm);
}

.record-main {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: var(--space-sm);
}

.record-left {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.record-category {
  font-weight: 500;
}

.record-note {
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.record-amount {
  font-weight: 600;
  font-size: var(--font-size-lg);
  white-space: nowrap;
}

.record-amount.income {
  color: var(--color-income);
}

.record-amount.expense {
  color: var(--color-expense);
}

.record-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-top: var(--space-sm);
}

.record-date {
  font-size: var(--font-size-sm);
  color: var(--color-text-muted);
}

.record-actions {
  display: flex;
  gap: var(--space-xs);
}

.btn-action {
  padding: 2px 8px;
  background: none;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
  cursor: pointer;
  transition: all 0.2s;
}

.btn-action:hover {
  border-color: var(--color-primary);
  color: var(--color-primary);
}

.btn-delete:hover {
  border-color: var(--color-danger);
  color: var(--color-danger);
}
</style>
