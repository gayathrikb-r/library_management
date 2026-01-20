class BooksController < ApplicationController
  before_action :set_book, only: [ :show, :edit, :update, :destroy, :borrow, :reserve ]

  # Librarians can manage books
  before_action :authenticate_librarian!, only: [ :new, :create, :edit, :update, :destroy ]

  # Members can borrow or reserve
  before_action :authenticate_member!, only: [ :borrow, :reserve ]

  def index
    @books = Book.includes(:authors, :categories)
                 .search(params[:search])
                 .by_category(params[:category_id])
    @books = @books.available if params[:available] == "true"
    @books = @books.page(params[:page]).per(12)
  end

  def show
  @reviews = @book.reviews.includes(:reviewer)

  if member_signed_in?
    @reviews =
      @book.reviews
           .where(status: :approved)
           .or(@book.reviews.where(reviewer: current_member))
           .includes(:reviewer)
  end

  if librarian_signed_in?
    @reviews = @book.reviews.includes(:reviewer)
  end

  @reviews = @reviews.order(created_at: :desc)
  @review = Review.new
end


  def new
    @book = Book.new
  end

  def create
    @book = Book.new(book_params)
    if @book.save
      redirect_to @book, notice: "Book created successfully"
    else
      flash.now[:alert] = @book.errors.full_messages.join(", ")
      render :new, status: :unprocessable_content
    end
  end

  def edit; end

  def update
    if @book.update(book_params)
      redirect_to @book, notice: "Book updated successfully"
    else
      flash.now[:alert] = @book.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @book.destroy
      redirect_to books_path, notice: "Book deleted successfully"
    else
      redirect_to @book, alert: @book.errors.full_messages.join(", ")
    end
  end

  def borrow
    borrowing = current_member.borrowings.build(book: @book)
    if borrowing.save
      redirect_to member_dashboard_path,
                  notice: "Book borrowed successfully! Due date: #{borrowing.due_date}"
    else
      redirect_to @book, alert: borrowing.errors.full_messages.join(", ")
    end
  end

  def reserve
    reservation = current_member.reservations.build(book: @book)
    if reservation.save
      redirect_to member_dashboard_path,
                  notice: "Book reserved successfully! We'll notify you when it's available."
    else
      redirect_to @book, alert: reservation.errors.full_messages.join(", ")
    end
  end

  private

  def set_book
    @book = Book.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to books_path, alert: "Book not found."
  end

  def book_params
    params.require(:book).permit(
      :title, :isbn, :publication_year,
      :total_copies, :available_copies, :description,
      author_ids: [], category_ids: []
    )
  end
end
