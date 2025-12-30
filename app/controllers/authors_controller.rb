class AuthorsController < ApplicationController
  before_action :set_author, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_librarian!, except: [:index, :show]

  def index
    @authors =
      if params[:search].present?
        Author.search_by_name(params[:search]).order(:name)
      else
        Author.order(:name)
      end
  end

  def show
    @books = @author.books.includes(:categories)
    @reviews = @author.reviews.approved.includes(:user).order(created_at: :desc)
    @review = Review.new
  end

  def new
    @author = Author.new
  end

  def create
    @author = Author.new(author_params)
    if @author.save
      flash[:notice] = "Author created successfully"
      redirect_to author_path(@author)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @author.update(author_params)
      flash[:notice] = "Author updated successfully"
      redirect_to author_path(@author)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @author.destroy
      flash[:notice] = "Author deleted"
      redirect_to authors_path
    else
      flash[:alert] = @author.errors.full_messages.to_sentence
      redirect_to author_path(@author)
    end
  end

  private

  def set_author
    @author = Author.find(params[:id])
  end

  def author_params
    params.require(:author).permit(:name, :biography, :birth_date)
  end
end
