module Api
  module V1
    module Librarians
      class ReservationsController < BaseController
   
        
        before_action :set_reservation, only: [:fulfill, :cancel]

        def index
          @pending_reservations = Reservation.includes(:member, :book)
                                            .where(status: 'pending')
                                            .order(created_at: :desc)
          
          render json: @pending_reservations, include: [:member, :book]
        end

        def fulfill
          if @reservation.fulfill!
            render json: { 
              message: "Reservation fulfilled successfully", 
              reservation: @reservation.as_json(include: [:member, :book]) 
            }, status: :ok
          else
            render json: { error: "Could not fulfill reservation" }, status: :unprocessable_entity
          end
        end

     
        def cancel
  
          if @reservation.cancel!
            render json: { 
              message: "Reservation cancelled", 
              reservation: @reservation.as_json(include: [:member, :book]) 
            }, status: :ok
          else
            render json: { error: "Could not cancel reservation" }, status: :unprocessable_entity
          end
        end

        private

        def set_reservation
          @reservation = Reservation.find(params[:id])
        end
      end
    end
  end
end