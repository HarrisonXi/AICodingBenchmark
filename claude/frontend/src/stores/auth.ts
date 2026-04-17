import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

const TOKEN_KEY = 'bookkeeping_token'
const USER_KEY = 'bookkeeping_user'

export const useAuthStore = defineStore('auth', () => {
  const token = ref<string | null>(null)
  const userId = ref<number | null>(null)
  const username = ref<string | null>(null)

  const isAuthenticated = computed(() => token.value !== null)

  function setAuth(data: { id: number; username: string; token: string }) {
    token.value = data.token
    userId.value = data.id
    username.value = data.username
    localStorage.setItem(TOKEN_KEY, data.token)
    localStorage.setItem(USER_KEY, JSON.stringify({ id: data.id, username: data.username }))
  }

  function logout() {
    token.value = null
    userId.value = null
    username.value = null
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(USER_KEY)
  }

  function loadFromStorage() {
    const savedToken = localStorage.getItem(TOKEN_KEY)
    const savedUser = localStorage.getItem(USER_KEY)
    if (savedToken && savedUser) {
      try {
        const user = JSON.parse(savedUser)
        token.value = savedToken
        userId.value = user.id
        username.value = user.username
      } catch {
        localStorage.removeItem(TOKEN_KEY)
        localStorage.removeItem(USER_KEY)
      }
    }
  }

  return { token, userId, username, isAuthenticated, setAuth, logout, loadFromStorage }
})
