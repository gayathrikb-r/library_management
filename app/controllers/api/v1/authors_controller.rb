module Api
  module V1
    class AuthorsController < BaseController
      before_action :set_author, only: [:show, :update, :destroy]

      def index
        authors = if params[:search].present?
                    Author.search_by_name(params[:search]).order(:name)
                  else
                    Author.order(:name)
                  end
        
        render json: authors
      end

      def show
         books = @author.books.includes(:categories) 
         reviews = if librarian_signed_in?
                  @author.reviews.includes(:reviewer)
                elsif member_signed_in?#1=approved
                  @author.reviews.where("status = ? OR reviewer_id = ?", 1, current_member.id)
                                .includes(:reviewer)
                else
                  @author.reviews.approved.includes(:reviewer)
                end

      render json: {
        author: @author,
        books: books.as_json(include: :categories),
        reviews: reviews.as_json(include: :reviewer)
      }
      end

      def create
        author = Author.create!(author_params)
        render json: author, status: :created
      end

      def update
        @author.update!(author_params)
        render json: @author
      end

      def destroy
        @author.destroy!
        head :no_content
      end

      private

      def set_author
        @author = Author.find(params[:id])
      end

      def author_params
        params.require(:author).permit(:name, :biography, :birth_date)
      end
    end
  end
end