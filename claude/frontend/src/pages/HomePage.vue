<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import type { BookRecord, CreateRecordPayload } from '@/types/api'
import { getRecords, createRecord, updateRecord, deleteRecord } from '@/api/records'
import { centsToYuan } from '@/utils/format'
import { ApiError } from '@/utils/http'
import RecordItem from '@/components/RecordItem.vue'
import RecordForm from '@/components/RecordForm.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'

const records = ref<BookRecord[]>([])
const loading = ref(false)
const error = ref('')

// 表单模态框
const showForm = ref(false)
const editingRecord = ref<BookRecord | null>(null)

// 删除确认
const showDeleteConfirm = ref(false)
const deletingRecord = ref<BookRecord | null>(null)

// 汇总
const totalIncome = computed(() =>
  records.value.filter((r) => r.isIncome === 1).reduce((sum, r) => sum + r.amount, 0),
)
const totalExpense = computed(() =>
  records.value.filter((r) => r.isIncome === 0).reduce((sum, r) => sum + r.amount, 0),
)
const balance = computed(() => totalIncome.value - totalExpense.value)

async function fetchRecords() {
  loading.value = true
  error.value = ''
  try {
    records.value = await getRecords()
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : '加载记录失败'
  } finally {
    loading.value = false
  }
}

function openCreateForm() {
  editingRecord.value = null
  showForm.value = true
}

function openEditForm(record: BookRecord) {
  editingRecord.value = record
  showForm.value = true
}

function openDeleteConfirm(record: BookRecord) {
  deletingRecord.value = record
  showDeleteConfirm.value = true
}

async function handleSave(payload: CreateRecordPayload, id?: number) {
  try {
    if (id) {
      await updateRecord(id, payload)
    } else {
      await createRecord(payload)
    }
    showForm.value = false
    await fetchRecords()
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : '保存失败'
  }
}

async function handleDelete() {
  if (!deletingRecord.value) return
  try {
    await deleteRecord(deletingRecord.value.id)
    showDeleteConfirm.value = false
    deletingRecord.value = null
    await fetchRecords()
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : '删除失败'
  }
}

onMounted(fetchRecords)
</script>

<template>
  <div class="home-page">
    <!-- 汇总卡片 -->
    <div class="summary-card">
      <div class="summary-item">
        <span class="summary-label">收入</span>
        <span class="summary-value income">+{{ centsToYuan(totalIncome) }}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">支出</span>
        <span class="summary-value expense">-{{ centsToYuan(totalExpense) }}</span>
      </div>
      <div class="summary-item">
        <span class="summary-label">结余</span>
        <span class="summary-value" :class="balance >= 0 ? 'income' : 'expense'">
          {{ balance >= 0 ? '+' : '' }}{{ centsToYuan(balance) }}
        </span>
      </div>
    </div>

    <!-- 错误提示 -->
    <div v-if="error" class="error-bar">
      {{ error }}
      <button class="error-close" @click="error = ''">&times;</button>
    </div>

    <!-- 加载状态 -->
    <div v-if="loading" class="loading">加载中...</div>

    <!-- 空态 -->
    <div v-else-if="records.length === 0" class="empty-state">
      <p>暂无记录</p>
      <p class="empty-hint">点击下方按钮开始记账</p>
    </div>

    <!-- 记录列表 -->
    <div v-else class="records-list">
      <RecordItem
        v-for="record in records"
        :key="record.id"
        :record="record"
        @edit="openEditForm"
        @delete="openDeleteConfirm"
      />
    </div>

    <!-- 新增按钮 -->
    <button class="fab" @click="openCreateForm" title="新增记录">+</button>

    <!-- 新增/编辑表单 -->
    <RecordForm
      :visible="showForm"
      :edit-record="editingRecord"
      @save="handleSave"
      @cancel="showForm = false"
    />

    <!-- 删除确认 -->
    <ConfirmDialog
      :visible="showDeleteConfirm"
      message="确定要删除这条记录吗？"
      @confirm="handleDelete"
      @cancel="showDeleteConfirm = false"
    />
  </div>
</template>

<style scoped>
.home-page {
  max-width: var(--max-width);
  margin: 0 auto;
  padding: var(--space-md);
  padding-bottom: 80px;
}

.summary-card {
  display: flex;
  gap: var(--space-md);
  background: var(--color-bg-white);
  border-radius: var(--radius-lg);
  padding: var(--space-md) var(--space-lg);
  box-shadow: var(--shadow-sm);
  margin-bottom: var(--space-md);
}

.summary-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.summary-label {
  font-size: var(--font-size-sm);
  color: var(--color-text-muted);
}

.summary-value {
  font-size: var(--font-size-lg);
  font-weight: 600;
}

.summary-value.income {
  color: var(--color-income);
}

.summary-value.expense {
  color: var(--color-expense);
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
  padding: 0 4px;
}

.loading {
  text-align: center;
  padding: var(--space-xl);
  color: var(--color-text-muted);
}

.empty-state {
  text-align: center;
  padding: var(--space-xl) var(--space-md);
  color: var(--color-text-muted);
}

.empty-hint {
  font-size: var(--font-size-sm);
  margin-top: var(--space-xs);
}

.records-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
}

.fab {
  position: fixed;
  bottom: 24px;
  right: 24px;
  width: 52px;
  height: 52px;
  border-radius: 50%;
  background: var(--color-primary);
  color: white;
  border: none;
  font-size: 28px;
  line-height: 1;
  cursor: pointer;
  box-shadow: var(--shadow-lg);
  transition: background 0.2s, transform 0.2s;
  display: flex;
  align-items: center;
  justify-content: center;
}

.fab:hover {
  background: var(--color-primary-hover);
  transform: scale(1.05);
}
</style>
