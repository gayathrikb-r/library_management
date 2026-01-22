// app/javascript/controllers/borrowing_show_controller.js
import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = ["details"]
  static values = { borrowingId: Number }
  

  static FINE_PER_DAY = 5;

  connect() {
    this.loadBorrowingDetails()
  }

  async loadBorrowingDetails() {
    try {
      const response = await fetch(`/api/v1/borrowings/${this.borrowingIdValue}`, {
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const borrowing = await response.json()
      this.renderBorrowing(borrowing)
    } catch (error) {
      console.error('Error loading borrowing:', error)
    }
  }

  async returnBook(event) {

    const button = event.currentTarget
    const dueDateStr = button.dataset.dueDate


    const confirmation = this.getConfirmationMessage(dueDateStr)


    if (!confirm(confirmation)) return

    try {
      const response = await fetch(`/api/v1/borrowings/${this.borrowingIdValue}/return_book`, {
        method: 'PATCH',
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const data = await response.json()
      
      if (response.ok) {
        this.handleReturnResponse(data) 
        this.loadBorrowingDetails()
      } else {
        alert(data.error || 'Error returning book')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to return book')
    }
  }


  getConfirmationMessage(dueDateStr) {
    const today = new Date()
    today.setHours(0,0,0,0) 
    
    const dueDate = new Date(dueDateStr)
    

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

  handleReturnResponse(data) {
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

  renderBorrowing(borrowing) {
    const statusBadge = this.getStatusBadge(borrowing)
    const borrowedDate = this.formatDateLong(borrowing.borrowed_date)
    const dueDate = this.formatDateLong(borrowing.due_date)
    

    const returnDate = borrowing.returned_date 
      ? this.formatDateLong(borrowing.returned_date)
      : "Not returned yet"

    
    const isBookReturned = borrowing.returned_date != null; 

 
    const returnButton = this.isLibrarianSignedIn() && !isBookReturned
      ? `<button class="btn btn-success" 
                 data-action="click->borrowing-show#returnBook"
                 data-due-date="${borrowing.due_date}">
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
    

    if (borrowing.status === 'overdue' || borrowing.days_overdue > 0) {
      return `<span class="badge badge-danger">Overdue by ${borrowing.days_overdue} days</span>`
    }
    
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
}