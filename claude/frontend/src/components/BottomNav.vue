<script setup lang="ts">
import { useRoute } from 'vue-router'

const route = useRoute()

const emit = defineEmits<{
  'create-record': []
}>()
</script>

<template>
  <nav class="bottom-nav">
    <router-link to="/" class="nav-item" :class="{ active: route.path === '/' }">
      <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
      </svg>
      <span class="nav-label">明细</span>
    </router-link>

    <button class="nav-center-btn" @click="emit('create-record')" title="新增记录">
      <span class="nav-center-icon">+</span>
    </button>

    <router-link to="/statistics" class="nav-item" :class="{ active: route.path === '/statistics' }">
      <svg class="nav-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <path d="M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z" />
        <path d="M20.488 9H15V3.512A9.025 9.025 0 0120.488 9z" />
      </svg>
      <span class="nav-label">统计</span>
    </router-link>
  </nav>
</template>

<style scoped>
.bottom-nav {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: var(--bottom-nav-height);
  background: var(--color-bg-white);
  border-top: 1px solid var(--color-border);
  display: flex;
  align-items: flex-end;
  justify-content: space-around;
  z-index: 100;
  padding-bottom: env(safe-area-inset-bottom, 0);
}

.nav-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 2px;
  padding: 6px 0 8px;
  text-decoration: none;
  color: var(--color-text-muted);
  transition: color 0.2s;
}

.nav-item.active {
  color: var(--color-primary);
}

.nav-icon {
  width: 22px;
  height: 22px;
}

.nav-label {
  font-size: 11px;
  font-weight: 500;
}

.nav-center-btn {
  width: 48px;
  height: 48px;
  border-radius: 50%;
  background: linear-gradient(135deg, var(--color-primary), var(--color-primary-hover));
  border: none;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: -16px;
  box-shadow: 0 2px 10px rgba(79, 70, 229, 0.4);
  transition: transform 0.2s, box-shadow 0.2s;
}

.nav-center-btn:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 14px rgba(79, 70, 229, 0.5);
}

.nav-center-icon {
  font-size: 24px;
  color: white;
  line-height: 1;
}
</style>
