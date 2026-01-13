module Api
  module V1
    class AuthorsController < BaseController
      before_action :set_author, only: [:show, :update, :destroy]
      before_action :authenticate_librarian!, only: [:create, :update, :destroy]
      skip_before_action :doorkeeper_authorize!, only: [:index, :show], raise: false
      
      def index
        authors_query = Author.order(:name)
        
        if params[:search].present?
          search_term = "%#{params[:search].downcase}%"
          authors_query = authors_query.where("LOWER(name) LIKE ?", search_term)
        end
        
        # Use 'limit' instead of 'items'
        pagy, authors = pagy(authors_query, limit: params[:per_page] || 20)
        
        render json: {
          authors: authors,
          meta: pagination_meta(pagy)
        }
      end
      
      def show
        # 1. Filter Reviews based on Role
        reviews_scope = @author.reviews.includes(:reviewer).order(created_at: :desc)
        
        if librarian_signed_in?
          @reviews = reviews_scope
        elsif member_signed_in?
          @reviews = reviews_scope.where(status: :approved)
                                   .or(reviews_scope.where(reviewer: current_member))
        else
          @reviews = reviews_scope.approved
        end
        
        # 2. Render JSON with Reviews and Books
        render json: {
          author: @author,
          books: @author.books.select(:id, :title, :publication_year),
          reviews: @reviews.as_json(include: { reviewer: { only: [:id, :name] } })
        }
      end
      
      def create
        @author = Author.new(author_params)
        
        if @author.save
          render json: @author, status: :created
        else
          render json: { errors: @author.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      def update
        if @author.update(author_params)
          render json: @author
        else
          render json: { errors: @author.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      def destroy
        if @author.destroy
          head :no_content
        else
          render json: { 
            errors: ["Could not delete author. They might be linked to active records."] 
          }, status: :unprocessable_entity
        end
      end
      
      private
      
      def set_author
        @author = Author.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Author not found" }, status: :not_found
      end
      
      def author_params
        params.require(:author).permit(:name, :biography, :birth_date)
      end
    end
  end
end