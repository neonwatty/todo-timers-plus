import { Controller } from "@hotwired/stimulus"
import Chart from 'chart.js/auto'

export default class extends Controller {
  static targets = ["timeDistribution", "topTasks", "streakCalendar", "tagBreakdown"]
  static values = { 
    timeData: Object,
    taskData: Object,
    streakData: Object,
    tagData: Object,
    period: String
  }

  connect() {
    this.initializeCharts()
  }

  disconnect() {
    // Clean up charts when controller disconnects
    if (this.timeChart) this.timeChart.destroy()
    if (this.taskChart) this.taskChart.destroy()
    if (this.tagChart) this.tagChart.destroy()
  }

  periodChanged(event) {
    // This will be called when period selection changes
    this.periodValue = event.target.value
    this.updateCharts()
  }

  initializeCharts() {
    if (this.hasTimeDistributionTarget && this.timeDataValue) {
      this.renderTimeDistributionChart()
    }
    
    if (this.hasTopTasksTarget && this.taskDataValue) {
      this.renderTopTasksChart()
    }

    if (this.hasTagBreakdownTarget && this.tagDataValue) {
      this.renderTagBreakdownChart()
    }
  }

  renderTimeDistributionChart() {
    const ctx = this.timeDistributionTarget.getContext('2d')
    
    // Configure mobile-responsive options
    const options = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: false
        },
        title: {
          display: true,
          text: this.getTimeDistributionTitle(),
          font: {
            size: 16
          }
        },
        tooltip: {
          callbacks: {
            label: (context) => {
              const hours = Math.floor(context.parsed.y / 3600)
              const minutes = Math.floor((context.parsed.y % 3600) / 60)
              return `${hours}h ${minutes}m`
            }
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          ticks: {
            callback: (value) => {
              const hours = Math.floor(value / 3600)
              const minutes = Math.floor((value % 3600) / 60)
              return hours > 0 ? `${hours}h` : `${minutes}m`
            }
          }
        }
      }
    }

    this.timeChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: this.timeDataValue.labels,
        datasets: [{
          label: 'Time Tracked',
          data: this.timeDataValue.data,
          backgroundColor: 'rgba(59, 130, 246, 0.8)',
          borderColor: 'rgba(59, 130, 246, 1)',
          borderWidth: 1,
          borderRadius: 4
        }]
      },
      options: options
    })
  }

  renderTopTasksChart() {
    const ctx = this.topTasksTarget.getContext('2d')
    
    const options = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          position: 'bottom',
          labels: {
            padding: 20,
            usePointStyle: true,
            font: {
              size: 12
            }
          }
        },
        title: {
          display: true,
          text: 'Top Tasks by Time',
          font: {
            size: 16
          }
        },
        tooltip: {
          callbacks: {
            label: (context) => {
              const hours = Math.floor(context.parsed / 3600)
              const minutes = Math.floor((context.parsed % 3600) / 60)
              return `${context.label}: ${hours}h ${minutes}m`
            }
          }
        }
      }
    }

    // Use doughnut chart for better mobile experience
    this.taskChart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: this.taskDataValue.labels,
        datasets: [{
          data: this.taskDataValue.data,
          backgroundColor: [
            'rgba(59, 130, 246, 0.8)',
            'rgba(16, 185, 129, 0.8)',
            'rgba(249, 115, 22, 0.8)',
            'rgba(139, 92, 246, 0.8)',
            'rgba(236, 72, 153, 0.8)'
          ],
          borderColor: [
            'rgba(59, 130, 246, 1)',
            'rgba(16, 185, 129, 1)',
            'rgba(249, 115, 22, 1)',
            'rgba(139, 92, 246, 1)',
            'rgba(236, 72, 153, 1)'
          ],
          borderWidth: 2
        }]
      },
      options: options
    })
  }

  renderTagBreakdownChart() {
    const ctx = this.tagBreakdownTarget.getContext('2d')
    
    const options = {
      responsive: true,
      maintainAspectRatio: false,
      indexAxis: 'y', // Horizontal bar chart
      plugins: {
        legend: {
          display: false
        },
        title: {
          display: true,
          text: 'Time by Tags',
          font: {
            size: 16
          }
        },
        tooltip: {
          callbacks: {
            label: (context) => {
              const hours = Math.floor(context.parsed.x / 3600)
              const minutes = Math.floor((context.parsed.x % 3600) / 60)
              return `${hours}h ${minutes}m`
            }
          }
        }
      },
      scales: {
        x: {
          beginAtZero: true,
          ticks: {
            callback: (value) => {
              const hours = Math.floor(value / 3600)
              return `${hours}h`
            }
          }
        }
      }
    }

    this.tagChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: this.tagDataValue.labels || [],
        datasets: [{
          label: 'Time by Tag',
          data: this.tagDataValue.data || [],
          backgroundColor: 'rgba(16, 185, 129, 0.8)',
          borderColor: 'rgba(16, 185, 129, 1)',
          borderWidth: 1,
          borderRadius: 4
        }]
      },
      options: options
    })
  }

  getTimeDistributionTitle() {
    switch(this.periodValue) {
      case 'day':
        return 'Hourly Activity (Last 24 Hours)'
      case 'week':
        return 'Daily Activity (Last 7 Days)'
      case 'month':
        return 'Weekly Activity (Last 4 Weeks)'
      default:
        return 'Time Distribution'
    }
  }

  updateCharts() {
    // This method will be called to refresh charts with new data
    // We'll implement this when we add AJAX updates
  }
}