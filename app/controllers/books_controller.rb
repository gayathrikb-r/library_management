class BooksController < ApplicationController
  skip_before_action :require_login, only: [:index, :show]
  before_action :set_book, only: [:show,:edit,:update, :destroy,:borrow,:reserve]
  before_action :require_librarian, only: [:new,:create,:edit,:update, :destroy]
  
  def index
    @book=Book.includes(:authors,:categories).all
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
  end

  def new
  end

  def create
  end

  def edit
  end

  def update
  end

  def destroy
  end
end
