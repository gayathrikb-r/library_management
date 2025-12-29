class Reservation < ApplicationRecord
  belongs_to :member
  belongs_to :book

  enum :status, {
    pending: 0,
    fulfilled: 1,
    cancelled: 2
  }

  validates :reservation_date, presence: true
  validate :book_is_unavailable, on: :create
  validate :no_duplicate_reservation, on: :create

  before_validation :set_defaults, on: :create
  after_create :send_confirmation

  def cancel!
    cancelled!
  end

  private

  def set_defaults
    self.reservation_date ||= Date.today
    self.status ||= "pending"
  end

  def book_is_unavailable
    errors.add(:base, "Book is currently available") if book&.available?
  end

  def no_duplicate_reservation
    return unless member && book

    if member.reservations.pending.where(book: book).exists?
      errors.add(:base, "You already have a pending reservation for this book")
    end
  end

  def send_confirmation
    Rails.logger.info("Reservation confirmation sent to #{member.email}")
  end
end
