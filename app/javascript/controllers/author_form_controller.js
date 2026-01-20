import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = ["form", "errors"]
  static values = { authorId: Number, isEdit: Boolean }

  async submit(event) {
    event.preventDefault()
    const formData = new FormData(event.target)
    
    const authorData = {
      name: formData.get('author[name]'),
      birth_date: formData.get('author[birth_date]'),
      biography: formData.get('author[biography]')
    }

    const url = this.isEditValue 
      ? `/api/v1/authors/${this.authorIdValue}`
      : '/api/v1/authors'
    const method = this.isEditValue ? 'PATCH' : 'POST'

    try {
      const response = await fetch(url, {
        method: method,
        headers: AuthHelper.getAuthHeaders(),
        body: JSON.stringify({ author: authorData })
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      if (response.ok) {
        const data = await response.json()
        window.location.href = `/authors/${data.id || this.authorIdValue}`
      } else {
        const data = await response.json()
        this.displayErrors(data.errors || ['An error occurred'])
      }
    } catch (error) {
      console.error('Error:', error)
      this.displayErrors(['Failed to save author'])
    }
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
