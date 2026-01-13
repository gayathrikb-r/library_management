# app/controllers/api/v1/reviews_controller.rb
module Api
  module V1
    class ReviewsController < BaseController
      before_action :set_reviewable, only: [:create]
      before_action :set_review, only: [:update, :destroy, :flag, :approve]
      
      def create
        authenticate_member!
        
        review = @reviewable.reviews.build(review_params)
        review.reviewer = current_member
        review.status = "pending"
        
        if review.save
          render json: { message: "Review submitted. Awaiting approval.", review: review }, status: :created
        else
          render json: { errors: review.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      def update
        # Check if user owns the review or is librarian
        unless current_member == @review.reviewer || current_librarian
          return render json: { error: "Not authorized" }, status: :forbidden
        end
        
        if @review.update(review_params)
          render json: { message: "Review updated successfully", review: @review }
        else
          render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity
        end
      end
      
      def destroy
        # Check if user owns the review or is librarian
        unless current_member == @review.reviewer || current_librarian
          return render json: { error: "Not authorized" }, status: :forbidden
        end
        
        @review.destroy!
        render json: { message: "Review deleted" }
      end
      
     def flag
        authenticate_member!
        # Fixed the missing 'end' for the if statement here
        if @review.flag!
          render json: { 
            message: "Review flagged and moved to moderation.", 
            status: @review.status 
          }, status: :ok
        else
          render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity
        end
      end # This ends the
      
      def approve
        authenticate_librarian!
        if @review.approved?
          render json: { error: "Review is already approved" }, status: :unprocessable_entity
        elsif @review.update(status: "approved")
          render json: { message: "Review approved", review: @review }
        else
          render json: { errors: @review.errors.full_messages }, status: :unprocessable_entity
        end
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
      
      def review_params
        params.require(:review).permit(:rating, :comment)
      end
    end
  end
end
