class Reservation < ApplicationRecord
  belongs_to :member
  belongs_to :book

enum :status, { pending: 0, fulfilled: 1, cancelled: 2 }

  # Validations
  validates :book_id, :member_id, :reservation_date, :status, presence: true
  validate :book_must_be_unavailable, on: :create, unless: :skip_availability_check
  validate :no_duplicate_pending_reservation, on: :create

  attr_accessor :skip_availability_check

  before_validation :set_defaults, on: :create
  after_create :send_confirmation

  def fulfill!
    return false unless pending?

    transaction do
      book.lock!

      if book.available_copies <= 0
        errors.add(:base, "No available copies to fulfill reservation")
        raise ActiveRecord::Rollback
      end


      borrowing = book.borrowings.create!(
        member: member,
        borrowed_date: Date.current,
        due_date: 2.weeks.from_now,
        status: :borrowed
      )


      update!(status: :fulfilled)

      # Send email notification to the member
      ReservationMailer.book_available_notification(self).deliver_later

      Rails.logger.info("Reservation #{id} fulfilled. Borrowing #{borrowing.id} created.")
      true
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.record.errors.full_messages.join(", "))
    false
  end

  def cancel!
    return false unless pending?

    update!(status: :cancelled)
    Rails.logger.info("Reservation #{id} cancelled")
    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.record.errors.full_messages.join(", "))
    false
  end

  def as_json(options = {})
    super(options).merge(
      status_label: status&.humanize,
      book_title: book&.title,
      member_name: member&.name
    )
  end

  private

  def set_defaults
    self.reservation_date ||= Date.current
    self.status ||= :pending
  end

  def book_must_be_unavailable
    return unless book
    if book.available_copies > 0
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
