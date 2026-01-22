// app/javascript/controllers/borrowings_controller.js
import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = ["table", "filters"]
  static values = { 
    filter: String,
    memberId: String
  }
  
  // Define fine amount constant here
  static FINE_PER_DAY = 5;

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
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

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
    
    this.element.querySelectorAll('[data-filter]').forEach(btn => {
      btn.classList.remove('btn-success')
    })
    event.currentTarget.classList.add('btn-success')
    
    this.loadBorrowings()
  }

  async returnBook(event) {
    const button = event.currentTarget
    const borrowingId = button.dataset.borrowingId
    
    // 1. Get Due Date from the button's data attribute
    const dueDateStr = button.dataset.dueDate
    
    // 2. Client-side Check: Calculate potential fine and ask for confirmation
    const confirmation = this.getConfirmationMessage(dueDateStr)

    // 3. Native OK/Cancel Dialog
    if (!confirm(confirmation)) return

    try {
      const response = await fetch(`/api/v1/borrowings/${borrowingId}/return_book`, {
        method: 'PATCH',
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const data = await response.json()
      
      if (response.ok) {
        // 4. Show success receipt from server response
        this.showReceipt(data)
        this.loadBorrowings()
      } else {
        alert(data.error || 'Error returning book')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to return book')
    }
  }

  // Helper to generate the text for the OK/Cancel box
  getConfirmationMessage(dueDateStr) {
    const today = new Date()
    today.setHours(0,0,0,0) // Reset time to midnight to ensure accurate day diff
    
    const dueDate = new Date(dueDateStr)
    // Fix parsing if needed, usually string 'YYYY-MM-DD' parses fine in JS
    
    // Calculate difference in milliseconds then convert to days
    const diffTime = today - dueDate
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
    
    if (diffDays > 0) {
      const fine = diffDays * this.constructor.FINE_PER_DAY
      return `⚠️ OVERDUE WARNING ⚠️\n\n` + 
             `This book is ${diffDays} days overdue.\n` +
             `Estimated Fine: ${fine} INR\n\n` +
             `Click OK to collect fine and return.\n` + 
             `Click Cancel to go back.`
    }
    
    return "Mark this book as returned?"
  }

  // Helper to show the final server response
  showReceipt(data) {
    if (data.alert) {
      const { title, message, amount, currency, days_overdue } = data.alert
      alert(
        `✅ RETURN SUCCESSFUL\n\n` +
        `----------------------------------\n` +
        `📅 Days Overdue:  ${days_overdue}\n` +
        `💰 FINE COLLECTED: ${currency} ${amount}\n` +
        `----------------------------------`
      )
    } else {
      alert(data.message)
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

    // CHANGED: Added data-due-date attribute so returnBook can read it
    const returnButton = isLibrarian && !borrowing.returned_date
      ? `<button class="btn btn-success btn-sm" 
                 data-action="click->borrowings#returnBook"
                 data-borrowing-id="${borrowing.id}"
                 data-due-date="${borrowing.due_date}">
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

    if (borrowing.status === 'overdue' || borrowing.days_overdue > 0) {
      return `<span class="badge badge-danger">Overdue (${borrowing.days_overdue} days)</span>`
    }

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
}