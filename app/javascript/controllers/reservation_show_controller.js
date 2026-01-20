import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = ["details"]
  static values = { reservationId: Number }

  connect() {
    this.loadReservationDetails()
  }

  async loadReservationDetails() {
    try {
      const response = await fetch(`/api/v1/reservations/${this.reservationIdValue}`, {
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const reservation = await response.json()
      this.renderReservation(reservation)
    } catch (error) {
      console.error('Error loading reservation:', error)
    }
  }

  async cancelReservation() {
    if (!confirm('Are you sure you want to cancel this reservation?')) return

    try {
      const response = await fetch(`/api/v1/reservations/${this.reservationIdValue}/cancel`, {
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
        window.location.href = '/reservations'
      } else {
        alert(data.error || 'Error cancelling reservation')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to cancel reservation')
    }
  }

  renderReservation(reservation) {
    const statusBadge = this.getStatusBadge(reservation.status)
    const cancelButton = reservation.status === 'pending'
      ? `<button class="btn btn-danger" data-action="click->reservation-show#cancelReservation">
           Cancel Reservation
         </button>`
      : ''

    this.detailsTarget.innerHTML = `
      <h1>Reservation Details</h1>
      <p><strong>Member:</strong> 
        <a href="/members/${reservation.member.id}">${this.escapeHtml(reservation.member.name)}</a>
      </p>
      <p><strong>Book:</strong> 
        <a href="/books/${reservation.book.id}">${this.escapeHtml(reservation.book.title)}</a>
      </p>
      <p><strong>Reserved On:</strong> ${this.formatDateLong(reservation.created_at)}</p>
      <p><strong>Status:</strong> ${statusBadge}</p>
      
      ${cancelButton}
      <a href="/reservations" class="btn btn-secondary">Back to Reservations</a>
    `
  }

  getStatusBadge(status) {
    const badges = {
      'pending': '<span class="badge badge-warning">Pending</span>',
      'fulfilled': '<span class="badge badge-success">Fulfilled</span>',
      'cancelled': '<span class="badge badge-danger">Cancelled</span>'
    }
    return badges[status] || status
  }

  formatDateLong(dateString) {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}