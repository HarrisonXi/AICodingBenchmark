<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { useCategoriesStore } from '@/stores/categories'
import { createRecord } from '@/api/records'
import { ApiError } from '@/utils/http'
import type { CreateRecordPayload } from '@/types/api'
import AppHeader from '@/components/AppHeader.vue'
import BottomNav from '@/components/BottomNav.vue'
import RecordForm from '@/components/RecordForm.vue'

const auth = useAuthStore()
const categories = useCategoriesStore()
const route = useRoute()

const showCreateForm = ref(false)
const homePageRef = ref<{ refresh: () => void } | null>(null)

onMounted(() => {
  auth.loadFromStorage()
  categories.fetchCategories()
})

function openCreateForm() {
  showCreateForm.value = true
}

async function handleCreateSave(payload: CreateRecordPayload) {
  try {
    await createRecord(payload)
    showCreateForm.value = false
    // 刷新当前页面数据
    if (route.path === '/') {
      homePageRef.value?.refresh()
    }
  } catch (e) {
    const msg = e instanceof ApiError ? e.message : '创建失败'
    alert(msg)
  }
}
</script>

<template>
  <AppHeader v-if="auth.isAuthenticated" />
  <router-view v-slot="{ Component }">
    <component :is="Component" ref="homePageRef" />
  </router-view>
  <BottomNav v-if="auth.isAuthenticated" @create-record="openCreateForm" />

  <!-- 新增记录表单（全局） -->
  <RecordForm
    :visible="showCreateForm"
    @save="handleCreateSave"
    @cancel="showCreateForm = false"
  />
</template>
