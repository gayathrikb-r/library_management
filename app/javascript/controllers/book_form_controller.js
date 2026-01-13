// app/javascript/controllers/book_form_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "errors"]
  static values = { bookId: Number, isEdit: Boolean }

  async submit(event) {
    event.preventDefault()
    const formData = new FormData(event.target)
    
    const bookData = {
      title: formData.get('book[title]'),
      isbn: formData.get('book[isbn]'),
      publication_year: formData.get('book[publication_year]'),
      total_copies: formData.get('book[total_copies]'),
      available_copies: formData.get('book[available_copies]'),
      description: formData.get('book[description]'),
      author_ids: formData.getAll('book[author_ids][]').filter(id => id),
      category_ids: formData.getAll('book[category_ids][]').filter(id => id)
    }

    // Handle new authors
    const newAuthors = formData.get('book[new_author_name]')
    if (newAuthors) {
      bookData.new_author_names = newAuthors.split(',').map(name => name.trim()).filter(Boolean)
    }

    // Handle new categories
    const newCategories = formData.get('book[new_category_name]')
    if (newCategories) {
      bookData.new_category_names = newCategories.split(',').map(name => name.trim()).filter(Boolean)
    }

    const url = this.isEditValue 
      ? `/api/v1/books/${this.bookIdValue}`
      : '/api/v1/books'
    
    const method = this.isEditValue ? 'PATCH' : 'POST'

    try {
      const response = await fetch(url, {
        method: method,
        headers: this.headers(),
        body: JSON.stringify({ book: bookData })
      })

      if (response.ok) {
        const data = await response.json()
        window.location.href = `/books/${data.id || this.bookIdValue}`
      } else {
        const data = await response.json()
        this.displayErrors(data.errors || ['An error occurred'])
      }
    } catch (error) {
      console.error('Error:', error)
      this.displayErrors(['Failed to save book'])
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

  headers() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    return {
      'Content-Type': 'application/json',
      'X-CSRF-Token': token
    }
  }
}