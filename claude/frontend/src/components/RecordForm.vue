<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import type { BookRecord, CreateRecordPayload } from '@/types/api'
import { useCategoriesStore } from '@/stores/categories'
import { useFormValidation, required, positiveNumber } from '@/composables/useFormValidation'
import { centsToYuan, yuanToCents, today } from '@/utils/format'

const props = defineProps<{
  visible: boolean
  editRecord?: BookRecord | null
}>()

const emit = defineEmits<{
  save: [payload: CreateRecordPayload, id?: number]
  cancel: []
}>()

const categories = useCategoriesStore()

const form = ref({
  isIncome: '0' as '0' | '1',
  categoryId: '',
  amount: '',
  date: today(),
  note: '',
})

const { errors, validate, validateField, clearErrors } = useFormValidation(form, {
  amount: [required('金额'), positiveNumber('金额')],
  categoryId: [required('分类')],
})

const filteredCategories = computed(() =>
  form.value.isIncome === '1' ? categories.incomeCategories : categories.expenseCategories,
)

const isEditing = computed(() => !!props.editRecord)

const title = computed(() => (isEditing.value ? '编辑记录' : '新增记录'))

// 编辑模式下填充表单
watch(
  () => props.editRecord,
  (record) => {
    if (record) {
      form.value = {
        isIncome: String(record.isIncome) as '0' | '1',
        categoryId: String(record.categoryId),
        amount: centsToYuan(record.amount),
        date: record.date,
        note: record.note ?? '',
      }
    }
  },
)

// 切换收入/支出时重置分类
watch(
  () => form.value.isIncome,
  () => {
    if (!isEditing.value) {
      form.value.categoryId = ''
    }
  },
)

// 打开/关闭时重置表单
watch(
  () => props.visible,
  (visible) => {
    if (visible && !props.editRecord) {
      form.value = { isIncome: '0', categoryId: '', amount: '', date: today(), note: '' }
      clearErrors()
    }
  },
)

function handleSubmit() {
  if (!validate()) return
  const payload: CreateRecordPayload = {
    isIncome: Number(form.value.isIncome) as 0 | 1,
    categoryId: Number(form.value.categoryId),
    amount: yuanToCents(form.value.amount),
    date: form.value.date,
  }
  if (form.value.note.trim()) {
    payload.note = form.value.note.trim()
  }
  emit('save', payload, props.editRecord?.id)
}
</script>

<template>
  <Teleport to="body">
    <div v-if="visible" class="overlay" @click.self="emit('cancel')">
      <div class="form-modal">
        <h2 class="form-title">{{ title }}</h2>
        <form @submit.prevent="handleSubmit" class="record-form">
          <!-- 收入/支出切换 -->
          <div class="toggle-group">
            <button
              type="button"
              class="toggle-btn"
              :class="{ active: form.isIncome === '0' }"
              @click="form.isIncome = '0'"
            >
              支出
            </button>
            <button
              type="button"
              class="toggle-btn"
              :class="{ active: form.isIncome === '1' }"
              @click="form.isIncome = '1'"
            >
              收入
            </button>
          </div>

          <!-- 分类 -->
          <div class="form-group">
            <label for="categoryId">分类</label>
            <select
              id="categoryId"
              v-model="form.categoryId"
              @change="validateField('categoryId')"
            >
              <option value="" disabled>请选择分类</option>
              <option
                v-for="cat in filteredCategories"
                :key="cat.id"
                :value="String(cat.id)"
              >
                {{ cat.name }}
              </option>
            </select>
            <span v-if="errors.categoryId" class="field-error">{{ errors.categoryId }}</span>
          </div>

          <!-- 金额 -->
          <div class="form-group">
            <label for="amount">金额（元）</label>
            <input
              id="amount"
              v-model="form.amount"
              type="number"
              step="0.01"
              min="0.01"
              placeholder="0.00"
              @blur="validateField('amount')"
            />
            <span v-if="errors.amount" class="field-error">{{ errors.amount }}</span>
          </div>

          <!-- 日期 -->
          <div class="form-group">
            <label for="date">日期</label>
            <input id="date" v-model="form.date" type="date" />
          </div>

          <!-- 备注 -->
          <div class="form-group">
            <label for="note">备注（可选，最多 200 字）</label>
            <input
              id="note"
              v-model="form.note"
              type="text"
              placeholder="添加备注..."
              maxlength="200"
            />
          </div>

          <!-- 操作 -->
          <div class="form-actions">
            <button type="button" class="btn-cancel" @click="emit('cancel')">取消</button>
            <button type="submit" class="btn-primary">保存</button>
          </div>
        </form>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.4);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 200;
  padding: var(--space-md);
}

.form-modal {
  background: var(--color-bg-white);
  border-radius: var(--radius-lg);
  padding: var(--space-lg);
  width: 100%;
  max-width: 420px;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: var(--shadow-lg);
}

.form-title {
  font-size: var(--font-size-xl);
  font-weight: 600;
  margin-bottom: var(--space-md);
}

.record-form {
  display: flex;
  flex-direction: column;
  gap: var(--space-md);
}

.toggle-group {
  display: flex;
  gap: 0;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  overflow: hidden;
}

.toggle-btn {
  flex: 1;
  padding: 8px;
  border: none;
  background: var(--color-bg-white);
  cursor: pointer;
  font-size: var(--font-size-base);
  font-weight: 500;
  transition: all 0.2s;
  color: var(--color-text-secondary);
}

.toggle-btn.active {
  background: var(--color-primary);
  color: white;
}

.form-group {
  display: flex;
  flex-direction: column;
  gap: var(--space-xs);
}

.form-group label {
  font-size: var(--font-size-sm);
  font-weight: 500;
  color: var(--color-text-secondary);
}

.form-group input,
.form-group select {
  padding: 10px 12px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  font-size: var(--font-size-base);
  transition: border-color 0.2s;
  background: var(--color-bg-white);
}

.form-group input:focus,
.form-group select:focus {
  outline: none;
  border-color: var(--color-border-focus);
  box-shadow: 0 0 0 3px rgba(79, 70, 229, 0.1);
}

.field-error {
  font-size: var(--font-size-sm);
  color: var(--color-danger);
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-sm);
  margin-top: var(--space-sm);
}

.btn-cancel {
  padding: 8px 16px;
  background: none;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  cursor: pointer;
  color: var(--color-text-secondary);
  transition: all 0.2s;
}

.btn-cancel:hover {
  border-color: var(--color-text-secondary);
}

.btn-primary {
  padding: 8px 20px;
  background: var(--color-primary);
  color: white;
  border: none;
  border-radius: var(--radius-sm);
  font-weight: 500;
  cursor: pointer;
  transition: background 0.2s;
}

.btn-primary:hover {
  background: var(--color-primary-hover);
}
</style>
