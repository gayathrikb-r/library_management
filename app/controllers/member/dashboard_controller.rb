class Member::DashboardController < ApplicationController
  before_action :authenticate_member!
  def show
    @member=current_member
    @borrowings=current_member.borrowings.active
    @reservations=current_member.reservations.pending
    @recent_reviews=current_member.reviews.order(created_at: :desc).limit(5)
  end
end
