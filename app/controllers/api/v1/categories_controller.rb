module Api
  module V1
    class CategoriesController < BaseController
      before_action :set_category, only: [:show, :update, :destroy]
      def index
        categories = Category.order(:name)
        render json: categories
      end

      def show
        books = @category.books.includes(:authors)
        
        render json: {
          category: @category,
          books: books.as_json(include: :authors)
        }
      end

      def create
        category = Category.create!(category_params)
        render json: category, status: :created
      end

      def update
        @category.update!(category_params)
        render json: @category
      end

      def destroy
        @category.destroy!
        head :no_content 
      end

      private

      def set_category
        @category = Category.find(params[:id])
      end

      def category_params
        params.require(:category).permit(:name)
      end
    end
  end
end