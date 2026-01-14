// app/javascript/controllers/book_show_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bookDetails", "reviewsList", "reviewForm"]
  static values = { bookId: Number }

  connect() {
    this.loadBookDetails()
  }

async loadBookDetails() {
  try {
    const response = await fetch(`/api/v1/books/${this.bookIdValue}`, {
      headers: this.headers()
    })
    
    // Check if the response is actually JSON
    const contentType = response.headers.get("content-type");
    if (!response.ok || !contentType || !contentType.includes("application/json")) {
      const errorHtml = await response.text();
      console.error("SERVER ERROR HTML:", errorHtml);
      this.bookDetailsTarget.innerHTML = "<p class='error'>Internal Server Error. Check Rails Logs.</p>";
      return;
    }

    const data = await response.json()
    this.renderBook(data.book)
    this.renderReviews(data.reviews)
  } catch (error) {
    console.error('Error loading book:', error)
  }
}

  async borrowBook(event) {
    const bookId = event.currentTarget.dataset.bookId
    try {
      const response = await fetch(`/api/v1/books/${bookId}/borrow`, {
        method: 'POST',
        headers: this.headers()
      })
      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        this.loadBookDetails()
      } else {
        alert(data.errors?.join(', ') || 'Error borrowing book')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to borrow book')
    }
  }

  async reserveBook(event) {
    const bookId = event.currentTarget.dataset.bookId
    try {
      const response = await fetch(`/api/v1/books/${bookId}/reserve`, {
        method: 'POST',
        headers: this.headers()
      })
      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        this.loadBookDetails()
      } else {
        alert(data.errors?.join(', ') || 'Error reserving book')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to reserve book')
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
      const response = await fetch(`/api/v1/books/${this.bookIdValue}/reviews`, {
        method: 'POST',
        headers: this.headers(),
        body: JSON.stringify({ review: reviewData })
      })
      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        form.reset()
        this.loadBookDetails()
      } else {
        alert(data.errors?.join(', ') || 'Error submitting review')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to submit review')
    }
  }

  async deleteReview(event) {
    const reviewId = event.currentTarget.dataset.reviewId
    if (!confirm('Are you sure you want to delete this review?')) return

    try {
      const response = await fetch(`/api/v1/reviews/${reviewId}`, {
        method: 'DELETE',
        headers: this.headers()
      })
      
      if (response.ok) {
        alert('Review deleted')
        this.loadBookDetails()
      } else {
        alert('Error deleting review')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to delete review')
    }
  }

  async flagReview(event) {
    const reviewId = event.currentTarget.dataset.reviewId
    try {
      const response = await fetch(`/api/v1/reviews/${reviewId}/flag`, {
        method: 'PATCH',
        headers: this.headers()
      })
      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        this.loadBookDetails()
      } else {
        alert('Error flagging review')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to flag review')
    }
  }

  async approveReview(event) {
    const reviewId = event.currentTarget.dataset.reviewId
    try {
      const response = await fetch(`/api/v1/reviews/${reviewId}/approve`, {
        method: 'PATCH',
        headers: this.headers()
      })
      const data = await response.json()
      
      if (response.ok) {
        alert(data.message)
        this.loadBookDetails()
      } else {
        alert('Error approving review')
      }
    } catch (error) {
      console.error('Error:', error)
      alert('Failed to approve review')
    }
  }

  renderBook(book) {
    const authors = book.authors?.map(a => 
      `<a href="/authors/${a.id}">${this.escapeHtml(a.name)}</a>`
    ).join(", ") || "Unknown"
    
    const categories = book.categories?.map(c => 
      `<a href="/categories/${c.id}">${this.escapeHtml(c.name)}</a>`
    ).join(", ") || "None"
    
    const stars = book.average_rating ? "⭐".repeat(Math.round(book.average_rating)) : ""
    
    const borrowButton = book.available_copies > 0 
      ? `<button class="btn btn-success" data-action="click->book-show#borrowBook" data-book-id="${book.id}">📖 Borrow This Book</button>`
      : `<button class="btn" data-action="click->book-show#reserveBook" data-book-id="${book.id}">🔖 Reserve This Book</button>`

    // Check roles
    const isLibrarian = this.isLibrarianSignedIn()
    const isMember = this.isMemberSignedIn()

    this.bookDetailsTarget.innerHTML = `
      <h1>${this.escapeHtml(book.title)}</h1>
      <p><strong>Authors:</strong> ${authors}</p>
      <p><strong>ISBN:</strong> ${book.isbn || "N/A"}</p>
      <p><strong>Published:</strong> ${book.publication_year || "N/A"}</p>
      <p><strong>Categories:</strong> ${categories}</p>
      <p><strong>Total Copies:</strong> ${book.total_copies}</p>
      <p><strong>Available:</strong> ${book.available_copies}</p>
   <p>
        <strong>Average Rating:</strong> 
        ${book.average_rating ? 
          `<span class="star-rating">${stars}</span> ${book.average_rating.toFixed(1)}/5 (${book.reviews_count} reviews)` 
          : ' No reviews yet'}
      </p>
      <h3>Description</h3>
      <p>${this.escapeHtml(book.description || "No description available.")}</p>
      
      <div class="action-row mt-3" data-member-signed-in="${isMember}">
        ${isMember ? borrowButton : ''}

        ${isLibrarian ? `
          <div class="librarian-actions mt-4 pt-3 border-top">
            <div class="btn-group">
              <a href="/books/${book.id}/edit" class="btn btn-primary">Edit Book</a>
              <button class="btn btn-danger" 
                      data-action="click->book-show#deleteBook" 
                      data-book-id="${book.id}">
                Delete Book
              </button>
            </div>
          </div>
        ` : ''}
      </div>
    `
  }

  
  async deleteBook(event) {
    if (!confirm("Are you sure you want to delete this book? This action cannot be undone.")) {
      return
    }

    try {
     
      const response = await fetch(`/api/v1/books/${this.bookIdValue}`, {
        method: 'DELETE',
        headers: this.headers()
      })

      if (response.ok) {
        alert("Book deleted successfully.")
      
        window.location.href = "/books"
      } else {
        alert("Failed to delete book. Please check if there are active borrowings.")
      }
    } catch (error) {
      console.error("Error deleting book:", error)
      alert("An error occurred while deleting the book.")
    }
  }
renderReviews(reviews) {
  const isMember = this.isMemberSignedIn()
  const isLibrarian = this.isLibrarianSignedIn()
  const currentMemberId = this.currentMemberId()

  // Control visibility
  const visibleReviews = reviews.filter(review => {
    if (isLibrarian) return true
    if (review.status === 'approved') return true
    return isMember && review.reviewer_id === currentMemberId
  })

  const hasAlreadyReviewed = reviews.some(r => r.reviewer_id === currentMemberId)
  const canWriteReview = isMember && !hasAlreadyReviewed

  this.reviewsListTarget.innerHTML = `
    <h2>Reviews (${visibleReviews.length})</h2>
    
    ${canWriteReview ? `
      <div class="card mb-4">
        <h3>Write a Review</h3>
        <form data-action="submit->book-show#submitReview">
          <div class="form-group">
            <label>Rating</label>
            <select name="review[rating]" class="form-control" required>
              ${[5,4,3,2,1].map(n => `<option value="${n}">${n}</option>`).join('')}
            </select>
          </div>
          <div class="form-group">
            <label>Comment</label>
            <textarea name="review[comment]" rows="4" class="form-control" required></textarea>
          </div>
          <button type="submit" class="btn btn-primary">Submit Review</button>
        </form>
      </div>
    ` : isMember && hasAlreadyReviewed ? '<p><i>You have already reviewed this book.</i></p>' : ''}
    
    ${visibleReviews.length > 0
      ? visibleReviews.map(review => this.reviewCard(review)).join('')
      : '<p>No reviews yet.</p>'}
  `
}

reviewCard(review) {
  const stars = "⭐".repeat(review.rating)
  const date = new Date(review.created_at).toLocaleDateString('en-US', { 
    year: 'numeric', month: 'long', day: 'numeric' 
  })
  
  const isOwner = this.isMemberSignedIn() && review.reviewer_id === this.currentMemberId()
  const isLibrarian = this.isLibrarianSignedIn()
  const isMember = this.isMemberSignedIn()

  // flagging only if review is approved
  const canFlag = isMember && !isOwner && review.status === 'approved'

  return `
    <div class="review-card" id="review-container-${review.id}">
      <div id="review-display-${review.id}">
        <p>
          <strong>${this.escapeHtml(review.reviewer?.name || "Anonymous")}</strong>
          <span class="star-rating">${stars}</span>

          ${review.status === 'pending' ? `
            <span class="badge badge-warning">
              ${isOwner ? 'Pending for approval' : 'Under Moderation'}
            </span>
          ` : ''}
        </p>

        <p class="review-comment">${this.escapeHtml(review.comment)}</p>
        <p class="review-date">${date}</p>
        
        <div class="review-actions">
          ${isOwner ? `
            <button class="btn btn-primary btn-sm" data-action="click->book-show#toggleEdit" data-review-id="${review.id}">Edit</button>
            <button class="btn btn-danger btn-sm" data-action="click->book-show#deleteReview" data-review-id="${review.id}">Delete</button>
          ` : ''}

          ${canFlag ? `
            <button class="btn btn-warning btn-sm" data-action="click->book-show#flagReview" data-review-id="${review.id}">Flag</button>
          ` : ''}

          ${isLibrarian ? `
            <button class="btn btn-danger btn-sm" data-action="click->book-show#deleteReview" data-review-id="${review.id}">Delete</button>
            ${review.status !== 'approved' ? `
              <button class="btn btn-success btn-sm" data-action="click->book-show#approveReview" data-review-id="${review.id}">Approve</button>
            ` : ''}
          ` : ''}
        </div>
      </div>

      <div id="review-edit-${review.id}" style="display: none;">
        <form data-action="submit->book-show#updateReview" data-review-id="${review.id}">
          <div class="form-group">
            <label>Rating</label>
            <select name="review[rating]" class="form-control">
              ${[5,4,3,2,1].map(n => `<option value="${n}" ${n == review.rating ? 'selected' : ''}>${n}</option>`).join('')}
            </select>
          </div>
          <div class="form-group">
            <label>Comment</label>
            <textarea name="review[comment]" class="form-control">${this.escapeHtml(review.comment)}</textarea>
          </div>
          <button type="submit" class="btn btn-success btn-sm">Save</button>
          <button type="button" class="btn btn-secondary btn-sm" data-action="click->book-show#toggleEdit" data-review-id="${review.id}">Cancel</button>
        </form>
      </div>
    </div>
  `
}
//between view mode and edit mode for the review form
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
        headers: this.headers(),
        body: JSON.stringify({ review: reviewData })
      })
      
      if (response.ok) {
        const data = await response.json()
        alert(data.message || 'Review updated!')
        this.loadBookDetails() // Refresh the list
      } else {
        const data = await response.json()
        alert(data.errors?.join(', ') || 'Update failed')
      }
    } catch (error) {
      console.error('Error:', error)
    }
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

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  headers() {
    const token = document.querySelector('meta[name="csrf-token"]')?.content
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json', 
      'X-CSRF-Token': token
    }
  }
}