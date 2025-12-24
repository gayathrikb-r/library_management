class User < ApplicationRecord
  has_secure_password

  has_many :borrowings, dependent: :destroy
  has_many :reservations, dependent: :destroy
  has_many :reviews, dependent: :destroy

  has_many :borrowed_books, through: :borrowings, source: :book
  has_many :reserved_books, through: :reservations, source: :book

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :phone, format: { with: /\A\d{10}\z/, message: "must be 10 digits" },
                    allow_blank: true

  before_validation :normalize_phone
  after_commit :send_welcome_email, on: :create
  before_destroy :check_active_borrowings

  def has_overdue_books?
    borrowings.where(status: "overdue").exists?
  end

  def active_borrowings_count
    borrowings.where(status: "active").count
  end

  private

  def normalize_phone
    self.phone = phone.gsub(/\D/, "") if phone.present?
  end

  def send_welcome_email
    puts "Welcome email sent to #{email}"
  end

  def check_active_borrowings
    if borrowings.where(status: "active").exists?
      errors.add(:base, "Cannot delete user with active borrowings")
      throw :abort
    end
  end
end
