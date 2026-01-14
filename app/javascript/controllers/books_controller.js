import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["grid", "search", "category", "available", "pagination"]
  static values = { 
    url: String,
    currentPage: { type: Number, default: 1 }
  }

  connect() {
    this.loadBooks()
  }

  async loadBooks() {
    const params = new URLSearchParams({
      search: this.searchTarget.value,
      category_id: this.categoryTarget.value,
      available: this.availableTarget.value,
      page: this.currentPageValue,
      per_page: 12
    })

    try {
      const response = await fetch(`/api/v1/books?${params}`, {
        headers: this.headers()
      })
      const data = await response.json()
      
      //  Check if 'data' is the array itself, or if the array is nested inside 'data.books'
      const booksArray = Array.isArray(data) ? data : (data.books || [])
      
      this.renderBooks(booksArray)
      
      // Render pagination if meta exists
      if (data.meta) {
        this.renderPagination(data.meta)
      }
    } catch (error) {
      console.error('Error loading books:', error)
      this.gridTarget.innerHTML = `<p class="error">Error loading books. Please try again.</p>`
    }
  }

  search(event) {
    event.preventDefault()
    this.currentPageValue = 1
    this.loadBooks()
  }

  clear() {
    this.searchTarget.value = ''
    this.categoryTarget.value = ''
    this.availableTarget.value = ''
    this.currentPageValue = 1
    this.loadBooks()
  }

  goToPage(event) {
    event.preventDefault()
    const page = parseInt(event.currentTarget.dataset.page)
    if (page) {
      this.currentPageValue = page
      this.loadBooks()
      window.scrollTo({ top: 0, behavior: 'smooth' })
    }
  }

  renderBooks(books) {

    if (!books || books.length === 0) {
      this.gridTarget.innerHTML = `
        <div class="card ">
          <p>No books found.</p>
          <p class="muted">Try adjusting your search or filters.</p>
        </div>
      `
      return
    }

    this.gridTarget.innerHTML = books.map(book => this.bookCard(book)).join('')
  }

  renderPagination(meta) {
    if (!this.hasPaginationTarget) return
    
    const { current_page, total_pages, prev_page, next_page } = meta
    
    if (total_pages <= 1) {
      this.paginationTarget.innerHTML = ''
      return
    }

    let pages = []
    
    //  show first page
    pages.push(1)
    
    // Show pages around current page
    for (let i = Math.max(2, current_page - 1); i <= Math.min(total_pages - 1, current_page + 1); i++) {
      if (!pages.includes(i)) pages.push(i)
    }
    
    // Always show last page
    if (!pages.includes(total_pages)) pages.push(total_pages)

    this.paginationTarget.innerHTML = `
      <div class="pagination">
        ${prev_page ? `
          <button class="btn btn-outline" data-action="click->books#goToPage" data-page="${prev_page}">
            ← Previous
          </button>
        ` : ''}
        
        ${pages.map((page, index) => {
          // Add ... if there's a gap
          const prevPage = pages[index - 1]
          const ellipsis = prevPage && page - prevPage > 1 ? '<span class="pagination-ellipsis">...</span>' : ''
          
          return `
            ${ellipsis}
            <button 
              class="btn ${page === current_page ? 'btn-primary' : 'btn-outline'}" 
              data-action="click->books#goToPage" 
              data-page="${page}"
              ${page === current_page ? 'disabled' : ''}>
              ${page}
            </button>
          `
        }).join('')}
        
        ${next_page ? `
          <button class="btn btn-outline" data-action="click->books#goToPage" data-page="${next_page}">
            Next →
          </button>
        ` : ''}
      </div>
      
      <p class="pagination-info">
        Page ${current_page} of ${total_pages} (${meta.total_count} books total)
      </p>
    `
  }

  bookCard(book) {
    const authors = book.authors?.map(a => a.name).join(", ") || "Unknown"
    const stars = book.average_rating ? "⭐".repeat(Math.round(book.average_rating)) : ""
    const availableBadge = book.available_copies > 0 
      ? `<span class="badge badge-success">Available (${book.available_copies})</span>`
      : `<span class="badge badge-danger">Unavailable</span>`

    return `
      <div class="card book-card">
        <h3 class="book-title">
          <a href="/books/${book.id}">${this.escapeHtml(book.title)}</a>
        </h3>
        <p class="book-meta">
          <strong>Authors:</strong> ${this.escapeHtml(authors)}
        </p>
        <p class="book-meta">
          <strong>ISBN:</strong> ${book.isbn || "N/A"}
        </p>
        <div class="availability">${availableBadge}</div>
        ${book.average_rating ? `
          <p class="star-rating">
            ${stars}
            <span class="rating-text">(${(Number(book.average_rating) || 0).toFixed(1)}/5)</span>
          </p>
        ` : ''}
        <a href="/books/${book.id}" class="btn btn-outline mt-10">View Details</a>
      </div>
    `
  }

  escapeHtml(text) {
    //  safety check for null/undefined
    if (!text) return ""
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