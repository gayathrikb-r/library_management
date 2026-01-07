class Reservation < ApplicationRecord
  belongs_to :member
  belongs_to :book

  enum status: {
    pending: 0,
    fulfilled: 1,
    cancelled: 2
  }
  validates :reservation_date, presence: true
  validate :book_must_be_unavailable, on: :create
  validate :no_duplicate_pending_reservation, on: :create


  before_validation :set_defaults, on: :create
  after_create :send_confirmation


  def fulfill!
    transaction do
      update!(status: :fulfilled)
    end
  end

  def cancel!
    update!(status: :cancelled)
  end

  private

  def set_defaults
    self.reservation_date ||= Date.current
    self.status ||= "pending"
  end

  def book_must_be_unavailable
    return unless book

    if book.available?
      errors.add(:base, "Book is currently available and does not need reservation")
    end
  end

  def no_duplicate_pending_reservation
    return unless member && book

    if Reservation.pending.where(member: member, book: book).exists?
      errors.add(:base, "You already have a pending reservation for this book")
    end
  end

  def send_confirmation
    Rails.logger.info("Reservation confirmation sent to #{member.email}")
  end
end
