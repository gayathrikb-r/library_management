// app/javascript/controllers/librarian_dashboard_controller.js
import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = [
    "stats",
    "overdueBooks",
    "pendingReviews",
    "recentBorrowings",
    "pendingReservations"
  ]

  connect() {
    this.loadDashboard()
  }

  async loadDashboard() {
    try {
      const response = await fetch('/api/v1/librarians/dashboard.json', {
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const data = await response.json()
      
      this.renderStats(data.stats)
      this.renderOverdueBooks(data.overdue_books)
      this.renderPendingReviews(data.pending_reviews)
      this.renderRecentBorrowings(data.recent_borrowings)
      this.renderPendingReservations(data.pending_reservations)
    } catch (error) {
      console.error('Error loading dashboard:', error)
    }
  }

  renderStats(stats) {
    this.statsTarget.innerHTML = `
      <div class="card">
        <h3>Total Books</h3>
        <p style="font-size: 2em; font-weight: bold; color: #007bff;">${stats.total_books}</p>
      </div>
      <div class="card">
        <h3>Total Members</h3>
        <p style="font-size: 2em; font-weight: bold; color: #28a745;">${stats.total_members}</p>
      </div>
      <div class="card">
        <h3>Active Borrowings</h3>
        <p style="font-size: 2em; font-weight: bold; color: #17a2b8;">${stats.active_borrowings}</p>
      </div>
      <div class="card">
        <h3>Overdue Books</h3>
        <p style="font-size: 2em; font-weight: bold; color: #dc3545;">${stats.overdue_borrowings}</p>
      </div>
      <div class="card">
        <h3>Pending Reservations</h3>
        <p style="font-size: 2em; font-weight: bold; color: #ffc107;">${stats.pending_reservations}</p>
      </div>
      <div class="card">
        <h3>Pending Reviews</h3>
        <p style="font-size: 2em; font-weight: bold; color: #6c757d;">${stats.pending_reviews}</p>
      </div>
    `
  }

  renderOverdueBooks(overdueBooks) {
    if (overdueBooks.length === 0) {
      this.overdueBooksTarget.innerHTML = '<p>No overdue books! 🎉</p>'
      return
    }

    this.overdueBooksTarget.innerHTML = `
      <table class="table table-striped">
        <thead>
          <tr>
            <th>Member</th>
            <th>Book</th>
            <th>Due Date</th>
            <th>Days Overdue</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          ${overdueBooks.map(b => `
            <tr>
              <td><a href="/members/${b.member.id}">${this.escapeHtml(b.member.name)}</a></td>
              <td><a href="/books/${b.book.id}">${this.escapeHtml(b.book.title)}</a></td>
              <td>${this.formatDate(b.due_date)}</td>
              <td>
                <span class="badge badge-danger">${b.days_overdue} days</span>
              </td>
              <td>
                <a href="/borrowings/${b.id}" class="btn btn-sm btn-secondary">View</a>
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `
  }

  renderPendingReviews(reviews) {
    if (reviews.length === 0) {
      this.pendingReviewsTarget.innerHTML = '<p>No pending reviews 🎉</p>'
      return
    }

    this.pendingReviewsTarget.innerHTML = `
      <table class="table table-striped">
        <thead>
          <tr>
            <th>Reviewer</th>
            <th>Item</th>
            <th>Rating</th>
            <th>Comment</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          ${reviews.map(r => `
            <tr id="review-${r.id}">
              <td>${this.escapeHtml(r.reviewer.name)}</td>
              <td>
                <a href="${this.getReviewableUrl(r.reviewable_type, r.reviewable_id)}">
                  ${this.escapeHtml(r.reviewable_title)}
                </a>
              </td>
              <td>${r.rating}/5</td>
              <td>${this.truncate(this.escapeHtml(r.comment), 80)}</td>
              <td>
                <div class="btn-group">
                  <button 
                    class="btn btn-success btn-sm" 
                    data-action="click->librarian-dashboard#approveReview"
                    data-review-id="${r.id}">
                    Approve
                  </button>
                  <button 
                    class="btn btn-danger btn-sm" 
                    data-action="click->librarian-dashboard#deleteReview"
                    data-review-id="${r.id}">
                    Delete
                  </button>
                </div>
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `
  }

  renderRecentBorrowings(borrowings) {
    if (borrowings.length === 0) {
      this.recentBorrowingsTarget.innerHTML = '<p>No recent borrowings.</p>'
      return
    }

    this.recentBorrowingsTarget.innerHTML = `
      <table class="table table-striped">
        <thead>
          <tr>
            <th>Member</th>
            <th>Book</th>
            <th>Borrowed On</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          ${borrowings.map(b => `
            <tr>
              <td><a href="/members/${b.member.id}">${this.escapeHtml(b.member.name)}</a></td>
              <td><a href="/books/${b.book.id}">${this.escapeHtml(b.book.title)}</a></td>
              <td>${this.formatDate(b.created_at)}</td>
              <td>${this.statusBadge(b.status)}</td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `
  }

  renderPendingReservations(reservations) {
    if (reservations.length === 0) {
      this.pendingReservationsTarget.innerHTML = '<p>No pending reservations 🎉</p>'
      return
    }

    this.pendingReservationsTarget.innerHTML = `
      <table class="table table-striped">
        <thead>
          <tr>
            <th>Member</th>
            <th>Book</th>
            <th>Reserved On</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          ${reservations.map(r => `
            <tr id="reservation-${r.id}">
              <td><a href="/members/${r.member.id}">${this.escapeHtml(r.member.name)}</a></td>
              <td><a href="/books/${r.book.id}">${this.escapeHtml(r.book.title)}</a></td>
              <td>${this.formatDate(r.created_at)}</td>
              <td>
                <div class="action-buttons">
                  <button 
                    class="btn btn-success btn-sm" 
                    data-action="click->librarian-dashboard#fulfillReservation"
                    data-reservation-id="${r.id}">
                    Fulfill
                  </button>
                  <button 
                    class="btn btn-danger btn-sm" 
                    data-action="click->librarian-dashboard#cancelReservation"
                    data-reservation-id="${r.id}">
                    Cancel
                  </button>
                </div>
              </td>
            </tr>
          `).join('')}
        </tbody>
      </table>
    `
  }

  // --- ACTIONS ---

  async approveReview(event) {
    const reviewId = event.currentTarget.dataset.reviewId
    if (!confirm('Approve this review?')) return

    try {
      const response = await fetch(`/api/v1/reviews/${reviewId}/approve`, {
        method: 'PATCH',
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        this.loadDashboard()
      } else {
        alert('Error approving review')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to approve review')
    }
  }

  async deleteReview(event) {
    const reviewId = event.currentTarget.dataset.reviewId
    if (!confirm('Delete this review?')) return

    try {
      const response = await fetch(`/api/v1/reviews/${reviewId}`, {
        method: 'DELETE',
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }
      
      if (response.ok) {
        alert('Review deleted')
        this.loadDashboard()
      } else {
        alert('Error deleting review')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to delete review')
    }
  }

  async fulfillReservation(event) {
    const reservationId = event.currentTarget.dataset.reservationId
    if (!confirm('Fulfill this reservation?')) return

    try {
      const response = await fetch(`/api/v1/librarians/reservations/${reservationId}/fulfill`, {
        method: 'PATCH',
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        this.loadDashboard()
      } else {
        alert(data.errors?.join(', ') || 'Error fulfilling reservation')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to fulfill reservation')
    }
  }

  async cancelReservation(event) {
    const reservationId = event.currentTarget.dataset.reservationId
    if (!confirm('Cancel this reservation?')) return

    try {
      const response = await fetch(`/api/v1/librarians/reservations/${reservationId}/cancel`, {
        method: 'PATCH',
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        this.loadDashboard()
      } else {
        alert(data.errors?.join(', ') || 'Error canceling reservation')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to cancel reservation')
    }
  }

  // --- HELPERS ---

  getReviewableUrl(type, id) {
    const typeMap = {
      'Book': 'books',
      'Author': 'authors'
    }
    return `/${typeMap[type] || 'books'}/${id}`
  }

  statusBadge(status) {
    const badges = {
      'active': '<span class="badge badge-info" style="background-color: #17a2b8; color: white;">Active</span>',
      'borrowed': '<span class="badge badge-info" style="background-color: #17a2b8; color: white;">Active</span>',
      'overdue': '<span class="badge badge-danger">Overdue</span>',
      'returned': '<span class="badge badge-success">Returned</span>'
    }
    return badges[status] || `<span class="badge badge-secondary">${status}</span>`
  }

  formatDate(dateString) {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })
  }

  truncate(text, length) {
    return text.length > length ? text.substring(0, length) + '...' : text
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}