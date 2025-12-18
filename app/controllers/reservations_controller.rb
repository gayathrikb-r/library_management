class ReservationsController < ApplicationController
  before_action :set_reservation, only: [:show,:cancel]
  def index
    if librarian?
      @reservations=Reservation.includes(:user,:book).order(created_at: :desc)
       else
      @reservations = current_user.reservations.includes(:book).order(created_at: :desc)
    end
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
    unless librarian? || current_user==@reservation.user
      flash[:alert] = "Not authorized"
      redirect_to root_path
    end
  end
end
