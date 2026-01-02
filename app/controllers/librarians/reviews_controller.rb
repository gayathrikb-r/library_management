class Librarians::ReviewsController < ApplicationController
  before_action :authenticate_librarian!
  before_action :set_review, only: [:approve, :show]

  def index
    @reviews = Review.includes(:reviewer, :reviewable)
                     .order(created_at: :desc)
  end


  def approve
    if @review.update(status: "approved")
      flash[:notice] = "Review approved successfully!"
    else
      flash[:alert] = "Could not approve review: #{@review.errors.full_messages.to_sentence}"
    end
    redirect_to polymorphic_path(@review.reviewable)
  end


  def show

  end

  private

  def set_review
    @review = Review.find(params[:id])
  end
end
