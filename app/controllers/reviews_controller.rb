class ReviewsController < ApplicationController
  before_action :set_reviewable
  before_action :set_review, only: [:update,:edit,:destroy,:update,:flag]
  # before_action :require_librarian, only: [:approve,:flag]
  def create
    @review=@reviewable.reviews.build(review_params)
    @review.user = User.first
    # @review.user=current_user
     if @review.save
      flash[:notice] = "Review submitted successfully. It will be visible after approval."
      redirect_to @reviewable
    else
      flash[:alert] = @review.errors.full_messages.join(", ")
      redirect_to @reviewable
    end
  end

  def edit
  end

  def update
    if @review.update(review_params)
      flash[:notice] = "Review updated"
      redirect_to @reviewable
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @review.destroy
    flash[:notice] = "Review deleted"
    redirect_to @reviewable
  end

  def approve
    @review.approve!
    flash[:notice] = "Review approved"
    redirect_to @reviewable
  end

  def flag
    @review.flag!
    flash[:notice] = "Review flagged"
    redirect_to @reviewable
  end
  private
  def set_reviewable
    if params[:book_id]
      @reviewable=Book.find(params[:book_id])
    elsif params[:author_id]
      @reviewable=Author.find(params[:author_id])
    end
  end
  def set_review
    @review=Review.find(params[:id])
    # unless librarian? || @review.user == current_user
    #   flash[:alert] = "Not authorized"
    #   redirect_to root_path
    # end
  end
  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
