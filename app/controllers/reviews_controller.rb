class ReviewsController < ApplicationController
  before_action :set_reviewable
  before_action :set_review, only: [ :update, :edit, :destroy, :flag ]
  before_action :authorize_review_owner!, only: [:edit, :update, :destroy]
  before_action :authenticate_member!

  def create
    @review=@reviewable.reviews.build(review_params)
    @review.reviewer = current_member
    @review.status = "pending"
    if @review.save
      redirect_to @reviewable, notice: "Review submitted. It will be visible after approval."
    else
      redirect_to @reviewable, alert: @review.errors.full_messages.to_sentence
    end
  end

  def edit
  end

  def update
    if @review.update(review_params)
      redirect_to @reviewable, notice: "Review updated successfully"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    redirect_to @reviewable, notice: "Review deleted"
  end
  def flag
    @review.flag!
    redirect_to @reviewable, notice: "Review flagged for moderation"
  end
  private
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
   @review = @reviewable.reviews.find(params[:id])

  end
  def authorize_review_owner!
    return if @review.reviewer == current_member

    redirect_to @reviewable, alert: "You are not authorized to perform this action"
  end

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
