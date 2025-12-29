class Member < ApplicationRecord
  has_secure_password

  # Associations
  has_many :borrowings, dependent: :restrict_with_error
  has_many :reservations, dependent: :destroy
  has_many :reviews, as: :reviewer, dependent: :destroy

  has_many :borrowed_books, through: :borrowings, source: :book
  has_many :reserved_books, through: :reservations, source: :book

  has_many :member_categories, dependent: :destroy
  has_many :liked_categories, through: :member_categories, source: :category

  belongs_to :favorite_author, class_name: "Author", optional: true

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :phone,
            format: { with: /\A\d{10}\z/, message: "must be 10 digits" },
            allow_blank: true

  # Callbacks
  before_validation :normalize_phone
  after_commit :send_welcome_email, on: :create
  before_destroy :check_active_borrowings

  # Business logic
  def has_overdue_books?
    borrowings.overdue.exists?
  end

  def active_borrowings_count
    borrowings.borrowed.count
  end

  private

  def normalize_phone
    self.phone = phone.gsub(/\D/, "") if phone.present?
  end

  def send_welcome_email
    Rails.logger.info "Welcome email sent to #{email}"
  end

  def check_active_borrowings
    if borrowings.borrowed.exists?
      errors.add(:base, "Cannot delete member with active borrowings")
      throw :abort
    end
  end
end
