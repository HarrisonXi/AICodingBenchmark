<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import type { BookRecord, CreateRecordPayload, RecordFilters } from '@/types/api'
import { getRecords, updateRecord, deleteRecord } from '@/api/records'
import { ApiError } from '@/utils/http'
import RecordItem from '@/components/RecordItem.vue'
import RecordForm from '@/components/RecordForm.vue'
import ConfirmDialog from '@/components/ConfirmDialog.vue'
import RecordFilter from '@/components/RecordFilter.vue'

const records = ref<BookRecord[]>([])
const loading = ref(false)
const error = ref('')
const page = ref(1)
const totalPages = ref(1)
const filters = ref<RecordFilters>({})
const sentinelRef = ref<HTMLElement | null>(null)
let observer: IntersectionObserver | null = null

// 编辑模态框
const showEditForm = ref(false)
const editingRecord = ref<BookRecord | null>(null)

// 删除确认
const showDeleteConfirm = ref(false)
const deletingRecord = ref<BookRecord | null>(null)

async function fetchRecords(pageNum: number, append: boolean = false) {
  if (loading.value) return
  loading.value = true
  error.value = ''
  try {
    const result = await getRecords({
      page: pageNum,
      pageSize: 20,
      ...filters.value,
    })
    if (append) {
      records.value = [...records.value, ...result.items]
    } else {
      records.value = result.items
    }
    page.value = result.pagination.page
    totalPages.value = result.pagination.totalPages
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : '加载记录失败'
  } finally {
    loading.value = false
  }
}

function resetAndFetch() {
  page.value = 1
  totalPages.value = 1
  records.value = []
  fetchRecords(1)
}

function onFilterChange(newFilters: RecordFilters) {
  filters.value = newFilters
  resetAndFetch()
}

function loadMore() {
  if (loading.value || page.value >= totalPages.value) return
  fetchRecords(page.value + 1, true)
}

function setupObserver() {
  if (!sentinelRef.value) return
  observer = new IntersectionObserver(
    (entries) => {
      if (entries[0].isIntersecting) loadMore()
    },
    { rootMargin: '100px' },
  )
  observer.observe(sentinelRef.value)
}

function openEditForm(record: BookRecord) {
  editingRecord.value = record
  showEditForm.value = true
}

function openDeleteConfirm(record: BookRecord) {
  deletingRecord.value = record
  showDeleteConfirm.value = true
}

async function handleSave(payload: CreateRecordPayload, id?: number) {
  if (!id) return
  try {
    await updateRecord(id, payload)
    showEditForm.value = false
    resetAndFetch()
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
    resetAndFetch()
  } catch (e) {
    error.value = e instanceof ApiError ? e.message : '删除失败'
  }
}

// 供 App.vue 调用的刷新方法
function refresh() {
  resetAndFetch()
}

defineExpose({ refresh })

onMounted(async () => {
  await fetchRecords(1)
  await nextTick()
  setupObserver()
})

onUnmounted(() => {
  observer?.disconnect()
})
</script>

<template>
  <div class="home-page">
    <!-- 筛选栏 -->
    <RecordFilter @filter-change="onFilterChange" />

    <!-- 错误提示 -->
    <div v-if="error" class="error-bar">
      {{ error }}
      <button class="error-close" @click="error = ''">&times;</button>
    </div>

    <!-- 空态 -->
    <div v-if="!loading && records.length === 0" class="empty-state">
      <p>暂无记录</p>
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

    <!-- 无限滚动哨兵 -->
    <div ref="sentinelRef" class="sentinel">
      <span v-if="loading" class="loading-text">加载中...</span>
      <span v-else-if="page >= totalPages && records.length > 0" class="loading-text">没有更多了</span>
    </div>

    <!-- 编辑表单 -->
    <RecordForm
      :visible="showEditForm"
      :edit-record="editingRecord"
      @save="handleSave"
      @cancel="showEditForm = false"
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
  padding-bottom: calc(var(--bottom-nav-height) + var(--space-lg));
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

.empty-state {
  text-align: center;
  padding: var(--space-xl) var(--space-md);
  color: var(--color-text-muted);
}

.records-list {
  display: flex;
  flex-direction: column;
  gap: var(--space-sm);
}

.sentinel {
  text-align: center;
  padding: var(--space-md);
  min-height: 48px;
}

.loading-text {
  font-size: var(--font-size-sm);
  color: var(--color-text-muted);
}
</style>
