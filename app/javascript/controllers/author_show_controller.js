import { Controller } from "@hotwired/stimulus"
import AuthHelper from "../services/auth_helper"

export default class extends Controller {
  static targets = ["authorDetails", "reviewsList"]
  static values = { authorId: Number }

  connect() {
    this.loadAuthorDetails()
  }

  async loadAuthorDetails() {
    try {
      const response = await fetch(`/api/v1/authors/${this.authorIdValue}`, {
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const contentType = response.headers.get("content-type")
      if (!response.ok || !contentType || !contentType.includes("application/json")) {
        console.error("Server Error: Response was not JSON")
        this.authorDetailsTarget.innerHTML = "<p class='error'>Error loading author details.</p>"
        return
      }

      const data = await response.json()
      this.renderAuthor(data.author)
      this.renderReviews(data.reviews)
    } catch (error) {
      console.error('Error loading author:', error)
    }
  }

  async submitReview(event) {
    event.preventDefault()
    const form = event.target
    const formData = new FormData(form)
    
    const reviewData = {
      rating: formData.get('review[rating]'),
      comment: formData.get('review[comment]')
    }

    try {
      const response = await fetch(`/api/v1/authors/${this.authorIdValue}/reviews`, {
        method: 'POST',
        headers: AuthHelper.getAuthHeaders(),
        body: JSON.stringify({ review: reviewData })
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        form.reset()
        this.loadAuthorDetails()
      } else {
        alert(data.errors?.join(', ') || 'Error submitting review')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to submit review')
    }
  }

  toggleEdit(event) {
    const id = event.currentTarget.dataset.reviewId
    const displayDiv = document.getElementById(`review-display-${id}`)
    const editDiv = document.getElementById(`review-edit-${id}`)
    
    if (displayDiv.style.display === "none") {
      displayDiv.style.display = "block"
      editDiv.style.display = "none"
    } else {
      displayDiv.style.display = "none"
      editDiv.style.display = "block"
    }
  }

  async updateReview(event) {
    event.preventDefault()
    const id = event.currentTarget.dataset.reviewId
    const formData = new FormData(event.target)
    
    const reviewData = {
      rating: formData.get('review[rating]'),
      comment: formData.get('review[comment]')
    }

    try {
      const response = await fetch(`/api/v1/reviews/${id}`, {
        method: 'PATCH',
        headers: AuthHelper.getAuthHeaders(),
        body: JSON.stringify({ review: reviewData })
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }
      
      if (response.ok) {
        alert('Review updated!')
        this.loadAuthorDetails()
      } else {
        const data = await response.json()
        alert(data.errors?.join(', ') || 'Update failed')
      }
    } catch (error) {
      console.error('Error:', error)
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
        this.loadAuthorDetails()
      }
    } catch (error) {
      console.error('Error:', error)
    }
  }

  async deleteAuthor() {
    if (!confirm('Are you sure? This will remove the author, but their books will remain.')) return

    try {
      const response = await fetch(`/api/v1/authors/${this.authorIdValue}`, {
        method: 'DELETE',
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }
      
      if (response.ok || response.status === 204) {
        alert('Author deleted successfully.')
        window.location.href = '/authors' 
      } else {
        const data = await response.json().catch(() => ({}))
        alert(data.errors?.join(', ') || 'Server rejected the deletion.')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to connect to the server.')
    }
  }

  async flagReview(event) {
    const reviewId = event.currentTarget.dataset.reviewId
    if (!confirm('Flag this review as inappropriate?')) return

    try {
      const response = await fetch(`/api/v1/reviews/${reviewId}/flag`, {
        method: 'PATCH',
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      if (response.ok) {
        alert("Review flagged.")
        this.loadAuthorDetails()
      }
    } catch (error) {
      console.error('Error:', error)
    }
  }

  async approveReview(event) {
    const reviewId = event.currentTarget.dataset.reviewId
    try {
      const response = await fetch(`/api/v1/reviews/${reviewId}/approve`, {
        method: 'PATCH',
        headers: AuthHelper.getAuthHeaders()
      })

      if (response.status === 401) {
        AuthHelper.handleUnauthorized()
        return
      }

      if (response.ok) {
        alert("Review approved.")
        this.loadAuthorDetails()
      }
    } catch (error) {
      console.error('Error:', error)
    }
  }

  renderAuthor(author) {
    const birthDate = author.birth_date 
      ? `<p><strong>Born:</strong> ${this.formatDate(author.birth_date)}</p>`
      : ''
    
    const isLibrarian = this.isLibrarianSignedIn()

    this.authorDetailsTarget.innerHTML = `
      <h1>${this.escapeHtml(author.name)}</h1>
      ${birthDate}
      <h3>Biography</h3>
      <p>${this.escapeHtml(author.biography || "No biography available.")}</p>
      
      ${isLibrarian ? `
        <div class="librarian-actions mt-3 pt-3 border-top">
          <a href="/authors/${author.id}/edit" class="btn btn-primary btn-sm">Edit</a>
          <button class="btn btn-danger btn-sm" data-action="click->author-show#deleteAuthor">Delete</button>
        </div>`
      : ''}
    `
  }

  renderReviews(reviews) {
    const isMember = this.isMemberSignedIn()
    const hasAlreadyReviewed = reviews.some(r => r.reviewer?.id === this.currentMemberId())
    const canWriteReview = isMember && !hasAlreadyReviewed
    
    this.reviewsListTarget.innerHTML = `
      <h3>Reviews (${reviews.length})</h3>
      
      ${canWriteReview ? `
        <div class="card mb-4 p-3">
          <h4>Write a Review</h4>
          <form data-action="submit->author-show#submitReview">
            <div class="form-group mb-2">
              <label>Rating</label>
              <select name="review[rating]" class="form-control" required>
                ${[5,4,3,2,1].map(n => `<option value="${n}">${n}</option>`).join('')}
              </select>
            </div>
            <div class="form-group mb-2">
              <label>Comment</label>
              <textarea name="review[comment]" rows="3" class="form-control" required></textarea>
            </div>
            <button type="submit" class="btn btn-primary">Submit Review</button>
          </form>
        </div>
      ` : isMember && hasAlreadyReviewed ? '<p class="text-muted"><i>You have reviewed this author.</i></p>' : ''}
      
      <div class="reviews-container">
        ${reviews.length > 0 ? reviews.map(review => this.reviewCard(review)).join('') : '<p>No reviews yet.</p>'}
      </div>
    `
  }

  reviewCard(review) {
    const stars = "⭐".repeat(review.rating)
    const date = new Date(review.created_at).toLocaleDateString('en-US', { 
      year: 'numeric', month: 'long', day: 'numeric' 
    })
    
    const isOwner = this.isMemberSignedIn() && review.reviewer?.id === this.currentMemberId()
    const isLibrarian = this.isLibrarianSignedIn()
    const isMember = this.isMemberSignedIn()
    const canFlag = isMember && !isOwner && review.status === 'approved'
    
    return `
      <div class="review-card border p-3 mb-3 rounded" id="review-container-${review.id}">
        <div id="review-display-${review.id}">
          <p>
            <strong>${this.escapeHtml(review.reviewer?.name || "Anonymous")}</strong>
            <span class="star-rating">${stars}</span>
            ${review.status === 'pending' ? `
              <span class="badge badge-warning">
                ${isOwner ? 'Pending for approval' : 'Under Moderation'}
              </span>
            ` : ''}
            ${review.status === 'flagged' ? '<span class="badge bg-danger">Flagged</span>' : ''}
          </p>
          <p class="review-comment">${this.escapeHtml(review.comment)}</p>
          <p class="review-date text-muted small">${date}</p>
          
          <div class="review-actions mt-2">
            ${isOwner ? `
              <button class="btn btn-primary btn-sm" data-action="click->author-show#toggleEdit" data-review-id="${review.id}">Edit</button>
              <button class="btn btn-danger btn-sm" data-action="click->author-show#deleteReview" data-review-id="${review.id}">Delete</button>
            ` : ''}
            
            ${canFlag ? `
              <button class="btn btn-warning btn-sm" data-action="click->author-show#flagReview" data-review-id="${review.id}">Flag</button>
            ` : ''}
            
            ${isLibrarian ? `
              <button class="btn btn-danger btn-sm" data-action="click->author-show#deleteReview" data-review-id="${review.id}">Delete</button>
              ${review.status !== 'approved' ? `
                <button class="btn btn-success btn-sm" data-action="click->author-show#approveReview" data-review-id="${review.id}">Approve</button>
              ` : ''}
            ` : ''}
          </div>
        </div>

        <div id="review-edit-${review.id}" style="display: none;">
          <form data-action="submit->author-show#updateReview" data-review-id="${review.id}">
            <select name="review[rating]" class="form-control mb-2">
              ${[5,4,3,2,1].map(n => `<option value="${n}" ${n == review.rating ? 'selected' : ''}>${n} Stars</option>`).join('')}
            </select>
            <textarea name="review[comment]" class="form-control mb-2">${this.escapeHtml(review.comment)}</textarea>
            <button type="submit" class="btn btn-success btn-sm">Save</button>
            <button type="button" class="btn btn-secondary btn-sm" data-action="click->author-show#toggleEdit" data-review-id="${review.id}">Cancel</button>
          </form>
        </div>
      </div>
    `
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
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}
