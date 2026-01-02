class BorrowingsController < ApplicationController
  # Allow either member or librarian
  before_action :authenticate_any!
  before_action :set_borrowing, only: [:show, :return_book]

 def index
  if librarian_signed_in?
    if params[:member_id].present?
      @member = Member.find(params[:member_id])
      @borrowings = @member.borrowings.includes(:book).order(created_at: :desc)
    else
      @borrowings = Borrowing.includes(:book, :member).order(created_at: :desc)
    end
  else
    @borrowings = current_member.borrowings.includes(:book).order(created_at: :desc)
  end

  case params[:filter]
  when "active"
    @borrowings = @borrowings.active
  when "overdue"
    @borrowings = @borrowings.overdue
  when "returned"
    @borrowings = @borrowings.returned
  end
end

  def show
  end

  def return_book
    if @borrowing.mark_as_returned!
      flash[:notice] = "Book returned successfully"
    else
      flash[:alert] = "Could not return book"
    end

    redirect_back fallback_location: borrowings_path
  end

  private

  def authenticate_any!
    return if member_signed_in? || librarian_signed_in?
    redirect_to root_path, alert: "You must be logged in"
  end

  def set_borrowing
    if librarian_signed_in?
      @borrowing = Borrowing.find(params[:id])
    else
      @borrowing = current_member.borrowings.find(params[:id])
    end
  end
end
