<script setup lang="ts">
import { onMounted } from 'vue'
import { useAuthStore } from '@/stores/auth'
import { useCategoriesStore } from '@/stores/categories'
import AppHeader from '@/components/AppHeader.vue'

const auth = useAuthStore()
const categories = useCategoriesStore()

onMounted(() => {
  auth.loadFromStorage()
  // 加载分类数据（公开接口，无需鉴权）
  categories.fetchCategories()
})
</script>

<template>
  <AppHeader v-if="auth.isAuthenticated" />
  <router-view />
</template>
