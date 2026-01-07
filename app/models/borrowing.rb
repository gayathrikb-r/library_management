class Borrowing < ApplicationRecord
  belongs_to :member
  belongs_to :librarian, optional: true
  belongs_to :book
  def self.ransackable_attributes(auth_object = nil)
    ["book_id", "borrowed_date", "created_at", "due_date", "id", "id_value", "librarian_id", "member_id", "returned_date", "status", "updated_at"]
  end
  def self.ransackable_associations(auth_object = nil)
    ["book", "librarian", "member"]
  end
  enum status: { borrowed: 0, returned: 1, overdue: 2 }

  FINE_PER_DAY = 5

  validates :borrowed_date, :due_date, presence: true
  validates :member, :book, presence: true
  validate :member_can_borrow, on: :create
  validate :book_is_available, on: :create
  validate :due_date_after_borrowed_date


  # Callbacks
  before_validation :set_dates, on: :create
  before_validation :check_if_overdue
  after_create :decrease_book_availability
  after_update :increase_book_availability, if: :returned_now?
  after_update :notify_next_reservation, if: :returned_now?

  # Scopes
  scope :borrowed, -> { where(status: :borrowed) }
  scope :returned, -> { where(status: :returned) }
  scope :active, -> { borrowed }
  scope :overdue, -> {
    where(status: :overdue)
      .or(
        where(status: :borrowed)
          .where("due_date < ?", Date.today)
      )
  }
  scope :for_member, ->(member) { where(member: member) }
  scope :for_book, ->(book) { where(book: book) }
  scope :due_soon, -> { borrowed.where("due_date <= ?", 3.days.from_now) }

  def mark_as_returned!
    return if returned?
    update!(status: :returned, returned_date: Date.today)
  end

  def days_overdue
    return 0 unless overdue?
    (Date.today - due_date).to_i
  end
  def active?
  borrowed?
  end


  def calculate_fine
    days_overdue * FINE_PER_DAY
  end

  private

  def set_dates
    self.borrowed_date ||= Date.today
    self.due_date ||= borrowed_date + 14.days
  end

  def member_can_borrow
    return unless member
    if member.has_overdue_books?
      errors.add(:base, "Member has overdue books")
    elsif member.active_borrowings_count >= 5
      errors.add(:base, "Borrowing limit reached")
    end
  end

  def book_is_available
    errors.add(:base, "Book is not available") unless book&.available?
  end

  def due_date_after_borrowed_date
    return if borrowed_date.blank? || due_date.blank?
    errors.add(:due_date, "must be after borrowed date") if due_date <= borrowed_date
  end

  def decrease_book_availability
    book.decrement_available_copies!
  end

  def increase_book_availability
    book.increment_available_copies!
  end

  def returned_now?
    saved_change_to_status? && returned?
  end

  def notify_next_reservation
    reservation = book.reservations.pending.order(:reservation_date).first
    return unless reservation

    reservation.update!(status: "fulfilled")
    Rails.logger.info("Reservation fulfilled for member #{reservation.member.email}")
  end

  def check_if_overdue
    self.status = :overdue if due_date.present? && Date.today > due_date
  end

end
