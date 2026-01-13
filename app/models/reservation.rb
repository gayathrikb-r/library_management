# app/models/reservation.rb
class Reservation < ApplicationRecord
  belongs_to :member
  belongs_to :book
  
  # ENUM (integer-based: pending=0, fulfilled=1, cancelled=2)
  enum status: {
    pending: 0,
    fulfilled: 1,
    cancelled: 2
  }
  
  # Validations
  validates :book_id, presence: true
  validates :member_id, presence: true
  validates :reservation_date, presence: true
  validates :status, presence: true
  validate :book_must_be_unavailable, on: :create, unless: :skip_availability_check
  validate :no_duplicate_pending_reservation, on: :create
  
  # Attribute for bypassing validation
  attr_accessor :skip_availability_check
  
  # Callbacks
  before_validation :set_defaults, on: :create
  after_create :send_confirmation
  
  # Fulfill reservation - create borrowing and mark as fulfilled
  def fulfill!
    return false unless pending?
    
    transaction do
      begin
        # Step 1: Temporarily increment book's available_copies for validation
        original_available = book.available_copies
        book.update_column(:available_copies, original_available + 1)
        
        # Step 2: Create the borrowing (this will decrement available_copies back)
        borrowing = book.borrowings.create!(
          member: member,
          borrowed_date: Date.current,
          due_date: 2.weeks.from_now,
          status: :borrowed
        )
        
        # Step 3: Update reservation status to fulfilled
        update_column(:status, Reservation.statuses[:fulfilled])
        
        Rails.logger.info("Reservation #{id} fulfilled successfully. Borrowing #{borrowing.id} created.")
        return true
        
      rescue ActiveRecord::RecordInvalid => e
        # If borrowing creation failed, restore original available_copies
        book.update_column(:available_copies, original_available)
        
        Rails.logger.error("Fulfill reservation #{id} failed: #{e.message}")
        Rails.logger.error("Borrowing errors: #{e.record.errors.full_messages}")
        errors.add(:base, e.record.errors.full_messages.join(", "))
        raise ActiveRecord::Rollback
        
      rescue => e
        # Restore original available_copies on any error
        book.update_column(:available_copies, original_available) if defined?(original_available)
        
        Rails.logger.error("Fulfill reservation #{id} error: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        errors.add(:base, "Failed to fulfill reservation: #{e.message}")
        raise ActiveRecord::Rollback
      end
    end
    
    false
  end
  
  # Cancel reservation
  def cancel!
    return false if fulfilled?
    return false unless pending? || cancelled?
    
    # Use update_column to skip the book_must_be_unavailable validation
    result = update_column(:status, Reservation.statuses[:cancelled])
    
    if result
      Rails.logger.info("Reservation #{id} cancelled successfully")
      true
    else
      errors.add(:base, "Failed to cancel reservation")
      false
    end
  rescue => e
    Rails.logger.error("Cancel reservation #{id} error: #{e.message}")
    errors.add(:base, "Failed to cancel reservation: #{e.message}")
    false
  end
  
  # JSON serialization
  def as_json(options = {})
    super(options).merge({
      status_label: status&.humanize,
      book_title: book&.title,
      member_name: member&.name
    })
  end
  
  private
  
  def set_defaults
    self.reservation_date ||= Date.current
    self.status ||= :pending  # Use symbol for enum
  end
  
  def book_must_be_unavailable
    return unless book
    
    if book.available?
      errors.add(:base, "Book is currently available and does not need reservation")
    end
  end
  
  def no_duplicate_pending_reservation
    return unless member && book
    
    if Reservation.pending.where(member: member, book: book).where.not(id: id).exists?
      errors.add(:base, "You already have a pending reservation for this book")
    end
  end
  
  def send_confirmation
    Rails.logger.info("Reservation confirmation sent to #{member.email}")
  end
end