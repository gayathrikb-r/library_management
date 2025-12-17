class Tag < ApplicationRecord
   has_and_belongs_to_many :books
  # Validations
  validates :name, presence: true, uniqueness: true
  # Methods
  def books_count
    books.count
  end
end
