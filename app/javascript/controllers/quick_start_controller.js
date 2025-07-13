import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "taskInput", 
    "stopwatchRadio",
    "countdownRadio",
    "timerTypeHidden",
    "countdownOptions",
    "customDurationInput",
    "submitButton",
    "advancedOptions", 
    "advancedToggle",
    "advancedIcon"
  ]
  
  connect() {
    // Focus on task input when page loads
    this.taskInputTarget.focus()
  }
  
  selectRecentTask(event) {
    const taskName = event.currentTarget.dataset.taskName
    this.taskInputTarget.value = taskName
    this.taskInputTarget.focus()
    // Trigger change event for Capybara tests
    this.taskInputTarget.dispatchEvent(new Event('change', { bubbles: true }))
  }
  
  toggleAdvanced(event) {
    event.preventDefault()
    this.advancedOptionsTarget.classList.toggle("hidden")
    
    // Rotate chevron icon
    if (this.advancedOptionsTarget.classList.contains("hidden")) {
      this.advancedIconTarget.classList.remove("rotate-180")
    } else {
      this.advancedIconTarget.classList.add("rotate-180")
    }
  }
  
  toggleTimerType(event) {
    // Update hidden field value
    this.timerTypeHiddenTarget.value = event.target.value
  }
  
  selectDuration(event) {
    event.preventDefault()
    
    // Set timer type to countdown
    this.countdownRadioTarget.checked = true
    this.timerTypeHiddenTarget.value = "countdown"
    
    // Set duration and provide visual feedback
    const minutes = event.currentTarget.dataset.minutes
    this.customDurationInputTarget.value = minutes
    
    // Remove active state from other preset buttons
    this.element.querySelectorAll('.quick-duration-btn').forEach(btn => {
      btn.classList.remove('bg-blue-100', 'border-blue-500', 'text-blue-700')
      btn.classList.add('bg-white', 'border-gray-300', 'text-gray-700')
    })
    
    // Add active state to clicked button
    event.currentTarget.classList.remove('bg-white', 'border-gray-300', 'text-gray-700')
    event.currentTarget.classList.add('bg-blue-100', 'border-blue-500', 'text-blue-700')
  }
  
  handleCustomDuration(event) {
    // When custom duration is entered, select countdown type and clear preset selection
    if (event.target.value) {
      this.countdownRadioTarget.checked = true
      this.timerTypeHiddenTarget.value = "countdown"
      
      // Clear preset button selection
      this.element.querySelectorAll('.quick-duration-btn').forEach(btn => {
        btn.classList.remove('bg-blue-100', 'border-blue-500', 'text-blue-700')
        btn.classList.add('bg-white', 'border-gray-300', 'text-gray-700')
      })
    }
  }
  
  handleEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }
}