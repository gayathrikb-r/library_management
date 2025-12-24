class ReservationsController < ApplicationController
  before_action :set_reservation, only: [:show,:cancel]
  def index
    @reservations = Reservation.includes(:user, :book).order(created_at: :desc)

  end

  def show
  end

  def cancel
    if @reservation.cancel!
      flash[:notice]="Reservation cancelled"
    else
      flash[:alert]="Could not cancel reservation"
    end
    redirect_to reservations_path
  end
  private
  def set_reservation
    @reservation=Reservation.find(params[:id])

  end
end
