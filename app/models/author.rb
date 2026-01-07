class Author < ApplicationRecord
  # Associations
  has_many :book_authors, dependent: :restrict_with_error
  has_many :books, through: :book_authors
  has_many :reviews, as: :reviewable, dependent: :destroy
   def self.ransackable_attributes(auth_object = nil)
    %w[
      id
      name
      created_at
      updated_at
    ]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[
      books
    ]
  end
  # Validations
  validates :name, presence: true

  # Scopes
  scope :search_by_name, ->(query) { where("name ILIKE ?", "%#{query}%") }

  # Methods
  def books_count
    books.count
  end
end
