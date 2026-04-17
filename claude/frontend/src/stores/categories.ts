import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { getCategories as fetchCategoriesApi } from '@/api/categories'
import type { Category } from '@/types/api'

export const useCategoriesStore = defineStore('categories', () => {
  const list = ref<Category[]>([])
  const loaded = ref(false)

  const expenseCategories = computed(() => list.value.filter((c) => c.isIncome === 0))
  const incomeCategories = computed(() => list.value.filter((c) => c.isIncome === 1))

  function getCategoryName(id: number): string {
    return list.value.find((c) => c.id === id)?.name ?? '未知分类'
  }

  async function fetchCategories() {
    if (loaded.value) return
    list.value = await fetchCategoriesApi()
    loaded.value = true
  }

  return { list, loaded, expenseCategories, incomeCategories, getCategoryName, fetchCategories }
})
