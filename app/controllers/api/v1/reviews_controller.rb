module Api
  module V1
    class ReviewsController < BaseController

      before_action :set_reviewable, only: [:create]
      before_action :set_review, only: [:show, :update, :destroy, :flag, :approve]
      
      def create
        authenticate_member! 

        review = @reviewable.reviews.build(review_params)
        review.reviewer = current_member
        review.status = "pending"

        review.save!
        render json: { message: "Review submitted. Awaiting approval.", review: review }, status: :created
      end

      def show
        render json: @review
      end

      def update
        @review.update!(review_params)
        render json: { message: "Review updated successfully", review: @review }
      end

      def destroy
        @review.destroy!
        render json: { message: "Review deleted" }
      end

      def flag
        @review.flag!
        render json: { message: "Review flagged for moderation", review: @review }
      end

      def approve

        return render json: { error: "Not authorized" }, status: :forbidden unless librarian_signed_in?
        
        @review.update!(status: "approved")
        render json: { message: "Review approved", review: @review }
      end

      private

      def set_reviewable
        @reviewable = if params[:book_id]
                        Book.find(params[:book_id])
                      elsif params[:author_id]
                        Author.find(params[:author_id])
                      end
        render json: { error: "Reviewable not found" }, status: :not_found unless @reviewable
      end

      def set_review
        @review = Review.find(params[:id])
      end

      def authenticate_any_user!
        unless member_signed_in? || librarian_signed_in?
          render json: { error: "Please sign in" }, status: :unauthorized
        end
      end

      def authorize_review_owner_or_librarian!
        is_owner = member_signed_in? && @review.reviewer == current_member
        is_librarian = librarian_signed_in?

        unless is_owner || is_librarian
          render json: { error: "Not authorized" }, status: :forbidden
        end
      end

      def review_params
        params.require(:review).permit(:rating, :comment)
      end
    end
  end
end