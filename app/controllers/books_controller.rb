class BooksController < ApplicationController
  before_action :set_book, only: [:show, :edit, :update, :destroy, :borrow, :reserve]

  def index
    @books = Book.includes(:authors, :categories)
                 .search(params[:search])
                 .by_category(params[:category_id])
    @books = @books.available if params[:available] == "true"
    @books = @books.page(params[:page]).per(12)
  end

  def show
    @reviews = @book.reviews.approved.includes(:user).order(created_at: :desc)
    @review = Review.new
  end

  def new
    @book = Book.new
  end

  def create
    @book = Book.new(book_params)
    if @book.save
      flash[:notice] = "Book created successfully"
      redirect_to @book
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @book.update(book_params)
      flash[:notice] = "Book updated successfully"
      redirect_to @book
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @book.destroy
      flash[:notice] = "Book deleted"
      redirect_to books_path
    else
      flash[:alert] = @book.errors.full_messages.join(", ")
      redirect_to @book
    end
  end

  def borrow
    borrowing = current_member.borrowings.build(book: @book)
    if borrowing.save
      flash[:notice] = "Book borrowed successfully! Due date: #{borrowing.due_date}"
      redirect_to member_dashboard_path
    else
      flash[:alert] = borrowing.errors.full_messages.join(", ")
      redirect_to @book
    end
  end

  def reserve
    reservation = current_member.reservations.build(book: @book)
    if reservation.save
      flash[:notice] = "Book reserved successfully! We'll notify you when it's available."
      redirect_to member_dashboard_path
    else
      flash[:alert] = reservation.errors.full_messages.join(", ")
      redirect_to @book
    end
  end

  private

  def set_book
    @book = Book.find(params[:id])
  end

  def book_params
    # Only allow IDs for existing authors and categories
    params.require(:book).permit(
      :title, :isbn, :publication_year,
      :total_copies, :available_copies, :description,
      author_ids: [], category_ids: []
    )
  end
end
