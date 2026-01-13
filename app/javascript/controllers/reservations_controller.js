import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["table"]

  connect() {
    this.loadReservations()
  }

  async loadReservations() {
    try {
      const response = await fetch('/api/v1/reservations', {
        headers: this.headers()
      })
      
      // If the server crashes (500), response.json() fails with SyntaxError
      if (!response.ok) throw new Error("Server returned an error")
        
      const reservations = await response.json()
      this.renderReservations(reservations)
    } catch (error) {
      console.error('Error loading reservations:', error)
      this.tableTarget.innerHTML = `<p class="text-danger">Error loading reservations. Please try again later.</p>`
    }
  }

  async cancelReservation(event) {
    const reservationId = event.currentTarget.dataset.reservationId
    if (!confirm('Are you sure you want to cancel this reservation?')) return

    try {
      const response = await fetch(`/api/v1/reservations/${reservationId}/cancel`, {
        method: 'PATCH',
        headers: this.headers()
      })
      
      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        this.loadReservations()
      } else {
        alert(data.error || 'Error cancelling reservation')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to cancel reservation')
    }
  }

  renderReservations(reservations) {
    if (!reservations || reservations.length === 0) {
      this.tableTarget.innerHTML = '<p>No reservations found.</p>'
      return
    }

    this.tableTarget.innerHTML = `
      <table class="table table-striped">
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
    const statusBadge = this.getStatusBadge(reservation.status)
    
    // Safety check: Use book_title from our updated as_json, or fallback safely
    const bookTitle = reservation.book_title || (reservation.book ? reservation.book.title : "Unknown Book")
    
    const cancelButton = reservation.status === 'pending'
      ? `<button class="btn btn-danger btn-sm" 
                 data-action="click->reservations#cancelReservation"
                 data-reservation-id="${reservation.id}">
           Cancel
         </button>`
      : ''

    return `
      <tr>
        <td><a href="/books/${reservation.book_id}">${this.escapeHtml(bookTitle)}</a></td>
        <td>${this.formatDate(reservation.created_at)}</td>
        <td>${statusBadge}</td>
        <td>
          <div class="btn-group">
            ${cancelButton}
            <a href="/reservations/${reservation.id}" class="btn btn-secondary btn-sm">Details</a>
          </div>
        </td>
      </tr>
    `
  }

  getStatusBadge(status) {
    const badges = {
      'pending': '<span class="badge badge-warning">Pending</span>',
      'fulfilled': '<span class="badge badge-success">Fulfilled</span>',
      'cancelled': '<span class="badge badge-danger">Cancelled</span>'
    }
    return badges[status] || `<span class="badge badge-secondary">${status}</span>`
  }

  formatDate(dateString) {
    if (!dateString) return ""
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })
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