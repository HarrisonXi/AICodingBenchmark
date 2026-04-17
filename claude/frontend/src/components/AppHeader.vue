<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

function handleLogout() {
  auth.logout()
  router.push('/login')
}
</script>

<template>
  <header class="app-header">
    <div class="header-inner">
      <h1 class="header-title">记账本</h1>
      <div class="header-right">
        <span class="header-username">{{ auth.username }}</span>
        <button class="btn-logout" @click="handleLogout">退出</button>
      </div>
    </div>
  </header>
</template>

<style scoped>
.app-header {
  height: var(--header-height);
  background: var(--color-bg-white);
  border-bottom: 1px solid var(--color-border);
  position: sticky;
  top: 0;
  z-index: 100;
}

.header-inner {
  max-width: var(--max-width);
  margin: 0 auto;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 var(--space-md);
}

.header-title {
  font-size: var(--font-size-lg);
  font-weight: 600;
}

.header-right {
  display: flex;
  align-items: center;
  gap: var(--space-sm);
}

.header-username {
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
}

.btn-logout {
  padding: 4px 12px;
  background: none;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  font-size: var(--font-size-sm);
  color: var(--color-text-secondary);
  cursor: pointer;
  transition: all 0.2s;
}

.btn-logout:hover {
  border-color: var(--color-danger);
  color: var(--color-danger);
}
</style>
