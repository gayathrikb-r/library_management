// app/javascript/controllers/member_dashboard_controller.js
import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = ["borrowings", "reservations", "reviews"]
  static values = { memberName: String }

  connect() {
    this.loadDashboard()
  }

  async loadDashboard() {
    try {
      const response = await fetch('/api/v1/member/dashboard', {
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const data = await response.json()
      
      this.renderBorrowings(data.borrowings)
      this.renderReservations(data.reservations)
      this.renderReviews(data.recent_reviews)
    } catch (error) {
      console.error('Error loading dashboard:', error)
    }
  }

  async returnBook(event) {
    const borrowingId = event.currentTarget.dataset.borrowingId
    if (!confirm('Mark this book as returned?')) return

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
        this.handleReturnResponse(data)
        this.loadDashboard()
      } else {
        alert(data.error || 'Error returning book')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to return book')
    }
  }
  handleReturnResponse(data) {
    if (data.alert) {
      const { title, amount, currency, days_overdue } = data.alert
      alert(
        `⚠️ ${title} ⚠️\n\n` +
        `You have returned this book late.\n\n` +
        `Days Overdue: ${days_overdue}\n` +
        `Fine Due: ${currency} ${amount}\n\n` +
        `Please pay at the counter.`
      )
    } else {
      alert(data.message)
    }
  }

  async cancelReservation(event) {
    const reservationId = event.currentTarget.dataset.reservationId
    if (!confirm('Cancel this reservation?')) return

    try {
      const response = await fetch(`/api/v1/reservations/${reservationId}/cancel`, {
        method: 'PATCH',
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const data = await response.json()
      
      if (response.ok) {
        alert(data.message || 'Reservation cancelled')
        this.loadDashboard()
      } else {
        alert(data.error || 'Error cancelling reservation')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to cancel reservation')
    }
  }

  renderBorrowings(borrowings) {
    if (!borrowings || borrowings.length === 0) {
      this.borrowingsTarget.innerHTML = `
        <p>No active borrowings. <a href="/books">Browse books</a> to borrow some!</p>
      `
      return
    }

    this.borrowingsTarget.innerHTML = `
      <table>
        <thead>
          <tr>
            <th>Book</th>
            <th>Borrowed Date</th>
            <th>Due Date</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          ${borrowings.map(b => this.borrowingRow(b)).join('')}
        </tbody>
      </table>
    `
  }

  borrowingRow(borrowing) {
    const statusBadge = borrowing.status === 'overdue'
      ? `<span class="badge badge-danger">Overdue by ${borrowing.days_overdue} days</span>`
      : '<span class="badge badge-success">Active</span>'

    return `
      <tr>
        <td><a href="/books/${borrowing.book.id}">${this.escapeHtml(borrowing.book.title)}</a></td>
        <td>${this.formatDate(borrowing.borrowed_date)}</td>
        <td>${this.formatDate(borrowing.due_date)}</td>
        <td>${statusBadge}</td>
        <td>
          <button class="btn btn-success" 
                  data-action="click->member-dashboard#returnBook"
                  data-borrowing-id="${borrowing.id}">
            Return
          </button>
        </td>
      </tr>
    `
  }

  renderReservations(reservations) {
    if (!reservations || reservations.length === 0) {
      this.reservationsTarget.innerHTML = '<p>No active reservations.</p>'
      return
    }

    this.reservationsTarget.innerHTML = `
      <table>
        <thead>
          <tr>
            <th>Book</th>
            <th>Reserved Date</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          ${reservations.map(r => this.reservationRow(r)).join('')}
        </tbody>
      </table>
    `
  }

  reservationRow(reservation) {
    return `
      <tr>
        <td><a href="/books/${reservation.book.id}">${this.escapeHtml(reservation.book.title)}</a></td>
        <td>${this.formatDate(reservation.created_at)}</td>
        <td><span class="badge badge-info">${this.capitalize(reservation.status)}</span></td>
        <td>
          <button class="btn btn-danger" 
                  data-action="click->member-dashboard#cancelReservation"
                  data-reservation-id="${reservation.id}">
            Cancel
          </button>
        </td>
      </tr>
    `
  }

  renderReviews(reviews) {
    if (!reviews || reviews.length === 0) {
      this.reviewsTarget.innerHTML = "<p>You haven't written any reviews yet.</p>"
      return
    }

    this.reviewsTarget.innerHTML = reviews.map(review => this.reviewCard(review)).join('')
  }

  reviewCard(review) {
    const stars = "⭐".repeat(review.rating)
    const badgeClass = review.status === 'approved' ? 'success' : 'warning'
    const title = review.reviewable_title || "Item"
    const url = this.getReviewableUrl(review.reviewable_type, review.reviewable_id)

    return `
      <div style="margin-bottom: 15px; padding: 10px; border-left: 3px solid #007bff;">
        <p><strong><a href="${url}">${this.escapeHtml(title)}</a></strong></p>
        <p class="star-rating">${stars} (${review.rating}/5)</p>
        <p>${this.escapeHtml(review.comment)}</p>
        <p style="font-size: 0.9em; color: #666;">
          Status: 
          <span class="badge badge-${badgeClass}">${this.capitalize(review.status)}</span>
        </p>
      </div>
    `
  }

  getReviewableUrl(type, id) {
    const typeMap = {
      'Book': 'books',
      'Author': 'authors'
    }
    return `/${typeMap[type] || 'books'}/${id}`
  }

  formatDate(dateString) {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })
  }

  capitalize(str) {
    return str.charAt(0).toUpperCase() + str.slice(1)
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}