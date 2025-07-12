import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["durationSettings"]

  connect() {
    // Initialize form state
    this.toggleTimerType()
  }

  toggleTimerType() {
    const countdownRadio = this.element.querySelector('input[value="countdown"]')
    const isCountdown = countdownRadio && countdownRadio.checked
    
    if (this.hasDurationSettingsTarget) {
      if (isCountdown) {
        this.durationSettingsTarget.classList.remove('hidden')
      } else {
        this.durationSettingsTarget.classList.add('hidden')
      }
    }
  }

  setDuration(event) {
    event.preventDefault()
    
    const minutes = parseInt(event.currentTarget.dataset.minutes)
    const hours = Math.floor(minutes / 60)
    const remainingMinutes = minutes % 60
    
    // Update the duration fields
    const hoursField = this.element.querySelector('[name="duration_hours"]')
    const minutesField = this.element.querySelector('[name="duration_minutes"]')
    const secondsField = this.element.querySelector('[name="duration_seconds"]')
    
    if (hoursField) hoursField.value = hours
    if (minutesField) minutesField.value = remainingMinutes
    if (secondsField) secondsField.value = 0
    
    // Visual feedback
    this.highlightButton(event.currentTarget)
  }

  highlightButton(button) {
    // Remove active state from all duration buttons
    this.element.querySelectorAll('[data-action*="setDuration"]').forEach(btn => {
      btn.classList.remove('bg-blue-600', 'text-white')
      btn.classList.add('bg-gray-100', 'text-gray-700')
    })
    
    // Add active state to clicked button
    button.classList.remove('bg-gray-100', 'text-gray-700')
    button.classList.add('bg-blue-600', 'text-white')
    
    // Remove active state after a short delay
    setTimeout(() => {
      button.classList.remove('bg-blue-600', 'text-white')
      button.classList.add('bg-gray-100', 'text-gray-700')
    }, 1000)
  }
}