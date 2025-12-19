class BorrowingsController < ApplicationController
  # before_action :set_borrowing, only: [:show, :return_book]
  def index
     @borrowings = Borrowing.includes(:user, :book).order(created_at: :desc)
    # if librarian?
      # @borrowings=Borrowing.includes(:user,:book).order(created_at: :desc)
      # case params[:filter]
      # when 'active'
      #   @borrowings=@borrowings.active
      # when 'overdue'
      #   @borrowings=@borrowings.overdue 
      # when 'returned'
      #   @borrowings = @borrowings.returned 
      # end
    # else
    #   @borrowings=current_user.borrowings.includes(:book).order(created_at: :desc)
    # end
    case params[:filter]
    when 'active'
      @borrowings = @borrowings.active
    when 'overdue'
      @borrowings = @borrowings.overdue
    when 'returned'
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
    redirect_to borrowings_path
  end
  private
  def set_borrowing
    @borrowing=Borrowing.find(params[:id])
    # unless librarian? || @borrowing.user== current_user
    #   flash[:alert]="Not authorized"
    #   redirect_to root_path
    # end
  end
end
