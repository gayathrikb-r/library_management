module Api
  module V1
    class ReservationsController < BaseController
      before_action :authenticate_member!
      before_action :set_reservation, only: [ :show, :cancel ]

      def index
        @reservations = current_member.reservations.includes(:book).order(created_at: :desc)
        render json: @reservations
      end

      def show
        render json: @reservation.as_json(
          include: {
            book: { only: [ :id, :title ] },
            member: { only: [ :id, :name ] }
          }
        )
      end

      def create
        reservation = current_member.reservations.build(reservation_params)

        if reservation.save
          render json: reservation, status: :created
        else
          render json: { errors: reservation.errors.full_messages }, status: :unprocessable_content
        end
      end

      def cancel
        if @reservation.cancelled?
          return render json: {
            message: "Reservation is already cancelled",
            reservation: @reservation
          }
        end

        if @reservation.cancel!
          render json: {
            message: "Reservation cancelled successfully",
            reservation: @reservation
          }
        else
          render json: {
            error: "Could not cancel reservation"
          }, status: :unprocessable_content
        end
      end

      private

      def set_reservation
        @reservation = current_member.reservations.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Reservation not found" }, status: :not_found
      end

      def reservation_params
        params.require(:reservation).permit(:book_id)
      end
    end
  end
end
