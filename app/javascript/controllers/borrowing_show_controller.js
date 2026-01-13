// app/javascript/controllers/borrowing_show_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["details"]
  static values = { borrowingId: Number }

  connect() {
    this.loadBorrowingDetails()
  }

  async loadBorrowingDetails() {
    try {
      const response = await fetch(`/api/v1/borrowings/${this.borrowingIdValue}`, {
        headers: this.headers()
      })
      const borrowing = await response.json()
      this.renderBorrowing(borrowing)
    } catch (error) {
      console.error('Error loading borrowing:', error)
    }
  }

  async returnBook() {
    if (!confirm('Confirm return?')) return

    try {
      const response = await fetch(`/api/v1/borrowings/${this.borrowingIdValue}/return_book`, {
        method: 'PATCH',
        headers: this.headers()
      })
      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        this.loadBorrowingDetails()
      } else {
        alert(data.error || 'Error returning book')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to return book')
    }
  }

renderBorrowing(borrowing) {
    const statusBadge = this.getStatusBadge(borrowing)
    const borrowedDate = this.formatDateLong(borrowing.borrowed_date)
    const dueDate = this.formatDateLong(borrowing.due_date)
    
    // Handle null returned_date gracefully
    const returnDate = borrowing.returned_date 
      ? this.formatDateLong(borrowing.returned_date)
      : "Not returned yet"

    // FIX: Strictly check if a returned_date exists to hide the button
    const isBookReturned = borrowing.returned_date != null; 

    // Only show button if librarian is signed in AND book is NOT returned
    const returnButton = this.isLibrarianSignedIn() && !isBookReturned
      ? `<button class="btn btn-success" data-action="click->borrowing-show#returnBook">
           Mark as Returned
         </button>`
      : ''

    this.detailsTarget.innerHTML = `
      <h1>Borrowing Details</h1>
      <p><strong>Member:</strong> 
        <a href="/members/${borrowing.member.id}">${this.escapeHtml(borrowing.member.name)}</a>
      </p>
      <p><strong>Book:</strong> 
        <a href="/books/${borrowing.book.id}">${this.escapeHtml(borrowing.book.title)}</a>
      </p>
      <p><strong>Borrowed Date:</strong> ${borrowedDate}</p>
      <p><strong>Due Date:</strong> ${dueDate}</p>
      <p><strong>Return Date:</strong> ${returnDate}</p>
      <p><strong>Status:</strong> ${statusBadge}</p>
      
      <div class="mt-3">
        ${returnButton}
        <a href="/borrowings" class="btn btn-secondary">Back</a>
      </div>
    `
  }

getStatusBadge(borrowing) {
if (borrowing.returned_date || borrowing.status === 'returned') {
      return '<span class="badge badge-success">Returned</span>'
    }
    
    // PRIORITY 2: If active and past due date
    if (borrowing.status === 'overdue' || borrowing.days_overdue > 0) {
      return `<span class="badge badge-danger">Overdue by ${borrowing.days_overdue} days</span>`
    }
    
    // PRIORITY 3: Active
    return '<span class="badge badge-info">Active</span>'
  }

  formatDateLong(dateString) {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
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