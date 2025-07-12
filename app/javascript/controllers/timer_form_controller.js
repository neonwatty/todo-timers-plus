import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "taskName", 
    "timerTypeStopwatch", 
    "timerTypeCountdown",
    "durationHours",
    "durationMinutes", 
    "durationSeconds",
    "tags",
    "durationPicker",
    "templateSection",
    "saveAsTemplate"
  ]

  connect() {
    // Initialize timer type selection styling
    this.updateTimerTypeDisplay()
  }

  selectTemplate(event) {
    event.preventDefault()
    
    const templateData = JSON.parse(event.currentTarget.dataset.template)
    
    // Populate task name
    if (this.hasTaskNameTarget) {
      this.taskNameTarget.value = templateData.task_name || ""
    }
    
    // Set timer type
    if (templateData.timer_type === "countdown") {
      if (this.hasTimerTypeCountdownTarget) {
        this.timerTypeCountdownTarget.checked = true
        this.showDurationPicker()
      }
      
      // Set duration if it's a countdown timer
      if (templateData.target_duration) {
        const hours = Math.floor(templateData.target_duration / 3600)
        const minutes = Math.floor((templateData.target_duration % 3600) / 60)
        const seconds = templateData.target_duration % 60
        
        if (this.hasDurationHoursTarget) this.durationHoursTarget.value = hours
        if (this.hasDurationMinutesTarget) this.durationMinutesTarget.value = minutes
        if (this.hasDurationSecondsTarget) this.durationSecondsTarget.value = seconds
      }
    } else {
      if (this.hasTimerTypeStopwatchTarget) {
        this.timerTypeStopwatchTarget.checked = true
        this.hideDurationPicker()
      }
    }
    
    // Set tags
    if (this.hasTagsTarget && templateData.tags) {
      this.tagsTarget.value = templateData.tags
    }
    
    // Update visual state
    this.updateTimerTypeDisplay()
    
    // Collapse template section
    if (this.hasTemplateSectionTarget) {
      this.templateSectionTarget.classList.add('hidden')
    }
    
    // Visual feedback
    this.showTemplateAppliedMessage(templateData.name)
  }

  toggleTemplateSection() {
    if (this.hasTemplateSectionTarget) {
      this.templateSectionTarget.classList.toggle('hidden')
    }
  }

  clearTemplate() {
    // Clear all form fields
    if (this.hasTaskNameTarget) this.taskNameTarget.value = ""
    if (this.hasTagsTarget) this.tagsTarget.value = ""
    
    // Reset to stopwatch
    if (this.hasTimerTypeStopwatchTarget) {
      this.timerTypeStopwatchTarget.checked = true
      this.hideDurationPicker()
    }
    
    // Clear duration fields
    if (this.hasDurationHoursTarget) this.durationHoursTarget.value = 0
    if (this.hasDurationMinutesTarget) this.durationMinutesTarget.value = 25
    if (this.hasDurationSecondsTarget) this.durationSecondsTarget.value = 0
    
    this.updateTimerTypeDisplay()
  }

  toggleTimerType(event) {
    if (event.target.value === "countdown") {
      this.showDurationPicker()
    } else {
      this.hideDurationPicker()
    }
    this.updateTimerTypeDisplay()
  }

  showDurationPicker() {
    if (this.hasDurationPickerTarget) {
      this.durationPickerTarget.classList.remove('hidden')
    }
  }

  hideDurationPicker() {
    if (this.hasDurationPickerTarget) {
      this.durationPickerTarget.classList.add('hidden')
    }
  }

  updateTimerTypeDisplay() {
    // Remove active styling from all radio button containers
    this.element.querySelectorAll('label.relative').forEach(label => {
      label.classList.remove('border-blue-500', 'ring-2', 'ring-blue-500')
    })
    
    // Add active styling to checked radio button
    const checkedRadio = this.element.querySelector('input[name="timer[timer_type]"]:checked')
    if (checkedRadio) {
      checkedRadio.closest('label').classList.add('border-blue-500', 'ring-2', 'ring-blue-500')
    }
  }

  setDuration(event) {
    event.preventDefault()
    
    const minutes = parseInt(event.currentTarget.dataset.minutes)
    const hours = Math.floor(minutes / 60)
    const remainingMinutes = minutes % 60
    
    if (this.hasDurationHoursTarget) this.durationHoursTarget.value = hours
    if (this.hasDurationMinutesTarget) this.durationMinutesTarget.value = remainingMinutes
    if (this.hasDurationSecondsTarget) this.durationSecondsTarget.value = 0
    
    // Visual feedback
    this.highlightDurationButton(event.currentTarget)
  }

  highlightDurationButton(button) {
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

  showTemplateAppliedMessage(templateName) {
    // Create and show a temporary success message
    const message = document.createElement('div')
    message.className = 'fixed top-4 right-4 bg-green-100 border border-green-200 text-green-800 px-4 py-2 rounded-lg shadow-lg z-50 transition-all duration-300'
    message.innerHTML = `
      <div class="flex items-center">
        <svg class="w-4 h-4 mr-2" fill="currentColor" viewBox="0 0 20 20">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clip-rule="evenodd"></path>
        </svg>
        Template "${templateName}" applied!
      </div>
    `
    
    document.body.appendChild(message)
    
    // Remove message after 3 seconds
    setTimeout(() => {
      message.remove()
    }, 3000)
  }
}