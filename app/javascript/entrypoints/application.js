// Import Hotwire
import '@hotwired/turbo-rails'

// Import Chart.js
import Chart from 'chart.js/auto'

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

// Analytics Charts
class AnalyticsManager {
  constructor() {
    this.initCharts()
  }

  initCharts() {
    // Daily/Weekly time chart
    const timeChartElement = document.getElementById('timeChart')
    if (timeChartElement) {
      this.createTimeChart(timeChartElement)
    }

    // Top tasks chart
    const tasksChartElement = document.getElementById('tasksChart')
    if (tasksChartElement) {
      this.createTasksChart(tasksChartElement)
    }
  }

  createTimeChart(canvas) {
    const data = JSON.parse(canvas.dataset.chartData || '{}')
    
    new Chart(canvas, {
      type: 'bar',
      data: {
        labels: data.labels || [],
        datasets: [{
          label: 'Time Spent (minutes)',
          data: data.values || [],
          backgroundColor: 'rgba(59, 130, 246, 0.5)',
          borderColor: 'rgb(59, 130, 246)',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            ticks: {
              callback: function(value) {
                return value + ' min'
              }
            }
          }
        },
        plugins: {
          tooltip: {
            callbacks: {
              label: function(context) {
                const minutes = context.parsed.y
                const hours = Math.floor(minutes / 60)
                const mins = minutes % 60
                return hours > 0 ? `${hours}h ${mins}m` : `${mins}m`
              }
            }
          }
        }
      }
    })
  }

  createTasksChart(canvas) {
    const data = JSON.parse(canvas.dataset.chartData || '{}')
    
    new Chart(canvas, {
      type: 'doughnut',
      data: {
        labels: data.labels || [],
        datasets: [{
          data: data.values || [],
          backgroundColor: [
            'rgba(59, 130, 246, 0.8)',
            'rgba(34, 197, 94, 0.8)',
            'rgba(245, 158, 11, 0.8)',
            'rgba(239, 68, 68, 0.8)',
            'rgba(147, 51, 234, 0.8)'
          ],
          borderWidth: 2,
          borderColor: '#fff'
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              padding: 15,
              font: {
                size: 12
              }
            }
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                const minutes = context.parsed
                const hours = Math.floor(minutes / 60)
                const mins = minutes % 60
                const time = hours > 0 ? `${hours}h ${mins}m` : `${mins}m`
                return `${context.label}: ${time}`
              }
            }
          }
        }
      }
    })
  }
}

// Initialize when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
  new TimerManager()
  new AnalyticsManager()
})

// Reinitialize on Turbo visits
document.addEventListener('turbo:load', () => {
  new TimerManager()
  new AnalyticsManager()
})
