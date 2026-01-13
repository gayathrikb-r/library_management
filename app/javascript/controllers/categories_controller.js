// app/javascript/controllers/categories_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grid", "pagination"]
  static values = {
    currentPage: { type: Number, default: 1 }
  }

  connect() {
    this.loadCategories()
  }

  async loadCategories() {
    const params = new URLSearchParams({
      page: this.currentPageValue,
      per_page: 20
    })

    try {
      const response = await fetch(`/api/v1/categories?${params}`, {
        headers: this.headers()
      })
      const data = await response.json()
      
      // FIX: Extract categories array from the response object
      const categoriesArray = data.categories || []
      
      this.renderCategories(categoriesArray)
      
      // Render pagination if meta exists
      if (data.meta) {
        this.renderPagination(data.meta)
      }
    } catch (error) {
      console.error('Error loading categories:', error)
      this.gridTarget.innerHTML = `<p class="error">Error loading categories.</p>`
    }
  }

  goToPage(event) {
    event.preventDefault()
    const page = parseInt(event.currentTarget.dataset.page)
    if (page) {
      this.currentPageValue = page
      this.loadCategories()
      window.scrollTo({ top: 0, behavior: 'smooth' })
    }
  }

  async deleteCategory(event) {
    const categoryId = event.currentTarget.dataset.categoryId
    if (!confirm('Are you sure you want to delete this category?')) return

    try {
      const response = await fetch(`/api/v1/categories/${categoryId}`, {
        method: 'DELETE',
        headers: this.headers()
      })
      
      if (response.ok || response.status === 204) {
        alert('Category deleted')
        this.loadCategories()
      } else {
        const data = await response.json()
        alert(data.errors?.join(', ') || 'Error deleting category')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to delete category')
    }
  }

  renderCategories(categories) {
    if (!categories || categories.length === 0) {
      this.gridTarget.innerHTML = `
        <div class="card">
          <p>No categories found.</p>
        </div>
      `
      return
    }

    this.gridTarget.innerHTML = categories.map(category => this.categoryCard(category)).join('')
  }

  renderPagination(meta) {
    if (!this.hasPaginationTarget) return
    
    const { current_page, total_pages, prev_page, next_page } = meta
    
    if (total_pages <= 1) {
      this.paginationTarget.innerHTML = ''
      return
    }

    let pages = []
    
    pages.push(1)
    
    for (let i = Math.max(2, current_page - 1); i <= Math.min(total_pages - 1, current_page + 1); i++) {
      if (!pages.includes(i)) pages.push(i)
    }
    
    if (!pages.includes(total_pages)) pages.push(total_pages)

    this.paginationTarget.innerHTML = `
      <div class="pagination">
        ${prev_page ? `
          <button class="btn btn-outline" data-action="click->categories#goToPage" data-page="${prev_page}">
            ← Previous
          </button>
        ` : ''}
        
        ${pages.map((page, index) => {
          const prevPage = pages[index - 1]
          const ellipsis = prevPage && page - prevPage > 1 ? '<span class="pagination-ellipsis">...</span>' : ''
          
          return `
            ${ellipsis}
            <button 
              class="btn ${page === current_page ? 'btn-primary' : 'btn-outline'}" 
              data-action="click->categories#goToPage" 
              data-page="${page}"
              ${page === current_page ? 'disabled' : ''}>
              ${page}
            </button>
          `
        }).join('')}
        
        ${next_page ? `
          <button class="btn btn-outline" data-action="click->categories#goToPage" data-page="${next_page}">
            Next →
          </button>
        ` : ''}
      </div>
      
      <p class="pagination-info">
        Page ${current_page} of ${total_pages} (${meta.total_count} categories total)
      </p>
    `
  }

  categoryCard(category) {
    const isLibrarian = this.isLibrarianSignedIn()

    return `
      <div class="card">
        <h3><a href="/categories/${category.id}">${this.escapeHtml(category.name)}</a></h3>
        <p><strong>Books:</strong> ${category.books_count || 0}</p>
        ${isLibrarian ? `
          <div style="margin-top: 10px;">
            <a href="/categories/${category.id}/edit" class="btn">Edit</a>
            <button class="btn btn-danger" 
                    data-action="click->categories#deleteCategory"
                    data-category-id="${category.id}">
              Delete
            </button>
          </div>
        ` : ''}
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

  headers() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    return {
      'Content-Type': 'application/json',
      'X-CSRF-Token': token
    }
  }
}