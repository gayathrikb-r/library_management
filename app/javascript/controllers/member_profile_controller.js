import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = ["profile", "activity"]
  static values = { memberId: Number }

  connect() {
    this.loadMemberProfile()
  }

  async loadMemberProfile() {
    try {
      const response = await fetch(`/api/v1/members/${this.memberIdValue}`, {
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const member = await response.json()
      this.renderProfile(member)
      
      if (this.isLibrarianSignedIn()) {
        await this.loadActivityStats()
      }
    } catch (error) {
      console.error('Error loading member profile:', error)
    }
  }

  async loadActivityStats() {
    try {
      const response = await fetch(`/api/v1/members/${this.memberIdValue}/activity`, {
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const stats = await response.json()
      this.renderActivity(stats)
    } catch (error) {
      console.error('Error loading activity stats:', error)
    }
  }

  renderProfile(member) {
    const canEdit = this.canEditProfile(member)
    
    this.profileTarget.innerHTML = `
      <p><strong>Name:</strong> ${this.escapeHtml(member.name)}</p>
      <p><strong>Email:</strong> ${this.escapeHtml(member.email)}</p>
      <p><strong>Phone:</strong> ${this.escapeHtml(member.phone || "—")}</p>
      <p><strong>Bio:</strong> ${this.escapeHtml(member.bio || "—")}</p>
      <p><strong>Birth Date:</strong> ${member.birth_date ? this.formatDate(member.birth_date) : "—"}</p>
      
      ${canEdit ? `
        <a href="/members/${member.id}/edit" class="btn btn-primary">Edit Profile</a>
      ` : ''}
    `
  }

  renderActivity(stats) {
    if (!this.hasActivityTarget) return

    this.activityTarget.innerHTML = `
      <h3>📊 Library Activity</h3>
      <p><strong>Total Borrowings:</strong> ${stats.total_borrowings}</p>
      <p><strong>Active Borrowings:</strong> ${stats.active_borrowings}</p>
      <p><strong>Overdue Borrowings:</strong> ${stats.overdue_borrowings}</p>
      <a href="/borrowings?member_id=${this.memberIdValue}" class="btn btn-secondary">
        View Borrowings
      </a>
    `
  }

  canEditProfile(member) {
    return this.isMemberSignedIn() && this.currentMemberId() === member.id
  }

  isMemberSignedIn() {
    return document.body.dataset.memberSignedIn === 'true'
  }

  isLibrarianSignedIn() {
    return document.body.dataset.librarianSignedIn === 'true'
  }

  currentMemberId() {
    return parseInt(document.body.dataset.currentMemberId)
  }

  formatDate(dateString) {
    const date = new Date(dateString)
    return date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
  }

  escapeHtml(text) {
    if (!text) return ''
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}

