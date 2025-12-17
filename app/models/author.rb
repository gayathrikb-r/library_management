class Author < ApplicationRecord
  # Prevent deleting an author if they have associated books
  has_many :book_authors, dependent: :restrict_with_error
  has_many :books, through: :book_authors
  has_many :reviews, as: :reviewable, dependent: :destroy
  has_many :profiles 
  #validation
  validates :name, presence: true

  def books_count
    books.count
  end
end
