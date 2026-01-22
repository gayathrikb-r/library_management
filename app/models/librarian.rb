class Librarian < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
    include Authenticatable
  # Associations
  has_many :processed_borrowings,
           class_name: "Borrowing",
           dependent: :nullify

validates :email, presence: true, uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }


  def self.ransackable_attributes(auth_object = nil)
    %w[id name email phone created_at]
  end
  private

  def normalize_phone
    self.phone = phone.gsub(/\D/, "") if phone.present?
  end
end


  
 
  