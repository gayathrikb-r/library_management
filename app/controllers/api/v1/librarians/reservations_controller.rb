module Api
  module V1
    module Librarians
      class ReservationsController < BaseController
        before_action :authenticate_librarian!
        before_action :set_reservation, only: [:fulfill, :cancel]

        def index
          reservations = Reservation.pending
                                    .includes(:member, :book)
                                    .order(created_at: :desc)
          
          render json: reservations.as_json(
            include: {
              member: { only: [:id, :name] },
              book: { only: [:id, :title] }
            }
          )
        end

        def fulfill
          if @reservation.fulfill!
            render json: { 
              message: "Reservation fulfilled successfully",
              reservation: @reservation.as_json(
                include: {
                  member: { only: [:id, :name] },
                  book: { only: [:id, :title] }
                }
              )
            }
          else
            error_messages = @reservation.errors.full_messages
            error_messages = ["Unable to fulfill reservation"] if error_messages.empty?
            
            Rails.logger.error("Fulfill reservation failed: #{error_messages.join(', ')}")
            
            render json: { 
              errors: error_messages
            }, status: :unprocessable_entity
          end
        end

        def cancel
          if @reservation.cancel!
            render json: { 
              message: "Reservation cancelled successfully",
              reservation: @reservation.as_json(
                include: {
                  member: { only: [:id, :name] },
                  book: { only: [:id, :title] }
                }
              )
            }
          else
            error_messages = @reservation.errors.full_messages
            error_messages = ["Unable to cancel reservation"] if error_messages.empty?
            
            Rails.logger.error("Cancel reservation failed: #{error_messages.join(', ')}")
            
            render json: { 
              errors: error_messages
            }, status: :unprocessable_entity
          end
        end

        private

        def set_reservation
          @reservation = Reservation.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          render json: { errors: ["Reservation not found"] }, status: :not_found
        end
      end
    end
  end
end