module Api
  module V1
    class CategoriesController < BaseController
      before_action :authenticate_librarian!, except: [ :index, :show ]
      before_action :set_category, only: [ :show, :update, :destroy ]
      skip_before_action :doorkeeper_authorize!, only: [ :index, :show ]

      def index
        categories_query = Category.order(:name)
        pagy, categories = pagy(categories_query, limit: params[:per_page] || 20)

        render json: {
          categories: categories.as_json(methods: [ :books_count ]),
          meta: pagination_meta(pagy)
        }
      end

      def show
        books = @category.books.includes(:authors)

        render json: {
          category: @category,
          books: books.as_json(include: :authors, methods: [ :available_copies ])
        }
      end

      def create
        category = Category.new(category_params)

        if category.save
          render json: category, status: :created
        else
          render json: { errors: category.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        if @category.update(category_params)
          render json: @category
        else
          render json: { errors: @category.errors.full_messages }, status: :unprocessable_content
        end
      end

      def destroy
        if @category.destroy
          head :no_content
        else
          render json: { errors: @category.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

      def set_category
        @category = Category.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Category not found" }, status: :not_found
      end

      def category_params
        params.require(:category).permit(:name)
      end
    end
  end
end
