import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="countdown-timer"
export default class extends Controller {
  static targets = ["display", "progressBar", "statusBadge", "controlButtons"]
  static values = {
    timerId: Number,
    status: String,
    startTime: String,
    targetDuration: Number,
    remainingDuration: Number,
    isCountdown: { type: Boolean, default: false },
    updateUrl: String
  }

  connect() {
    // Request notification permission for countdown timers
    if (this.isCountdownValue && "Notification" in window && Notification.permission === "default") {
      Notification.requestPermission()
    }
    
    if (this.statusValue === "running") {
      this.startUpdating()
    }
    
    // Bind button click handlers
    this.bindButtonHandlers()
  }

  disconnect() {
    this.stopUpdating()
  }

  startUpdating() {
    this.updateDisplay()
    this.updateInterval = setInterval(() => {
      this.updateDisplay()
    }, 1000)
  }

  stopUpdating() {
    if (this.updateInterval) {
      clearInterval(this.updateInterval)
      this.updateInterval = null
    }
  }

  updateDisplay() {
    const currentTime = this.calculateCurrentTime()
    
    if (this.hasDisplayTarget) {
      this.displayTarget.textContent = this.formatTime(currentTime)
    }
    
    if (this.isCountdownValue && this.hasProgressBarTarget) {
      const percentage = this.calculatePercentage(currentTime)
      this.progressBarTarget.style.width = `${percentage}%`
    }
    
    // Check if countdown timer has expired
    if (this.isCountdownValue && currentTime <= 0 && this.statusValue === "running") {
      this.handleExpiration()
    }
  }

  calculateCurrentTime() {
    if (this.statusValue !== "running") {
      return this.isCountdownValue ? this.remainingDurationValue : 0
    }
    
    const startTime = new Date(this.startTimeValue)
    const now = new Date()
    const elapsedSeconds = Math.floor((now - startTime) / 1000)
    
    if (this.isCountdownValue) {
      // Countdown timer
      const remaining = this.remainingDurationValue - elapsedSeconds
      return Math.max(0, remaining)
    } else {
      // Stopwatch timer
      return elapsedSeconds
    }
  }

  calculatePercentage(remainingTime) {
    if (!this.targetDurationValue || this.targetDurationValue === 0) return 0
    
    const elapsed = this.targetDurationValue - remainingTime
    const percentage = (elapsed / this.targetDurationValue) * 100
    return Math.min(100, Math.max(0, percentage))
  }

  formatTime(totalSeconds) {
    const hours = Math.floor(totalSeconds / 3600)
    const minutes = Math.floor((totalSeconds % 3600) / 60)
    const seconds = totalSeconds % 60
    
    return [hours, minutes, seconds]
      .map(val => String(val).padStart(2, '0'))
      .join(':')
  }

  handleExpiration() {
    this.stopUpdating()
    this.statusValue = "expired"
    
    // Visual indication of expiration
    if (this.hasDisplayTarget) {
      this.displayTarget.textContent = "00:00:00"
      this.displayTarget.classList.add("text-red-600", "animate-pulse")
    }
    
    // Notify server that timer has expired
    if (this.updateUrlValue) {
      fetch(this.updateUrlValue, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': this.getCSRFToken(),
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        body: JSON.stringify({ expired: true })
      })
    }
    
