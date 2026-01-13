# app/controllers/api/v1/reservations_controller.rb
module Api
  module V1
    class ReservationsController < BaseController
      before_action :authenticate_member!
      before_action :set_reservation, only: [:show, :cancel]
      
      # REMOVED: before_action :authorize_member! 
      # (It is redundant because set_reservation scopes to current_member)
# app/controllers/api/v1/reservations_controller.rb
def index
  @reservations = current_member.reservations.includes(:book).order(created_at: :desc)
  
  # Note: Since we updated the Model's as_json to include book_title, 
  # simple render json: @reservations works!
  render json: @reservations
end

      def show
        render json: @reservation.as_json(
          include: {
            book: { only: [:id, :title] },
            member: { only: [:id, :name] }
          }
        )
      end

      def create
        reservation = current_member.reservations.build(reservation_params)
        
        if reservation.save
          render json: reservation, status: :created
        else
          render json: { errors: reservation.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def cancel
        # Check if already cancelled
        if @reservation.cancelled?
          render json: { message: "Reservation is already cancelled", reservation: @reservation }
          return
        end

        if @reservation.cancel!
          render json: { 
            message: "Reservation cancelled successfully", 
            reservation: @reservation 
          }
        else
          render json: { 
            error: "Could not cancel reservation" 
          }, status: :unprocessable_entity
        end
      end

      private

      def set_reservation
        # This automatically authorizes the user because it only searches THEIR reservations.
        # If ID 5 belongs to someone else, this line will raise RecordNotFound.
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