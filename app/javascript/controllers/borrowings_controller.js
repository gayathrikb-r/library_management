// app/javascript/controllers/borrowings_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["table", "filters"]
  static values = { 
    filter: String,
    memberId: String
  }

  connect() {
    this.loadBorrowings()
  }

  async loadBorrowings() {
    const params = new URLSearchParams()
    
    if (this.filterValue) {
      params.append('filter', this.filterValue)
    }
    
    if (this.memberIdValue) {
      params.append('member_id', this.memberIdValue)
    }

    try {
      const response = await fetch(`/api/v1/borrowings?${params}`, {
        headers: this.headers()
      })
      const borrowings = await response.json()
      this.renderBorrowings(borrowings)
    } catch (error) {
      console.error('Error loading borrowings:', error)
    }
  }

  setFilter(event) {
    event.preventDefault()
    const filter = event.currentTarget.dataset.filter
    this.filterValue = filter || ''
    
    // Update active button
    this.element.querySelectorAll('[data-filter]').forEach(btn => {
      btn.classList.remove('btn-success')
    })
    event.currentTarget.classList.add('btn-success')
    
    this.loadBorrowings()
  }

  async returnBook(event) {
    const borrowingId = event.currentTarget.dataset.borrowingId
    if (!confirm('Mark this book as returned?')) return

    try {
      const response = await fetch(`/api/v1/borrowings/${borrowingId}/return_book`, {
        method: 'PATCH',
        headers: this.headers()
      })
      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        this.loadBorrowings()
      } else {
        alert(data.error || 'Error returning book')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to return book')
    }
  }

  renderBorrowings(borrowings) {
    if (!borrowings || borrowings.length === 0) {
      this.tableTarget.innerHTML = '<p>No borrowings found.</p>'
      return
    }

    const isLibrarian = this.isLibrarianSignedIn()
    
    this.tableTarget.innerHTML = `
      <table class="table table-striped">
        <thead>
          <tr>
            ${isLibrarian ? '<th>Member</th>' : ''}
            <th>Book</th>
            <th>Borrowed Date</th>
            <th>Due Date</th>
            <th>Return Date</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          ${borrowings.map(b => this.borrowingRow(b, isLibrarian)).join('')}
        </tbody>
      </table>
    `
  }

  borrowingRow(borrowing, isLibrarian) {
    const statusBadge = this.getStatusBadge(borrowing)
    const borrowedDate = this.formatDate(borrowing.borrowed_date)
    const dueDate = this.formatDate(borrowing.due_date)
    const returnDate = borrowing.returned_date 
      ? this.formatDate(borrowing.returned_date)
      : "Not returned"

    const returnButton = isLibrarian && !borrowing.returned_date
      ? `<button class="btn btn-success btn-sm" 
                 data-action="click->borrowings#returnBook"
                 data-borrowing-id="${borrowing.id}">
           Return
         </button>`
      : ''

    return `
      <tr>
        ${isLibrarian ? `<td><a href="/members/${borrowing.member.id}">${this.escapeHtml(borrowing.member.name)}</a></td>` : ''}
        <td><a href="/books/${borrowing.book.id}">${this.escapeHtml(borrowing.book.title)}</a></td>
        <td>${borrowedDate}</td>
        <td>${dueDate}</td>
        <td>${returnDate}</td>
        <td>${statusBadge}</td>
        <td>
          <div class="action-buttons" style="display: flex; gap: 5px;">
            <a href="/borrowings/${borrowing.id}" class="btn btn-secondary btn-sm">Details</a>
            ${returnButton}
          </div>
        </td>
      </tr>
    `
  }

getStatusBadge(borrowing) {
if (borrowing.returned_date || borrowing.status === 'returned') {
      return '<span class="badge badge-success">Returned</span>'
    }

    // 2. If NOT returned, then check if it is overdue
    if (borrowing.status === 'overdue' || borrowing.days_overdue > 0) {
      return `<span class="badge badge-danger">Overdue (${borrowing.days_overdue} days)</span>`
    }

    // 3. Otherwise, it is Active
    return '<span class="badge badge-info">Active</span>'
  }

  formatDate(dateString) {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })
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