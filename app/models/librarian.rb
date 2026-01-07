class Librarian < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  def self.ransackable_attributes(auth_object = nil)
    %w[
      id
      name
      email
      phone
      created_at
    ]
  end
  # Associations
  has_many :processed_borrowings,
           class_name: "Borrowing",
           dependent: :nullify

  has_many :reviews, as: :reviewer, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :phone,
            format: { with: /\A\d{10}\z/, message: "must be 10 digits" },
            allow_blank: true

  # Callbacks
  before_validation :normalize_phone

  private

  def normalize_phone
    self.phone = phone.gsub(/\D/, "") if phone.present?
  end
end
