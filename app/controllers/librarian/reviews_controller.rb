module Librarian
  class ReviewsController <ApplicationController
    before_action :set_review, only: [:approve]
    def index
      @reviews=Review.all.includes(:user,:reviewable).order(created_at: :desc)
    end
    def approve
      @review.approve!
      @reviewable=@review.reviewable
      flash[:notice]="Review approved successfully!"
      redirect_to @reviewable
    end
    def show
      @review = Review.find(params[:id])
    end
    private
    def set_review
      @review=Review.find(params[:id])
    end
  end
end