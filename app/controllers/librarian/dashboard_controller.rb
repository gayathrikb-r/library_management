class Librarian::DashboardController < ApplicationController
  before_action :require_librarian
  def index
    @total_books=Book.count 
    @total_users = User.count
    @active_borrowings = Borrowing.active.count
    @overdue_borrowings = Borrowing.overdue.count
    @recent_borrowings = Borrowing.includes(:user, :book).order(created_at: :desc).limit(10)
    @pending_reservations = Reservation.pending.count
    @pending_reviews = Review.pending.count
    @overdue_books = Borrowing.overdue.includes(:user, :book).order(due_date: :asc)
  end
end
