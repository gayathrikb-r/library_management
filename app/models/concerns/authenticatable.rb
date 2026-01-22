
module Authenticatable
  extend ActiveSupport::Concern

  included do
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

    has_many :reviews, as: :reviewer, dependent: :destroy

    validates :name, presence: true
    validates :phone,
              format: { with: /\A\d{10}\z/, message: "must be 10 digits" },
              allow_blank: true

    before_validation :normalize_phone
    after_update :revoke_all_oauth_tokens!, if: :saved_change_to_encrypted_password?
  end

  def revoke_all_oauth_tokens!
    oauth_access_tokens.update_all(revoked_at: Time.current)
    oauth_access_grants.update_all(revoked_at: Time.current)
  end

  private

  def normalize_phone
    self.phone = phone.gsub(/\D/, "") if phone.present?
  end
end