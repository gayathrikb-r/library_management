import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = ["form", "errors"]
  static values = { memberId: Number }

  async submit(event) {
    event.preventDefault()
    const formData = new FormData(event.target)
    
    const memberData = {
      name: formData.get('member[name]'),
      phone: formData.get('member[phone]'),
      bio: formData.get('member[bio]'),
      birth_date: formData.get('member[birth_date]')
    }

    try {
      const response = await fetch(`/api/v1/members/${this.memberIdValue}`, {
        method: 'PATCH',
        headers: AuthHelper.getAuthHeaders(),
        body: JSON.stringify({ member: memberData })
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const data = await response.json()

      if (response.ok) {
        alert(data.message)
        window.location.href = `/members/${this.memberIdValue}`
      } else {
        this.displayErrors(data.errors || ['An error occurred'])
      }
    } catch (error) {
      console.error('Error:', error)
      this.displayErrors(['Failed to update profile'])
    }
  }

  displayErrors(errors) {
    const errorList = Array.isArray(errors) ? errors : Object.values(errors).flat()
    this.errorsTarget.innerHTML = `
      <div class="flash alert">
        <h4>${errorList.length} error(s) prohibited this profile from being saved:</h4>
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
