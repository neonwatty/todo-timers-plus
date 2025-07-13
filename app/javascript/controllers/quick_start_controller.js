import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["taskInput", "submitButton", "advancedOptions", "advancedToggle", "durationField"]
  
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
    
    // Update button appearance
    if (this.advancedOptionsTarget.classList.contains("hidden")) {
      this.advancedToggleTarget.classList.remove("bg-blue-100", "border-blue-400")
    } else {
      this.advancedToggleTarget.classList.add("bg-blue-100", "border-blue-400")
    }
  }
  
  toggleDuration(event) {
    if (event.target.value === "countdown") {
      this.durationFieldTarget.classList.remove("hidden")
    } else {
      this.durationFieldTarget.classList.add("hidden")
    }
  }
  
  handleEnter(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      this.element.requestSubmit()
    }
  }
}