class Reservation < ApplicationRecord
  belongs_to :user
  belongs_to :book
  #Validations
  validates :reservation_date, presence: true
  validate :book_is_unavailable, on: :create
  validate :user_cannot_have_duplicate_reservation
  #Callbacks
  before_validation :set_reservation_date, on: :create
  after_create :send_confirmation
  #Scope
  scope :pending, -> {where(status: 'pending')}
  scope :fulfilled, -> {where(status: 'fulfilled')}
  scope :cancelled, -> {where(status: 'cancelled')}
  def cancel!
    update(status: 'cancelled')
  end

  private
  def set_reservation_date
    self.reservation_date ||=Date.today
  end
  def book_is_unavailable
    if book&.available?
      errors.add(:base, "Book is currently available, no need to reserve")
    end
  end

  def user_cannot_have_duplicate_reservation
    if user && book && user.reservations.where(book: book, status: 'pending').exists?
      errors.add(:base, "You already have a pending reservation for this book.")
    end
  end
  def send_confirmation
    puts "Reservation confirmation sent to #{user.email}"
  end
end
