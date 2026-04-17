<script setup lang="ts">
defineProps<{
  visible: boolean
  message: string
}>()

const emit = defineEmits<{
  confirm: []
  cancel: []
}>()
</script>

<template>
  <Teleport to="body">
    <div v-if="visible" class="overlay" @click.self="emit('cancel')">
      <div class="dialog">
        <p class="dialog-message">{{ message }}</p>
        <div class="dialog-actions">
          <button class="btn-cancel" @click="emit('cancel')">取消</button>
          <button class="btn-confirm" @click="emit('confirm')">确认</button>
        </div>
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
}

.dialog {
  background: var(--color-bg-white);
  border-radius: var(--radius-lg);
  padding: var(--space-lg);
  width: 90%;
  max-width: 360px;
  box-shadow: var(--shadow-lg);
}

.dialog-message {
  font-size: var(--font-size-base);
  margin-bottom: var(--space-lg);
  line-height: 1.6;
}

.dialog-actions {
  display: flex;
  justify-content: flex-end;
  gap: var(--space-sm);
}

.btn-cancel,
.btn-confirm {
  padding: 6px 16px;
  border-radius: var(--radius-sm);
  font-size: var(--font-size-sm);
  cursor: pointer;
  transition: all 0.2s;
}

.btn-cancel {
  background: none;
  border: 1px solid var(--color-border);
  color: var(--color-text-secondary);
}

.btn-cancel:hover {
  border-color: var(--color-text-secondary);
}

.btn-confirm {
  background: var(--color-danger);
  border: none;
  color: white;
}

.btn-confirm:hover {
  background: var(--color-danger-hover);
}
</style>
