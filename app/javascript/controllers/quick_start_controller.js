import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "taskInput", 
    "stopwatchRadio",
    "countdownRadio",
    "timerTypeHidden",
    "stopwatchStartButton",
    "countdownOptions",
    "customDurationInput",
    "customStartButton",
    "advancedOptions", 
    "advancedToggle",
    "advancedIcon"
  ]
  
  connect() {
    // Focus on task input when page loads
    this.taskInputTarget.focus()
    // Initialize UI state
    this.updateUI()
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
    this.updateUI()
  }
  
  updateUI() {
    const isCountdown = this.countdownRadioTarget.checked
    
    // Show/hide relevant UI elements
    if (isCountdown) {
      this.stopwatchStartButtonTarget.classList.add("opacity-50", "pointer-events-none")
      this.countdownOptionsTarget.classList.remove("opacity-50", "pointer-events-none")
    } else {
      this.stopwatchStartButtonTarget.classList.remove("opacity-50", "pointer-events-none")
      this.countdownOptionsTarget.classList.add("opacity-50", "pointer-events-none")
    }
  }
  
  selectDurationAndStart(event) {
    event.preventDefault()
    
    // Set timer type to countdown
    this.countdownRadioTarget.checked = true
    this.timerTypeHiddenTarget.value = "countdown"
    
    // Set duration
    const minutes = event.currentTarget.dataset.minutes
    this.customDurationInputTarget.value = minutes
    
    // Submit form
    this.element.requestSubmit()
  }
  
  handleEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      
      // If countdown is selected and custom duration has a value, use that
      if (this.countdownRadioTarget.checked && this.customDurationInputTarget.value) {
        this.element.requestSubmit()
      } else if (this.stopwatchRadioTarget.checked) {
        // For stopwatch, just submit
        this.element.requestSubmit()
      }
    }
  }
}