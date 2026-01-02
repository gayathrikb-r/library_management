class Librarians::DashboardController < ApplicationController
  before_action :authenticate_librarian!

  def index
    # Core stats
    @total_books = Book.count
    @total_members = Member.count

    # Borrowings
    @active_borrowings = Borrowing.active.count
    @overdue_borrowings = Borrowing.overdue.count

    @recent_borrowings = Borrowing
      .includes(:member, :book)
      .order(created_at: :desc)
      .limit(10)

    # Reservations
    @pending_reservations = Reservation.pending.count

    # Reviews (pending approval)
    @pending_reviews = Review
      .pending
      .includes(:reviewer, :reviewable)
      .count

    # Overdue books list
    @overdue_books = Borrowing
      .overdue
      .includes(:member, :book)
      .order(due_date: :asc)
      
  end
end
