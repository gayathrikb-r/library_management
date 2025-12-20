class BooksController < ApplicationController
  # skip_before_action :require_login, only: [:index, :show]
 before_action :set_book, only: [:show, :edit, :update, :destroy, :borrow, :reserve]
  # before_action :require_librarian, only: [:new,:create,:edit,:update, :destroy]
  
  def index
    @books=Book.includes(:authors,:categories).all
    if params[:search].present?
      @books = @books.where("title ILIKE ? OR isbn ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    end
    # Filter by category
    if params[:category_id].present?
      @books = @books.joins(:categories).where(categories: { id: params[:category_id] })
    end
    
    # Filter by availability
    if params[:available] == 'true'
      @books = @books.available
    end    
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
    if params[:book][:new_author_name].present?
      author_names=params[:book][:new_author_name].split(',').map(&:strip).reject(&:blank?)
      author_names.each do |name|
        author=Author.find_or_create_by(name: name)
        @book.authors<<author unless @book.authors.include?(author)
      end
    end
    if params[:book][:new_category_name].present?
      category_names=params[:book][:new_category_name].split(',').map(&:strip).reject(&:blank?)
      category_names.each do |name|
        category=Category.find_or_create_by(name: name)
        @book.categories<<category unless @book.categories.include?(category)
      end
    end
    if @book.save
      flash[:notice] = "Book created successfully"
      redirect_to @book
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit

  end

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
    borrowing = User.first.borrowings.build(book: @book)
    # borrowing=current_user.borrowings.build(book: @book)
    if borrowing.save
      flash[:notice]="Book borrowed successfully! Due date: #{borrowing.due_date}"
      # redirect_to dashboard_user_path(current_user)
        redirect_to dashboard_user_path(User.first)
    else
      flash[:alert]=borrowing.errors.full_messages.join(", ")
      redirect_to @book
    end
  end
  def reserve
    reservation = User.first.reservations.build(book: @book)
    # reservation = current_user.reservations.build(book: @book)
    if reservation.save
      flash[:notice] = "Book reserved successfully! We'll notify you when it's available."
      redirect_to dashboard_user_path(User.first)
      # redirect_to dashboard_user_path(current_user)
    else
      flash[:alert] = reservation.errors.full_messages.join(", ")
      redirect_to @book
    end
  end
  private
  def set_book
    @book=Book.find(params[:id])
  end
  def book_params
    params.require(:book).permit(:title,:isbn,:publication_year,:total_copies, :available_copies,:description,author_ids: [],category_ids: [])
  end
end
