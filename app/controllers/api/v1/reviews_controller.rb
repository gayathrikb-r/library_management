module Api
  module V1
    class ReviewsController < BaseController
      before_action :set_reviewable, only: [ :create ]
      before_action :set_review, only: [ :update, :destroy, :flag, :approve ]
      before_action :authenticate_member!, only: [ :create, :flag ]
      before_action :authenticate_librarian!, only: [ :approve ]

      def create
        review = @reviewable.reviews.build(review_params)
        review.reviewer = current_member
        review.status = "pending"

        if review.save
          render json: {
            message: "Review submitted. Awaiting approval.",
            review: review
          }, status: :created
        else
          render json: { errors: review.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        unless (member_signed_in? && current_member == @review.reviewer) || librarian_signed_in?
          return render json: { error: "Not authorized" }, status: :forbidden
        end

        if @review.update(review_params)
          render json: { message: "Review updated successfully", review: @review }
        else
          render json: { errors: @review.errors.full_messages }, status: :unprocessable_content
        end
      end

      def destroy
        unless (member_signed_in? && current_member == @review.reviewer) || librarian_signed_in?
          return render json: { error: "Not authorized" }, status: :forbidden
        end

        @review.destroy!
        render json: { message: "Review deleted" }
      end

      def flag
        if @review.flag!
          render json: {
            message: "Review flagged and moved to moderation.",
            status: @review.status
          }, status: :ok
        else
          render json: { errors: @review.errors.full_messages }, status: :unprocessable_content
        end
      end

      def approve
        if @review.approved?
          return render json: { error: "Review is already approved" }, status: :unprocessable_content
        end

        if @review.update(status: "approved")
          render json: { message: "Review approved", review: @review }
        else
          render json: { errors: @review.errors.full_messages }, status: :unprocessable_content
        end
      end

      private

      def set_reviewable
        @reviewable = if params[:book_id]
          Book.find(params[:book_id])
        elsif params[:author_id]
          Author.find(params[:author_id])
        end

        unless @reviewable
          render json: { error: "Reviewable not found" }, status: :not_found
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Reviewable not found" }, status: :not_found
      end

      def set_review
        @review = Review.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Review not found" }, status: :not_found
      end

      def review_params
        params.require(:review).permit(:rating, :comment)
      end
    end
  end
end
