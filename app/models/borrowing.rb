class Borrowing < ApplicationRecord
  belongs_to :member
  belongs_to :librarian, optional: true
  belongs_to :book
  

  attr_accessor :created_by_librarian

  def self.ransackable_attributes(auth_object = nil)
    ["book_id", "borrowed_date", "created_at", "due_date", "id", "id_value", "librarian_id", "member_id", "returned_date", "status", "updated_at"]
  end
  
  def self.ransackable_associations(auth_object = nil)
    ["book", "librarian", "member"]
  end
  
  enum :status, { borrowed: 0, returned: 1, overdue: 2 }
  
  FINE_PER_DAY = 5
  
  validates :borrowed_date, :due_date, presence: true
  validates :member, :book, presence: true
  validate :member_can_borrow, on: :create
  validate :book_is_available_or_reserved, on: :create  
  validate :due_date_after_borrowed_date
  
  # Callbacks
  before_validation :set_dates, on: :create
  before_validation :check_if_overdue
  after_create :decrease_book_availability
  after_update :notify_next_reservation, if: :returned_now?
  
  # Scopes
  scope :borrowed, -> { where(status: :borrowed) }
  scope :returned, -> { where(status: :returned) }
scope :active, -> { 
    where(returned_date: nil)
    .where("due_date >= ?", Date.current) 
  }
  scope :overdue, -> {
    where(returned_date: nil).and(
      where(status: :overdue).or(
        where(status: :borrowed).where("due_date < ?", Date.today)
      )
    )
  }
  scope :for_member, ->(member) { where(member: member) }
  scope :for_book, ->(book) { where(book: book) }
  scope :due_soon, -> { borrowed.where("due_date <= ?", 3.days.from_now) }
  
  def mark_as_returned!
    return if returned?
    
    transaction do
      update!(status: :returned, returned_date: Date.today)
      book.increment!(:available_copies)
    end
    
    true
  rescue => e
    Rails.logger.error("Error marking borrowing as returned: #{e.message}")
    false
  end
  

  def days_overdue
    return 0 if returned_date.present?
    
    today = Date.current
    return 0 if due_date >= today

    (today - due_date).to_i
  end
  
  def active?
    borrowed? && due_date >= Date.today
  end
  
  def calculate_fine
    days_overdue * FINE_PER_DAY
  end
  
  def as_json(options = {})
    super(options).merge({
      active: active?,
      days_overdue: days_overdue,
      fine: calculate_fine
    })
  end
  
  private
  
  def set_dates
    self.borrowed_date ||= Date.today
    self.due_date ||= borrowed_date + 14.days
  end
  
  def member_can_borrow
 
    return if created_by_librarian
    return unless member
    
    if member.has_overdue_books?
      errors.add(:base, "Member has overdue books")
    elsif member.active_borrowings_count >= 5
      errors.add(:base, "Borrowing limit reached")
    end
  end
  
  def book_is_available_or_reserved
    return unless book
    
    return if book.available_copies.to_i > 0
    
    has_reservation = book.reservations.pending.exists?(member: member)
    
    unless has_reservation
      errors.add(:base, "Book is not available")
    end
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
    
    reservation.update_column(:status, Reservation.statuses[:fulfilled])
    Rails.logger.info("Reservation fulfilled for member #{reservation.member.email}")
  end
  
  def check_if_overdue
    return if status == "returned" || returned_date.present?
    
    if due_date.present? && Date.today > due_date
      self.status = :overdue
    end
  end
end