    // Optional: Play a sound or show a notification
    this.playExpirationSound()
    this.showExpirationNotification()
  }

  playExpirationSound() {
    // Play an alarm sound pattern using Web Audio API
    try {
      const audioContext = new (window.AudioContext || window.webkitAudioContext)()
      
      // Play three beeps
      for (let i = 0; i < 3; i++) {
        const oscillator = audioContext.createOscillator()
        const gainNode = audioContext.createGain()
        
        oscillator.connect(gainNode)
        gainNode.connect(audioContext.destination)
        
        // Alternate between two frequencies for alarm effect
        oscillator.frequency.value = i % 2 === 0 ? 800 : 600
        gainNode.gain.value = 0.5
        
        // Start each beep with a delay
        const startTime = audioContext.currentTime + (i * 0.3)
        oscillator.start(startTime)
        oscillator.stop(startTime + 0.2)
      }
    } catch (e) {
      console.error("Could not play expiration sound:", e)
    }
  }

  showExpirationNotification() {
    // Show browser notification if permitted
    if ("Notification" in window && Notification.permission === "granted") {
      new Notification("Timer Expired!", {
        body: "Your countdown timer has reached zero.",
        icon: "/icon.png"
      })
    }
  }

  // Called when timer status changes (via Turbo)
  statusValueChanged() {
    if (this.statusValue === "running") {
      this.startUpdating()
    } else {
      this.stopUpdating()
    }
  }

  getCSRFToken() {
    const meta = document.querySelector('meta[name="csrf-token"]')
    return meta ? meta.content : ''
  }
  
  // Button handlers
  bindButtonHandlers() {
    // We'll use data-action attributes instead
  }
  
  async start(event) {
    event.preventDefault()
    await this.sendTimerAction('start')
  }
  
  async pause(event) {
    event.preventDefault()
    await this.sendTimerAction('pause')
  }
  
  async stop(event) {
    event.preventDefault()
    await this.sendTimerAction('stop')
  }
  
  async resume(event) {
    event.preventDefault()
    await this.sendTimerAction('resume')
  }
  
  async reset(event) {
    event.preventDefault()
    await this.sendTimerAction('reset')
  }
  
  async sendTimerAction(action) {
    const url = `/timers/${this.timerIdValue}/${action}`
    
    try {
      const response = await fetch(url, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': this.getCSRFToken(),
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        }
      })
      
      if (response.ok) {
        const data = await response.json()
        this.updateTimerState(data)
      } else {
        console.error(`Failed to ${action} timer: ${response.status} ${response.statusText}`)
        const text = await response.text()
        console.error('Response:', text)
      }
    } catch (error) {
      console.error(`Failed to ${action} timer:`, error)
    }
  }
  
  updateTimerState(data) {
    // Update local state based on server response
    this.statusValue = data.status
    if (data.start_time) this.startTimeValue = data.start_time
    if (data.remaining_duration !== undefined) this.remainingDurationValue = data.remaining_duration
    
    // Handle state changes
    if (this.statusValue === "running") {
      this.startUpdating()
    } else {
      this.stopUpdating()
      if (this.statusValue === "stopped" || this.statusValue === "expired") {
        this.updateDisplay() // Update display one last time
      }
    }
    
    // Update UI classes
    this.updateUIState()
    
    // Update controls with server-rendered HTML
    this.updateControlsFromServer(data)
  }
  
  updateUIState() {
    // Update status badge if present
    if (this.hasStatusBadgeTarget) {
      this.updateStatusBadge()
    }
    
    // Update control buttons if present
    if (this.hasControlButtonsTarget) {
      this.updateControlButtons()
    }
  }
  
  updateStatusBadge() {
    const badge = this.statusBadgeTarget
    
    // Remove all status classes
    badge.classList.remove('bg-green-100', 'text-green-800', 'bg-amber-100', 'text-amber-800', 
                          'bg-gray-100', 'text-gray-800', 'bg-red-100', 'text-red-800')
    
    // Add appropriate classes based on status
    switch(this.statusValue) {
      case 'running':
        badge.classList.add('bg-green-100', 'text-green-800')
        badge.innerHTML = `${this.iconHtml('play', 3)} Running`
        break
      case 'paused':
        badge.classList.add('bg-amber-100', 'text-amber-800')
        badge.innerHTML = `${this.iconHtml('pause', 3)} Paused`
        break
      case 'expired':
        badge.classList.add('bg-red-100', 'text-red-800')
        badge.innerHTML = `${this.iconHtml('exclamation', 3)} Expired`
        break
      default:
        badge.classList.add('bg-gray-100', 'text-gray-800')
        badge.innerHTML = `${this.iconHtml('check', 3)} ${this.statusValue.charAt(0).toUpperCase() + this.statusValue.slice(1)}`
    }
  }
  
  updateControlButtons() {
    const container = this.controlButtonsTarget
    container.innerHTML = ''
    
    if (this.statusValue === 'stopped' || this.statusValue === 'completed' || this.statusValue === 'expired') {
      if (this.isCountdownValue) {
        container.innerHTML = `
          <button type="button" class="btn-primary btn-lg" data-action="click->countdown-timer#reset">
            ${this.iconWithTextHtml('refresh', 'Reset Timer', 5)}
          </button>`
      } else {
        container.innerHTML = `
          <button type="button" class="btn-success btn-lg" data-action="click->countdown-timer#start">
            ${this.iconWithTextHtml('play', 'Start Timer', 5)}
          </button>`
      }
    } else if (this.statusValue === 'running') {
      container.innerHTML = `
        <button type="button" class="btn-warning btn-lg" data-action="click->countdown-timer#pause">
          ${this.iconWithTextHtml('pause', 'Pause', 5)}
        </button>
        <button type="button" class="btn-danger btn-lg" data-action="click->countdown-timer#stop">
          ${this.iconWithTextHtml('stop', 'Stop', 5)}
        </button>`
    } else if (this.statusValue === 'paused') {
      container.innerHTML = `
        <button type="button" class="btn-success btn-lg" data-action="click->countdown-timer#resume">
          ${this.iconWithTextHtml('play', 'Resume', 5)}
        </button>
        <button type="button" class="btn-danger btn-lg" data-action="click->countdown-timer#stop">
          ${this.iconWithTextHtml('stop', 'Stop', 5)}
        </button>`
    }
  }
  
  iconHtml(name, size) {
    // Use static classes to ensure Tailwind includes them
    const sizeClasses = {
      3: 'w-3 h-3',
      4: 'w-4 h-4', 
      5: 'w-5 h-5',
      6: 'w-6 h-6'
    }
    const sizeClass = sizeClasses[size] || 'w-5 h-5'
    const icons = {
      play: `<svg class="${sizeClass} mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>`,
      pause: `<svg class="${sizeClass} mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 9v6m4-6v6m7-3a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>`,
      stop: `<svg class="${sizeClass}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 10a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 01-1-1v-4z"></path></svg>`,
      refresh: `<svg class="${sizeClass}" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"></path></svg>`,
      exclamation: `<svg class="${sizeClass} mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path></svg>`,
      check: `<svg class="${sizeClass} mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg>`
    }
    return icons[name] || ''
  }
  
  iconWithTextHtml(iconName, text, size) {
    return `<span class="inline-flex items-center gap-2">${this.iconHtml(iconName, size)} ${text}</span>`
  }
  
  updateControlsFromServer(data) {
    // Find the controls container in the DOM
    const controlsContainer = this.element.querySelector('.flex.items-center.gap-2, .flex.space-x-2')
    
    if (controlsContainer && (data.controls_html || data.controls_compact_html)) {
      // Determine which controls to use based on the current view
      const isCompactView = controlsContainer.querySelector('button[title]') !== null
      const controlsHtml = isCompactView ? data.controls_compact_html : data.controls_html
      
      if (controlsHtml) {
        // Create a temporary container to parse the HTML
        const temp = document.createElement('div')
        temp.innerHTML = controlsHtml
        
        // Find all timer control buttons in the container
        const existingButtons = controlsContainer.querySelectorAll('button[data-action*="countdown-timer"]')
        
        // Replace the existing buttons with new ones
        if (existingButtons.length > 0 && temp.children.length > 0) {
          // Remove existing timer control buttons
          existingButtons.forEach(btn => btn.remove())
          
          // Insert new buttons at the beginning of the container
          const firstNonTimerElement = controlsContainer.querySelector('a, button:not([data-action*="countdown-timer"])')
          if (firstNonTimerElement) {
            // Insert all new buttons before the first non-timer element
            while (temp.firstChild) {
              controlsContainer.insertBefore(temp.firstChild, firstNonTimerElement)
            }
          } else {
            // Append to the end if no non-timer elements found
            while (temp.firstChild) {
              controlsContainer.appendChild(temp.firstChild)
            }
          }
        }
      }
    }
  }
}