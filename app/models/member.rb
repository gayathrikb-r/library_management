class Member < ApplicationRecord
  # Devise modules
   include Authenticatable
   has_many :borrowings, dependent: :destroy
  has_many :reservations, dependent: :destroy
  
  has_many :borrowed_books, through: :borrowings, source: :book
  has_many :reserved_books, through: :reservations, source: :book

  has_many :member_categories, dependent: :destroy
  has_many :liked_categories, through: :member_categories, source: :category

  belongs_to :favorite_author, class_name: "Author", optional: true
  

  after_commit :send_welcome_email, on: :create
  before_destroy :check_active_borrowings, prepend: true
  
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
