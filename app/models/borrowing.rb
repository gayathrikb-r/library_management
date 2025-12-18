class Borrowing < ApplicationRecord
  belongs_to :user
  belongs_to :book
  #constant
  STATUSES = %w[active returned overdue].freeze
  FINE_PER_DAY = 5#5 rupee per day
  validates :borrowed_date, :due_date, presence: true
  validates :status, presence: true, inclusion: {in: STATUSES}
  validate :user_can_borrow, on: :create
  validate :book_is_available, on: :create
  validate :due_date_after_borrowed_date
  #CALLBACKS
  before_validation :set_dates, on: :create
  before_validation :check_if_overdue
  after_create :decrease_book_availability
  after_update :increase_book_availability, if: :returned_now?
  after_update :notify_next_reservation, if: :returned_now?

  scope :active, -> { where(status: 'active') }
  scope :overdue,  -> { where(status: 'overdue') }
  scope :returned, -> { where(status: 'returned') }
  scope :for_user, -> (user){ where(user: user) }
  scope :for_book, -> (book){ where(book: book)}
  scope :due_soon, -> { active.where('due_date <= ?', 3.days.from_now) }
  def mark_as_returned!
    update!(status: 'returned', returned_date: Date.today)
  end
  def overdue?
    active? && Date.today>due_date
  end
  def active?
    status=='active'
  end
  def days_overdue
    return 0 unless overdue?
    (Date.today-due_date).to_i
  end
  def calculate_fine
    return 0 unless overdue?
    days_overdue*FINE_PER_DAY
  end
  private
  def set_dates
    self.borrowed_date ||=Date.today
    self.due_date ||= borrowed_date + 14.days
  end
  def user_can_borrow
    return unless user
    errors.add(:base, "User has overdue books") if user.has_overdue_books?
    errors.add(:base, "User has reached borrowing limit") if user.active_borrowings_count>=5
  end
  def book_is_available
    errors.add(:base, "Book is not available") unless book&.available?
  end
  def due_date_after_borrowed_date
    return if borrowed_date.blank? || due_date.blank?
    if due_date <=borrowed_date 
      errors.add(:due_date, "must be after borrowed date")
    end
  end
  def decrease_book_availability
    book.decrement_available_copies!
  end
  def increase_book_availability
    book.increment_available_copies!
  end
  def returned_now?
    saved_change_to_status? && status == 'returned'
  end
  def notify_next_reservation
    next_reservation = book.reservations.where(status: 'pending').order(:reservation_date).first
    return unless next_reservation
    next_reservation.update!(status: 'fulfilled')
    Rails.logger.info("Reservation fulfilled for user #{next_reservation.user.email}")
  rescue StandardError => e
    Rails.logger.error("Failed to fulfill reservation #{next_reservation&.id}: #{e.message}")
  end
  def check_if_overdue
    return unless status == 'active'
    return if due_date.blank?
    self.status = 'overdue' if Date.today > due_date
  end
end
