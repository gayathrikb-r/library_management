module Api
  module V1
    class ReservationsController < BaseController
      # Devise authentication
      before_action :set_reservation, only: [:show, :cancel]
      def index
  
        @reservations = current_member
                        .reservations
                        .includes(:book)
                        .order(created_at: :desc)

        render json: @reservations, include: [:book]
      end

      def show
        render json: @reservation, include: [:book]
      end

      def create

        reservation = current_member.reservations.create!(reservation_params)
        render json: reservation, status: :created
      end

      def cancel
        if @reservation.cancel!
          render json: { message: "Reservation cancelled successfully", reservation: @reservation }
        else
          render json: { error: "Could not cancel reservation" }, status: :unprocessable_entity
        end
      end

      private

      def set_reservation
        @reservation = current_member.reservations.find(params[:id])
      end

      def reservation_params
        params.require(:reservation).permit(:book_id)
      end
    end
  end
end