import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = ["categoryDetails", "booksList"]
  static values = { categoryId: Number }

  connect() {
    this.loadCategoryDetails()
  }

  async loadCategoryDetails() {
    try {
      const response = await fetch(`/api/v1/categories/${this.categoryIdValue}`, {
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const data = await response.json()
      
      this.renderCategory(data.category)
      this.renderBooks(data.books, data.category.name)
    } catch (error) {
      console.error('Error loading category:', error)
    }
  }

  async deleteCategory() {
    if (!confirm('Are you sure you want to delete this category?')) return

    try {
      const response = await fetch(`/api/v1/categories/${this.categoryIdValue}`, {
        method: 'DELETE',
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }
      
      if (response.ok || response.status === 204) {
        alert('Category deleted')
        window.location.href = '/categories'
      } else {
        const data = await response.json()
        alert(data.errors?.join(', ') || 'Error deleting category')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to delete category')
    }
  }

  renderCategory(category) {
    const isLibrarian = this.isLibrarianSignedIn()

    this.categoryDetailsTarget.innerHTML = `
      <h1>${this.escapeHtml(category.name)}</h1>
      ${isLibrarian ? `
        <div style="margin-top: 10px;">
          <a href="/categories/${category.id}/edit" class="btn">Edit</a>
          <button class="btn btn-danger" data-action="click->category-show#deleteCategory">
            Delete
          </button>
        </div>
      ` : ''}
    `
  }

  renderBooks(books, categoryName) {
    this.booksListTarget.innerHTML = `
      <h2>Books in ${this.escapeHtml(categoryName)} (${books.length})</h2>
      ${books.length > 0 ? `
        <div class="grid">
          ${books.map(book => this.bookCard(book)).join('')}
        </div>
      ` : '<p>No books in this category yet.</p>'}
    `
  }

  bookCard(book) {
    const authors = book.authors?.map(a => a.name).join(", ") || "Unknown"
    const availableBadge = book.available_copies > 0
      ? '<span class="badge badge-success">Available</span>'
      : '<span class="badge badge-danger">Unavailable</span>'

    return `
      <div style="padding: 10px; border: 1px solid #ddd; border-radius: 4px;">
        <h4><a href="/books/${book.id}">${this.escapeHtml(book.title)}</a></h4>
        <p>${this.escapeHtml(authors)}</p>
        ${availableBadge}
      </div>
    `
  }

  isLibrarianSignedIn() {
    return document.body.dataset.librarianSignedIn === 'true'
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}