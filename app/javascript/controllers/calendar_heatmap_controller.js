import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["calendar"]
  static values = { data: Object }

  connect() {
    if (this.hasCalendarTarget && this.dataValue) {
      this.renderHeatmap()
    }
  }

  renderHeatmap() {
    const calendarData = this.dataValue
    const container = this.calendarTarget
    
    // Clear existing content
    container.innerHTML = ''
    
    // Create month labels
    const monthsContainer = document.createElement('div')
    monthsContainer.className = 'flex justify-between mb-2 text-xs text-gray-600'
    
    // Get unique months
    const months = this.getMonthsInRange()
    months.forEach(month => {
      const monthLabel = document.createElement('div')
      monthLabel.textContent = month
      monthsContainer.appendChild(monthLabel)
    })
    container.appendChild(monthsContainer)
    
    // Create day labels
    const daysContainer = document.createElement('div')
    daysContainer.className = 'flex flex-col gap-1 float-left mr-2 text-xs text-gray-600'
    const dayLabels = ['', 'Mon', '', 'Wed', '', 'Fri', '']
    dayLabels.forEach(day => {
      const dayLabel = document.createElement('div')
      dayLabel.className = 'h-3'
      dayLabel.textContent = day
      daysContainer.appendChild(dayLabel)
    })
    container.appendChild(daysContainer)
    
    // Create grid container
    const gridContainer = document.createElement('div')
    gridContainer.className = 'grid grid-flow-col gap-1 auto-cols-max'
    
    // Generate 90 days of data
    const today = new Date()
    const startDate = new Date(today)
    startDate.setDate(startDate.getDate() - 89) // 90 days including today
    
    // Group by week
    let currentWeek = []
    const weeks = []
    
    for (let i = 0; i < 90; i++) {
      const currentDate = new Date(startDate)
      currentDate.setDate(currentDate.getDate() + i)
      const dateStr = currentDate.toISOString().split('T')[0]
      const dayData = calendarData[dateStr] || { count: 0, duration: 0 }
      
      currentWeek.push({
        date: currentDate,
        dateStr: dateStr,
        data: dayData,
        dayOfWeek: currentDate.getDay()
      })
      
      // Start new week on Sunday
      if (currentDate.getDay() === 6 || i === 89) {
        weeks.push(currentWeek)
        currentWeek = []
      }
    }
    
    // Render weeks
    weeks.forEach(week => {
      const weekContainer = document.createElement('div')
      weekContainer.className = 'flex flex-col gap-1'
      
      // Ensure each week has 7 days (fill empty days)
      for (let dayIndex = 0; dayIndex < 7; dayIndex++) {
        const dayData = week.find(d => d.dayOfWeek === dayIndex)
        const dayElement = document.createElement('div')
        dayElement.className = 'w-3 h-3 rounded-sm'
        
        if (dayData) {
          const intensity = this.getIntensity(dayData.data.duration)
          dayElement.className += ` ${this.getColorClass(intensity)}`
          dayElement.title = `${dayData.dateStr}: ${dayData.data.count} timers, ${this.formatDuration(dayData.data.duration)}`
        } else {
          dayElement.className += ' bg-gray-100'
        }
        
        weekContainer.appendChild(dayElement)
      }
      
      gridContainer.appendChild(weekContainer)
    })
    
    container.appendChild(gridContainer)
    
    // Add legend
    const legendContainer = document.createElement('div')
    legendContainer.className = 'flex items-center gap-2 mt-4 text-xs text-gray-600'
    legendContainer.innerHTML = `
      <span>Less</span>
      <div class="flex gap-1">
        <div class="w-3 h-3 rounded-sm bg-gray-200"></div>
        <div class="w-3 h-3 rounded-sm bg-green-300"></div>
        <div class="w-3 h-3 rounded-sm bg-green-400"></div>
        <div class="w-3 h-3 rounded-sm bg-green-500"></div>
        <div class="w-3 h-3 rounded-sm bg-green-600"></div>
      </div>
      <span>More</span>
    `
    container.appendChild(legendContainer)
  }

  getMonthsInRange() {
    const months = []
    const today = new Date()
    const startDate = new Date(today)
    startDate.setDate(startDate.getDate() - 89)
    
    let currentMonth = startDate.getMonth()
    months.push(startDate.toLocaleString('default', { month: 'short' }))
    
    for (let i = 1; i < 90; i++) {
      const date = new Date(startDate)
      date.setDate(date.getDate() + i)
      if (date.getMonth() !== currentMonth) {
        currentMonth = date.getMonth()
        months.push(date.toLocaleString('default', { month: 'short' }))
      }
    }
    
    return months
  }

  getIntensity(duration) {
    if (duration === 0) return 0
    if (duration < 1800) return 1 // Less than 30 minutes
    if (duration < 3600) return 2 // Less than 1 hour
    if (duration < 7200) return 3 // Less than 2 hours
    return 4 // 2+ hours
  }

  getColorClass(intensity) {
    switch(intensity) {
      case 0: return 'bg-gray-200'
      case 1: return 'bg-green-300'
      case 2: return 'bg-green-400'
      case 3: return 'bg-green-500'
      case 4: return 'bg-green-600'
      default: return 'bg-gray-200'
    }
  }

  formatDuration(seconds) {
    const hours = Math.floor(seconds / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)
    return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`
  }
}