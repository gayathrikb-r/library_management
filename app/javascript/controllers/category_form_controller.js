import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = ["form", "errors"]
  static values = { categoryId: Number, isEdit: Boolean }

  async submit(event) {
    event.preventDefault()
    const formData = new FormData(event.target)
    
    const categoryData = {
      name: formData.get('category[name]')
    }

    const url = this.isEditValue 
      ? `/api/v1/categories/${this.categoryIdValue}`
      : '/api/v1/categories'
    
    const method = this.isEditValue ? 'PATCH' : 'POST'

    try {
      const response = await fetch(url, {
        method: method,
        headers: AuthHelper.getAuthHeaders(),
        body: JSON.stringify({ category: categoryData })
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      if (response.ok) {
        const data = await response.json()
        window.location.href = `/categories/${data.id || this.categoryIdValue}`
      } else {
        const data = await response.json()
        this.displayErrors(data.errors || ['An error occurred'])
      }
    } catch (error) {
      console.error('Error:', error)
      this.displayErrors(['Failed to save category'])
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
