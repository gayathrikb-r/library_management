import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = ["table", "flash"]

  connect() {
    this.loadReservations()
  }

  async loadReservations() {
    try {
      const response = await fetch('/api/v1/librarians/reservations', {
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const reservations = await response.json()
      this.renderReservations(reservations)
    } catch (error) {
      console.error('Error loading reservations:', error)
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
        this.showFlash(data.message, 'success')
        this.loadReservations()
      } else {
        this.showFlash(data.errors?.join(', ') || 'Error fulfilling reservation', 'error')
      }
    } catch (error) {
      console.error('Error:', error)
      this.showFlash('Failed to fulfill reservation', 'error')
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
        this.showFlash(data.message, 'warning')
        this.loadReservations()
      } else {
        this.showFlash(data.errors?.join(', ') || 'Error cancelling reservation', 'error')
      }
    } catch (error) {
      console.error('Error:', error)
      this.showFlash('Failed to cancel reservation', 'error')
    }
  }

  renderReservations(reservations) {
    if (!reservations || reservations.length === 0) {
      this.tableTarget.innerHTML = '<p>No pending reservations 🎉</p>'
      return
    }

    this.tableTarget.innerHTML = `
      <table>
        <thead>
          <tr>
            <th>Member</th>
            <th>Book</th>
            <th>Reserved On</th>
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
      <tr id="reservation-${reservation.id}">
        <td>${this.escapeHtml(reservation.member.name)}</td>
        <td><a href="/books/${reservation.book.id}">${this.escapeHtml(reservation.book.title)}</a></td>
        <td>${this.formatDate(reservation.created_at)}</td>
        <td>
          <div class="action-buttons">
            <button class="btn btn-success" 
                    data-action="click->librarian-reservations#fulfillReservation"
                    data-reservation-id="${reservation.id}">
              Fulfill
            </button>
            <button class="btn btn-danger" 
                    data-action="click->librarian-reservations#cancelReservation"
                    data-reservation-id="${reservation.id}">
              Cancel
            </button>
          </div>
        </td>
      </tr>
    `
  }

  showFlash(message, type) {
    const flashClass = type === 'success' ? 'notice' : 'alert'
    this.flashTarget.innerHTML = `
      <div class="flash ${flashClass}" style="animation: slideIn 0.3s ease-out;">
        ${this.escapeHtml(message)}
      </div>
    `

    setTimeout(() => {
      const flashElement = this.flashTarget.querySelector('.flash')
      if (flashElement) {
        flashElement.style.transition = 'opacity 0.5s ease-out'
        flashElement.style.opacity = '0'
        setTimeout(() => {
          flashElement.remove()
        }, 500)
      }
    }, 3000)
  }

  formatDate(dateString) {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' })
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}