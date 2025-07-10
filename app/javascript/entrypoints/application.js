// Import CSS
import './application.css'

// Import Hotwire
import '@hotwired/turbo-rails'

// Timer functionality
class TimerManager {
  constructor() {
    this.timers = new Map()
    this.init()
  }

  init() {
    this.startTimerUpdates()
    this.bindEvents()
  }

  startTimerUpdates() {
    setInterval(() => {
      document.querySelectorAll('[data-timer-id]').forEach(element => {
        const timerId = element.dataset.timerId
        const status = element.dataset.timerStatus
        const startTime = element.dataset.timerStartTime
        
        if (status === 'running' && startTime) {
          this.updateTimerDisplay(element, startTime)
        }
      })
    }, 1000)
  }

  updateTimerDisplay(element, startTime) {
    const start = new Date(startTime)
    const now = new Date()
    const elapsed = Math.floor((now - start) / 1000)
    
    const hours = Math.floor(elapsed / 3600)
    const minutes = Math.floor((elapsed % 3600) / 60)
    const seconds = elapsed % 60
    
    const display = hours > 0 
      ? `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
      : `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`
    
    const displayElement = element.querySelector('.timer-display')
    if (displayElement) {
      displayElement.textContent = display
    }
  }

  bindEvents() {
    // Handle timer control buttons
    document.addEventListener('click', (e) => {
      if (e.target.matches('[data-timer-action]')) {
        const action = e.target.dataset.timerAction
        const timerId = e.target.dataset.timerId
        this.handleTimerAction(action, timerId)
      }
    })
  }

  handleTimerAction(action, timerId) {
    // Actions are handled by Rails forms, but we can add client-side feedback
    const timerElement = document.querySelector(`[data-timer-id="${timerId}"]`)
    if (timerElement) {
      // Add visual feedback
      timerElement.style.opacity = '0.7'
      setTimeout(() => {
        timerElement.style.opacity = '1'
      }, 200)
    }
  }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  new TimerManager()
})

// Reinitialize on Turbo visits
document.addEventListener('turbo:load', () => {
  new TimerManager()
})
