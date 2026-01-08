class ReviewsController < ApplicationController

  before_action :set_reviewable, only: [:create]
  before_action :set_review, only: [:edit, :update, :destroy, :flag, :approve]
  before_action :authenticate_member_or_librarian!, only: [:destroy, :flag, :approve]
  before_action :authorize_review_owner_or_librarian!, only: [:edit, :update, :destroy]

  def create
    authenticate_member!
    @review = @reviewable.reviews.build(review_params)
    @review.reviewer = current_member
    @review.status = "pending"

    if @review.save
      redirect_to @reviewable, notice: "Review submitted. Awaiting approval."
    else
      redirect_to @reviewable, alert: @review.errors.full_messages.to_sentence
    end
  end

  def edit; end

  def update
    if @review.update(review_params)
      redirect_to @review.reviewable, notice: "Review updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    redirect_to @review.reviewable, notice: "Review deleted"
  end

  def flag
    @review.flag!
    redirect_to @review.reviewable, notice: "Review flagged for moderation"
  end


  def approve
    @review.update!(status: "approved")
    redirect_to @review.reviewable, notice: "Review approved"
  end


  private

  def authenticate_member_or_librarian!
    unless member_signed_in? || librarian_signed_in?
      redirect_to login_path, alert: "You must be signed in to perform this action"
    end
  end

  # Authorization: member can edit/delete own, librarian can delete any
  def authorize_review_owner_or_librarian!
    return if (member_signed_in? && @review.reviewer == current_member)
    return if librarian_signed_in?

    redirect_to @review.reviewable, alert: "You are not authorized to perform this action"
  end

  def set_reviewable
    @reviewable =
      if params[:book_id]
        Book.find(params[:book_id])
      elsif params[:author_id]
        Author.find(params[:author_id])
      else
        raise ActiveRecord::RecordNotFound
      end
  end

  def set_review
    @review = Review.find(params[:id])
  end

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
