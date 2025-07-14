import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { storageKey: String }
  
  connect() {
    this.storageKeyValue = this.storageKeyValue || 'todo-timers-dark-mode'
    this.initializeTheme()
    
    // Listen for system theme changes
    this.mediaQuery = window.matchMedia('(prefers-color-scheme: dark)')
    this.mediaQuery.addEventListener('change', this.handleSystemThemeChange.bind(this))
  }
  
  disconnect() {
    if (this.mediaQuery) {
      this.mediaQuery.removeEventListener('change', this.handleSystemThemeChange.bind(this))
    }
  }
  
  initializeTheme() {
    const savedTheme = localStorage.getItem(this.storageKeyValue)
    const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
    
    // Clear the class first to ensure proper initialization
    document.documentElement.classList.remove('dark')
    
    if (savedTheme === 'dark' || (!savedTheme && systemPrefersDark)) {
      document.documentElement.classList.add('dark')
    }
  }
  
  toggle() {
    const isDark = document.documentElement.classList.toggle('dark')
    localStorage.setItem(this.storageKeyValue, isDark ? 'dark' : 'light')
  }
  
  handleSystemThemeChange(e) {
    if (!localStorage.getItem(this.storageKeyValue)) {
      if (e.matches) {
        document.documentElement.classList.add('dark')
      } else {
        document.documentElement.classList.remove('dark')
      }
    }
  }
}