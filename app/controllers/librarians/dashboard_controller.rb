class Librarians::DashboardController < ApplicationController
  before_action :authenticate_librarian!

  def index
   
    @total_books = Book.count
    @total_members = Member.count

    
    @active_borrowings = Borrowing.active.count
    @overdue_borrowings = Borrowing.overdue.count

    @recent_borrowings = Borrowing
      .includes(:member, :book)
      .order(created_at: :desc)
      .limit(10)

   
    @pending_reservations_count = Reservation.pending.count

    @pending_reservations = Reservation
      .pending
      .includes(:member, :book)
      .order(created_at: :desc)
      .limit(10)  
  
    @pending_reviews_count = Review.pending.count

    @pending_reviews = Review
      .pending
      .includes(:reviewer, :reviewable)
      .order(created_at: :desc)
      .limit(10)



    @overdue_books = Borrowing
      .overdue
      .includes(:member, :book)
      .order(due_date: :asc)
      
  end
end
