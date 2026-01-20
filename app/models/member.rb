class Member < ApplicationRecord
  # Devise modules
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :oauth_access_grants,
           as: :resource_owner,
           class_name: 'Doorkeeper::AccessGrant',
           dependent: :destroy

  has_many :oauth_access_tokens,
           as: :resource_owner,
           class_name: 'Doorkeeper::AccessToken',
           dependent: :destroy

  # Associations
has_many :borrowings, dependent: :destroy

  
  has_many :reservations, dependent: :destroy
  has_many :reviews, as: :reviewer, dependent: :destroy

  has_many :borrowed_books, through: :borrowings, source: :book
  has_many :reserved_books, through: :reservations, source: :book

  has_many :member_categories, dependent: :destroy
  has_many :liked_categories, through: :member_categories, source: :category

  belongs_to :favorite_author, class_name: "Author", optional: true

  # Validations
  validates :name, presence: true
  validates :phone,
            format: { with: /\A\d{10}\z/, message: "must be 10 digits" },
            allow_blank: true

  # Callbacks
  before_validation :normalize_phone
  after_commit :send_welcome_email, on: :create
  before_destroy :check_active_borrowings, prepend: true
  after_update :revoke_all_oauth_tokens!, if: :saved_change_to_encrypted_password?


  # Scopes / Methods
  def has_overdue_books?
    borrowings.overdue.exists?
  end

  def active_borrowings_count
    borrowings.borrowed.count
  end

  
  # Ransack support
  def self.ransackable_attributes(auth_object = nil)
    %w[name email phone birth_date bio created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[borrowings reservations reviews member_categories liked_categories favorite_author]
  end
    # Call this when password changes or account is locked
  def revoke_all_oauth_tokens!
    oauth_access_tokens.update_all(revoked_at: Time.current)
    oauth_access_grants.update_all(revoked_at: Time.current)
  end

  private

  def normalize_phone
    self.phone = phone.gsub(/\D/, "") if phone.present?
  end

  def send_welcome_email
    Rails.logger.info "Welcome email sent to #{email}"
  end

 def check_active_borrowings
    if borrowings.where(status: [:borrowed, :overdue]).exists?
      errors.add(:base, "Cannot delete member with active borrowings")
      throw :abort
    end
  end
end
