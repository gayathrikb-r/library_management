class ReservationsController < ApplicationController
  before_action :authenticate_member!
  before_action :set_reservation, only: [:show, :cancel]
  before_action :authorize_member!, only: [:show, :cancel]

  def index
    @reservations = current_member
      .reservations
      .includes(:book)
      .order(created_at: :desc)
  end

  def show
  end

  def cancel
    @reservation.cancel!
    redirect_to reservations_path, notice: "Reservation cancelled successfully"
  end

  private

  def set_reservation
    @reservation = Reservation.find(params[:id])
  end

  def authorize_member!
    return if @reservation.member == current_member

    redirect_to reservations_path, alert: "You are not authorized to access this reservation"
  end
end

