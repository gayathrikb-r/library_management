import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = ["form", "errors"]
  static values = { 
    reviewId: Number,
    reviewableType: String,
    reviewableId: Number
  }

  async submit(event) {
    event.preventDefault()
    const formData = new FormData(event.target)
    
    const reviewData = {
      rating: formData.get('review[rating]'),
      comment: formData.get('review[comment]')
    }

    try {
      const response = await fetch(`/api/v1/reviews/${this.reviewIdValue}`, {
        method: 'PATCH',
        headers: AuthHelper.getAuthHeaders(),
        body: JSON.stringify({ review: reviewData })
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        // Redirect back to the reviewable (book or author)
        window.location.href = this.getReviewableUrl()
      } else {
        this.displayErrors(data.errors || ['An error occurred'])
      }
    } catch (error) {
      console.error('Error:', error)
      this.displayErrors(['Failed to update review'])
    }
  }

  getReviewableUrl() {
    const type = this.reviewableTypeValue.toLowerCase()
    return `/${type}s/${this.reviewableIdValue}`
  }

  displayErrors(errors) {
    const errorList = Array.isArray(errors) ? errors : Object.values(errors).flat()
    this.errorsTarget.innerHTML = `
      <div class="flash alert">
        <h3>${errorList.length} error(s):</h3>
        <ul>
          ${errorList.map(error => `<li>${this.escapeHtml(error)}</li>`).join('')}
        </ul>
      </div>
    `
    this.errorsTarget.scrollIntoView({ behavior: 'smooth' })
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}