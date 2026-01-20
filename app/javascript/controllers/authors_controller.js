import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = ["grid", "search", "pagination"]
  static values = {
    currentPage: { type: Number, default: 1 }
  }

  connect() {
    this.loadAuthors()
  }

  async loadAuthors() {
    const params = new URLSearchParams({
      search: this.searchTarget.value,
      page: this.currentPageValue,
      per_page: 20
    })

    try {
      const response = await fetch(`/api/v1/authors?${params}`, {
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const data = await response.json()
      const authorsArray = data.authors || []
      
      this.renderAuthors(authorsArray)
      
      if (data.meta) {
        this.renderPagination(data.meta)
      }
    } catch (error) {
      console.error('Error loading authors:', error)
      this.gridTarget.innerHTML = `<p class="error">Error loading authors.</p>`
    }
  }

  search(event) {
    event.preventDefault()
    this.currentPageValue = 1
    this.loadAuthors()
  }

  clear() {
    this.searchTarget.value = ''
    this.currentPageValue = 1
    this.loadAuthors()
  }

  goToPage(event) {
    event.preventDefault()
    const page = parseInt(event.currentTarget.dataset.page)
    if (page) {
      this.currentPageValue = page
      this.loadAuthors()
      window.scrollTo({ top: 0, behavior: 'smooth' })
    }
  }

  renderAuthors(authors) {
    if (!authors || authors.length === 0) {
      this.gridTarget.innerHTML = `
        <div class="card">
          <p>No authors found.</p>
        </div>
      `
      return
    }

    this.gridTarget.innerHTML = authors.map(author => this.authorCard(author)).join('')
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
          <button class="btn btn-outline" data-action="click->authors#goToPage" data-page="${prev_page}">
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
              data-action="click->authors#goToPage" 
              data-page="${page}"
              ${page === current_page ? 'disabled' : ''}>
              ${page}
            </button>
          `
        }).join('')}
        
        ${next_page ? `
          <button class="btn btn-outline" data-action="click->authors#goToPage" data-page="${next_page}">
            Next →
          </button>
        ` : ''}
      </div>
      
      <p class="pagination-info">
        Page ${current_page} of ${total_pages} (${meta.total_count} authors total)
      </p>
    `
  }

  authorCard(author) {
    const birthDate = author.birth_date 
      ? `<p><strong>Born:</strong> ${this.formatDate(author.birth_date)}</p>`
      : ''

    return `
      <div class="card">
        <h3><a href="/authors/${author.id}">${this.escapeHtml(author.name)}</a></h3>
        <p><strong>Books:</strong> ${author.books_count || 0}</p>
        ${birthDate}
        <a href="/authors/${author.id}" class="btn mt-10">View Details</a>
      </div>
    `
  }

  formatDate(dateString) {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}