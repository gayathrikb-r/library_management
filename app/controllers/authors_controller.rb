class AuthorsController < ApplicationController
  # skip_before_action :require_login, only: [:index, :show]
  before_action :set_author, only: [:show,:edit, :update, :destroy]
  # before_action :require_librarian, only: [:new,:create,:edit,:update,:destroy]

  def index
    @authors=Author.all.order(:name)
    if params[:search].present?
      @authors=@authors.where("name ILIKE?","%#{params[:search]}%")
    end
  end

  def show
    @books=@author.books.includes(:categories)
    @reviews=@author.reviews.approved.includes(:user).order(created_at: :desc)
    @review=Review.new
  end

  def new
    @author=Author.new
  end

  def create
    @author=Author.new(author_params)
    if @author.save
      flash[:notice] = "Author created successfully"
      redirect_to @author
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @author.update(author_params)
      flash[:notice] = "Author updated successfully"
      redirect_to @author
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
     if @author.destroy
      flash[:notice] = "Author deleted"
      redirect_to authors_path
    else
      flash[:alert] = @author.errors.full_messages.join(", ")
      redirect_to @author
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
