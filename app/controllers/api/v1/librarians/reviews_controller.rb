module Api
  module V1
    module Librarians
      class ReviewsController < BaseController
        before_action :authenticate_librarian!
        before_action :set_review, only: [ :show, :approve ]

        def index
          @reviews = Review.includes(:reviewer, :reviewable)
                           .order(created_at: :desc)

          render json: @reviews, include: [ :reviewer, :reviewable ]
        end

        def show
          render json: @review, include: [ :reviewer, :reviewable ]
        end

        def approve
          if @review.update(status: "approved")
            render json: {
              message: "Review approved successfully!",
              review: @review
            }, status: :ok
          else
            render json: {
              errors: @review.errors.full_messages
            }, status: :unprocessable_content
          end
        end

        private

        def set_review
          @review = Review.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { error: "Review not found" }, status: :not_found
        end
      end
    end
  end
end
