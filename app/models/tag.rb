class Tag < ApplicationRecord
   has_and_belongs_to_many :books
  def self.ransackable_attributes(auth_object = nil)
    %w[id name created_at updated_at]
  end
  # Validations
  validates :name, presence: true, uniqueness: true
  # Methods
  def books_count
    books.count
  end
end
