class CategoriesController < ApplicationController
  # skip_before_action :require_login, only: [:index, :show]
  before_action :set_category, only: [:show, :edit, :update, :destroy]
  # before_action :require_librarian, only: [:new, :create, :edit, :update, :destroy]
  
  def index
    @categories=Category.all.order(:name)
  end

  def show
    @books=@category.books.includes(:authors)
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      flash[:notice] = "Category created successfully"
      redirect_to categories_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
   if @category.update(category_params)
      flash[:notice] = "Category updated successfully"
      redirect_to categories_path
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroy
    flash[:notice] = "Category deleted"
    else
      flash[:alert] = @category.errors.full_messages.to_sentence
    end
    redirect_to categories_path
  end

  private
  def set_category
    @category = Category.find(params[:id])
  end
  
  def category_params
    params.require(:category).permit(:name)
  end
end
