import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["editButton", "viewMode", "editMode", "emptyState", "notesDisplay", "notesTextarea"]

  connect() {
    this.originalNotes = this.notesTextareaTarget.value
  }

  toggleEdit() {
    this.showEditMode()
  }

  showEditMode() {
    this.viewModeTarget.classList.add("hidden")
    this.emptyStateTarget.classList.add("hidden")
    this.editModeTarget.classList.remove("hidden")
    this.notesTextareaTarget.focus()
  }

  showViewMode() {
    this.editModeTarget.classList.add("hidden")
    
    if (this.notesTextareaTarget.value.trim()) {
      this.viewModeTarget.classList.remove("hidden")
      this.emptyStateTarget.classList.add("hidden")
    } else {
      this.viewModeTarget.classList.add("hidden")
      this.emptyStateTarget.classList.remove("hidden")
    }
  }

  cancelEdit() {
    this.notesTextareaTarget.value = this.originalNotes
    this.showViewMode()
  }

  saveNotes(event) {
    event.preventDefault()
    
    const form = event.target
    const formData = new FormData(form)
    
    fetch(form.action, {
      method: "PATCH",
      body: formData,
      headers: {
        "X-Requested-With": "XMLHttpRequest",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        // Update the display with the new notes
        this.notesDisplayTarget.textContent = this.notesTextareaTarget.value
        this.originalNotes = this.notesTextareaTarget.value
        
        // Update button text
        this.editButtonTarget.textContent = this.notesTextareaTarget.value.trim() ? "Edit Notes" : "Add Notes"
        
        // Show view mode
        this.showViewMode()
        
        // Show success message (optional)
        this.showMessage("Notes saved successfully!", "success")
      } else {
        this.showMessage("Failed to save notes. Please try again.", "error")
      }
    })
    .catch(error => {
      console.error("Error saving notes:", error)
      this.showMessage("An error occurred while saving notes.", "error")
    })
  }

  showMessage(text, type) {
    // Create a simple toast notification
    const toast = document.createElement("div")
    toast.className = `fixed top-4 right-4 px-4 py-2 rounded-lg text-white text-sm font-medium z-50 ${
      type === "success" ? "bg-green-600" : "bg-red-600"
    }`
    toast.textContent = text
    
    document.body.appendChild(toast)
    
    // Remove after 3 seconds
    setTimeout(() => {
      if (toast.parentNode) {
        toast.parentNode.removeChild(toast)
      }
    }, 3000)
  }
}