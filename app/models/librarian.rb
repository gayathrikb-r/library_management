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
  has_many :oauth_access_grants,
           as: :resource_owner,
           class_name: 'Doorkeeper::AccessGrant',
           dependent: :destroy

  has_many :oauth_access_tokens,
           as: :resource_owner,
           class_name: 'Doorkeeper::AccessToken',
           dependent: :destroy
  # Validations
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  validates :phone,
            format: { with: /\A\d{10}\z/, message: "must be 10 digits" },
            allow_blank: true

  # Callbacks
  before_validation :normalize_phone
  after_update :revoke_all_oauth_tokens!, if: :saved_change_to_encrypted_password?

    # Call this when password changes or account is locked
  def revoke_all_oauth_tokens!
    oauth_access_tokens.update_all(revoked_at: Time.current)
    oauth_access_grants.update_all(revoked_at: Time.current)
  end
  private

  def normalize_phone
    self.phone = phone.gsub(/\D/, "") if phone.present?
  end
end
