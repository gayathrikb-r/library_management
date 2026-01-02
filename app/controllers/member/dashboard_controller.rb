# app/controllers/member/dashboard_controller.rb
class Member::DashboardController < ApplicationController
  before_action :authenticate_member!

  def show
    @member = current_member
    @borrowings = @member.borrowings.active.includes(:book).order(borrowed_date: :desc)
    @reservations = @member.reservations.pending.includes(:book).order(created_at: :desc)
    @recent_reviews = @member.reviews.includes(:reviewable).order(created_at: :desc).limit(5)
  end
end
