class CategoriesController < ApplicationController
  # Only librarians can create/update/destroy categories
  before_action :authenticate_librarian!, except: [:index, :show]
  before_action :set_category, only: [:show, :edit, :update, :destroy]

  # GET /categories
  def index
    @categories = Category.order(:name)
  end

  # GET /categories/:id
  def show
    @books = @category.books.includes(:authors)
  end

  # GET /categories/new
  def new
    @category = Category.new
  end

  # POST /categories
  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to categories_path, notice: "Category created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /categories/:id/edit
  def edit
  end

  # PATCH/PUT /categories/:id
  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: "Category updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /categories/:id
  def destroy
    @category.destroy
    redirect_to categories_path, notice: "Category deleted"
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name)
  end
end
