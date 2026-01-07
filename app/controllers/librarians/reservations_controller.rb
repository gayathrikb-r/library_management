class Librarians::ReservationsController < ApplicationController
    include ActionView::RecordIdentifier 
  before_action :authenticate_librarian!
  before_action :set_reservation, only: [:fulfill, :cancel]
  
  def index
    @pending_reservations = Reservation.includes(:member, :book)
                                      .where(status: 'pending')
                                      .order(created_at: :desc)
    
    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end
  
 def fulfill
  Rails.logger.info "=== FULFILL CALLED ==="
  Rails.logger.info "Reservation ID: #{params[:id]}"
  Rails.logger.info "DOM ID: #{dom_id(@reservation)}"
  
  @reservation.fulfill!
  
  respond_to do |format|
    format.turbo_stream do
      Rails.logger.info "=== TURBO STREAM FORMAT ==="
      render turbo_stream: [
        turbo_stream.remove(dom_id(@reservation)),
        turbo_stream.update("flash_messages", partial: "shared/flash", locals: { 
          message: "Reservation fulfilled successfully", 
          type: "success" 
        })
      ]
    end
    format.html { redirect_to librarians_dashboard_path, notice: "Reservation fulfilled" }
  end
end
  
  def cancel
    @reservation.cancel!
    
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(dom_id(@reservation)),
          turbo_stream.update("flash_messages", partial: "shared/flash", locals: { 
            message: "Reservation cancelled", 
            type: "warning" 
          })
        ]
      end
      format.html { redirect_to librarians_dashboard_path, alert: "Reservation cancelled" }
    end
  end
  
  private
  
  def set_reservation
    @reservation = Reservation.find(params[:id])
  end
end